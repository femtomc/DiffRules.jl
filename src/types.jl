abstract type Diff end
abstract type AbstractDiff <: Diff end
abstract type RuntimeDiff <: AbstractDiff end

struct Change <: AbstractDiff end
struct NoChange <: RuntimeDiff end

struct SetDiff{V} <: RuntimeDiff
    added::Set{V}
    deleted::Set{V}
end

struct DictDiff{K,V} <: RuntimeDiff
    added::AbstractDict{K,V}
    deleted::AbstractSet{K}
    updated::AbstractDict{K, RuntimeDiff}
end

struct VectorDiff <: RuntimeDiff
    new_length::Int
    prev_length::Int
    updated::Dict{Int, RuntimeDiff}
end

struct IntDiff <: RuntimeDiff
    difference::Int # new - old
end

struct ScalarDiff{K} <: RuntimeDiff
    diff::K
end

struct BoolDiff <: RuntimeDiff
    new::Bool
end

lift(val) = NoChange()
lift(::RuntimeDiff) = Change()
lift(::Type{<:RuntimeDiff}) = Change

# ------------ Container ------------ #

struct Diffed{V, DV <: Diff}
   value::V
   diff::DV
end

get_value(value) = value
get_value(diffed::Diffed) = diffed.value
get_diff(diffed::Diffed) = diffed.diff
