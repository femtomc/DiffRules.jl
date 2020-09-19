struct CachedSite{V}
    call::Function
    args::Tuple
    ret::V
end
get_ret(cs::CachedSite) = cs.ret

struct DynamicCallGraph{V}
    addressed::Dict{Symbol, CachedSite}
    recursed::Dict{Symbol, DynamicCallGraph}
    call::Function
    args::Tuple
    ret::V
end
get_ret(dcg::DynamicCallGraph) = dcg.ret
get_subgraph(dcg::DynamicCallGraph, addr) = dcg.recursed[addr]

# ------------ Pretty printing ------------ #

function collect!(par, chd, gr)
    for (k, v) in gr.recursed
        collect!((par..., k), chd, v)
    end
    for (k, v) in gr.addressed
        chd[(par..., k)] = v
    end
    chd[par] = gr.ret
end

function collect(gr::DynamicCallGraph)
    chd = Dict()
    for (k, v) in gr.recursed
        collect!((k, ), chd, v)
    end
    for (k, v) in gr.addressed
        chd[(k, )] = v
    end
    chd
end

@inline display(gr::DynamicCallGraph) = display(collect(gr))

# ------------ Recording ------------ #

abstract type ExecutionContext end

@inline record!(mx::E, addr, cs::CachedSite) where E <: ExecutionContext = mx.addressed[addr] = cs
@inline record!(mx::E, addr, gr::DynamicCallGraph) where E <: ExecutionContext = mx.recursed[addr] = gr
@inline visit!(mx::E, addr) where E <: ExecutionContext = addr in mx.visited ? error("Already visited $addr.") : push!(mx.visited, addr)
@inline get_subgraph(mx::E, addr) where E <: ExecutionContext = mx.recursed[addr]

struct RecordContext <: ExecutionContext
    addressed::Dict{Symbol, CachedSite}
    recursed::Dict{Symbol, DynamicCallGraph}
    visited::Vector{Symbol}
end
RecordContext() = RecordContext(Dict{Symbol, CachedSite}(), 
                                Dict{Symbol, DynamicCallGraph}(),
                                Symbol[])

# ------------ Incremental ------------ #

mutable struct IncrementalContext <: ExecutionContext
    prev::DynamicCallGraph
    addressed::Dict{Symbol, CachedSite}
    recursed::Dict{Symbol, DynamicCallGraph}
    visited::Vector{Symbol}
end

@inline function record_cached!(ctx::IncrementalContext, addr)
    visit!(ctx, addr)
    sub = getindex(ctx.prev.addressed, addr)
    ctx.addressed[addr] = sub
    get_ret(sub)
end

@inline function record_track!(ctx::IncrementalContext, addr)
    visit!(ctx, addr)
    sub = getindex(ctx.prev.recursed, addr)
    ctx.recursed[addr] = sub
    get_ret(sub)
end

function Incremental(prev::DynamicCallGraph)
    IncrementalContext(prev,
                       Dict{Symbol, CachedSite}(),
                       Dict{Symbol, DynamicCallGraph}(),
                       Symbol[])
end

# ------------ Tracing ------------ #

@inline cache(addr, fn, args...) = fn(args...)
@inline track(addr, fn, args...) = fn(args...)
@abstract DiffPrimitives cache(addr, fn, args...) = propagate(args...)
@abstract DiffPrimitives track(addr, fn, args...) = propagate(args...)

whitelist = [:cache, :track,
             # Base.
             :_apply_iterate, :collect,
            ]

unwrap(gr::GlobalRef) = gr.name
unwrap(v::Val{K}) where K = K
unwrap(gr) = gr

# Fix for specialized tracing.
function recur(ir, to = self)
    pr = Pipe(ir)
    for (x, st) in pr
        isexpr(st.expr, :call) && begin
            ref = unwrap(st.expr.args[1])
            ref in whitelist || continue
            pr[x] = Expr(:call, to, st.expr.args...)
        end
    end
    finish(pr)
end

@dynamo function (mx::ExecutionContext)(a...)
    ir = IR(a...)
    ir == nothing && return
    ir = recur(ir)
    ir
end

@inline function (mx::ExecutionContext)(::typeof(cache), addr, fn, args...)
    visit!(mx, addr)
    ret = fn(args...)
    record!(mx, addr, CachedSite(fn, map(a -> strip_diff(a), args), strip_diff(ret)))
    ret
end

@inline function (mx::ExecutionContext)(::typeof(track), addr, fn, args...)
    visit!(mx, addr)
    ret, retdiff, subgraph = record(fn, args...)
    record!(mx, addr, subgraph)
    ret
end

@dynamo function (mx::IncrementalContext)(f, ::Type{S}, args...) where S <: Tuple
    ir = IR(f, S.parameters...)
    ir == nothing && return
    if control_flow_check(ir)
        tr = diff_inference(f, S.parameters, args)
        argument!(ir, at = 2)
        ir = optimization_pipeline(ir.meta, tr)
    else
        argument!(ir, at = 2)
        ir = recur(ir)
    end
    ir
end

@inline function (mx::IncrementalContext)(::typeof(cache), addr, fn, args...)
    visit!(mx, addr)
    ret = fn(args...)
    record!(mx, addr, CachedSite(fn, map(a -> strip_diff(a), args), strip_diff(ret)))
    ret
end

@inline function (mx::IncrementalContext)(::typeof(track), addr, fn, args...)
    visit!(mx, addr)
    if haskey(mx.recursed, addr)
        subgraph = get_subgraph(mx, addr)
        ret, retdiff, graph = change(subgraph, args...)
    else
        ret, retdiff, graph = record(fn, args...)
    end
    record!(mx, addr, graph)
    retdiff
end

function record(fn, args...)
    rec = RecordContext()
    ret = rec(fn, args...)
    return strip_diff(ret), ret, DynamicCallGraph(rec.addressed, 
                                                  rec.recursed, 
                                                  fn, 
                                                  args, 
                                                  strip_diff(ret))
end

function change(prev::DynamicCallGraph, new_args::Diffed...) where N
    inc = Incremental(prev)
    ret = inc(prev.call, tupletype(new_args...), new_args...)
    return strip_diff(ret), ret, DynamicCallGraph(inc.addressed, 
                                                  inc.recursed, 
                                                  prev.call, 
                                                  map(a -> unwrap(a), new_args), 
                                                  strip_diff(ret))
end
