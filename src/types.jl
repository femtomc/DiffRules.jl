"""
    abstract type Diff end

Abstract type for information about a change to a value.
"""
abstract type Diff end

"""
    Change

No information is provided about the change to the value.
"""
struct Change <: Diff end

"""
    NoChange

The value did not change.
"""
struct NoChange <: Diff end

struct SetDiff{V} <: Diff

    # elements that were added
    added::Set{V}

    # elements that were deleted
    deleted::Set{V}
end

struct DictDiff{K,V} <: Diff

    # keys that that were added and their values
    added::AbstractDict{K,V}

    # keys that were deleted
    deleted::AbstractSet{K}

    # map from key to diff value for that key
    updated::AbstractDict{K,Diff}
end

struct VectorDiff <: Diff
    new_length::Int
    prev_length::Int
    updated::Dict{Int,Diff}
end

struct IntDiff <: Diff
    difference::Int # new - old
end

struct ScalarDiff{K} <: Diff
    diff::K
end

struct BoolDiff <: Diff
    new::Bool
end

"""
   Diffed{V,DV <: Diff}

Container for a value and information about a change to its value.
"""
struct Diffed{V,DV <: Diff}
   value::V
   diff::DV
end

get_diff(diffed::Diffed) = diffed.diff
get_diff(value) = NoChange()
strip_diff(diffed::Diffed) = diffed.value
strip_diff(value) = value
