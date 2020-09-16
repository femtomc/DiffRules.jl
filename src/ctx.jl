# Define the algebra for propagation of diffs.
unwrap(d::Diffed) = d.value
unwrap(::Type{K}) where K = K
unwrap(::Const{K}) where K = K
unwrap(::Partial{K}) where K = K
unwrap(::Mjolnir.Node{K}) where K = K

function change_check(args)
    unwrapped = map(args) do a
        unwrap(a) <: Change
    end
    any(unwrapped) && return Change
    return NoChange
end

function propagate(args...)
    unwrapped = map(args) do a
        unwrap(a)
    end
    change_check(args)
end

struct DiffPrimitives end
