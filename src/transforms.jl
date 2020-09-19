# Check if there are branches.
function control_flow_check(ir)
    length(ir.blocks) > 1 && return false
    return true
end

@inline check_change(st) = st.type == Change
@inline function check_removable(st)
    ex = st.expr
    ex isa Expr &&
    ex.head == :call && 
    (ex.args[1] isa IRTools.Inner.Self ||
    (ex.args[1] isa GlobalRef && ex.args[1].name == :record_cached!) ||
    (ex.args[1] isa GlobalRef && ex.args[1].name == :record_track!))
end

# This pass is a dataflow analysis which determines what deterministic statements can be safely removed. It leaves rand calls and record_cached! calls alone.
function no_change_prune(ir)
    us = IRTools.Inner.usecounts(ir)
    isused(x) = get(us, x, 0) > 0
    for v in reverse(keys(ir))
        if !isused(v) && !check_removable(ir[v])
            if isexpr(ir[v].expr)
                Mjolnir.effectful(Mjolnir.exprtype.((ir,), ir[v].expr.args)...) && continue
                map(v -> v isa Variable && (us[v] -= 1), ir[v].expr.args)
            elseif ir[v].expr isa Variable
                us[ir[v].expr] -= 1
            end
            delete!(ir, v)
        end
    end
    return ir
end

# This pass strips the types from all basic block arguments (and thus, branches).
function strip_types(ir)
    pr = IRTools.Pipe(ir)
    for (v, st) in pr
        pr[v] = IRTools.Statement(st, type = Any)
    end
    new = IRTools.finish(pr)
    for bb in IRTools.blocks(new)
        at = IRTools.argtypes(bb)
        for (i, a) in enumerate(at)
            at[i] = Any
        end
    end
    new
end

# This pass wraps rand calls.
function cache_wrapper(ir)
    pr = IRTools.Pipe(ir)
    for (v, st) in pr
        expr = st.expr
        if expr.head == :call && expr.args[1] == cache && expr.args[2] isa QuoteNode
            pr[v] = xcall(self, GlobalRef(@__MODULE__, :cache), expr.args[2 : end]...)
        end
    end
    IRTools.finish(pr)
end

# This pass inserts the return value of the call before any NoChange call nodes.
function substitute_get_value!(pr, v, st)
    expr = st.expr
    if expr.head == :call && expr.args[1] == cache && expr.args[2] isa QuoteNode
        pr[v] = xcall(GlobalRef(@__MODULE__, :record_cached!), self, expr.args[2])
    end
    if expr.head == :call && expr.args[1] == track && expr.args[2] isa QuoteNode
        pr[v] = xcall(GlobalRef(@__MODULE__, :record_track!), self, expr.args[2])
    end
end

# This pass prunes the IR of any NoChange nodes.
function insert_cache_calls(ir)
    pr = IRTools.Pipe(ir)
    for (v, st) in pr
        st.type != Change && substitute_get_value!(pr, v, st)
    end
    IRTools.finish(pr)
end

# This merges the meta from one piece of IR with the IR from a trace.
function reconstruct_ir(meta, tr)
    ir = IRTools.IR(copy(tr.defs), copy.(tr.blocks), copy(tr.lines), meta)
    ir
end

# Abstract interpretation - diff propagation inference.
@inline function diff_inference(f, type_params, args)
    args = map(args) do a
        lift(difftype(a))
    end
    tr = _propagate(f, type_params, args)
    argument!(tr, at = 2)
    tr
end

# Full pipeline.
@inline function optimization_pipeline(meta, tr)
    tr = reconstruct_ir(meta, tr)
    tr = insert_cache_calls(tr)
    tr = strip_types(tr)
    tr = cache_wrapper(tr)
    tr = no_change_prune(tr)
    tr = renumber(tr)
    tr
end
