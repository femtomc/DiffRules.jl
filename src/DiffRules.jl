module DiffRules

using Distributions
using Random
using IRTools
using IRTools: @dynamo, IR, xcall, arguments, insertafter!, recurse!, isexpr, self, argument!, Variable, meta, renumber, Pipe, finish
using Mjolnir
using Mjolnir: Basic, AType, Const, abstract, Multi, @abstract, Partial, Node
using Mjolnir: Defaults

include("types.jl")
include("ctx.jl")

# Runtime
include("runtime_lib/base.jl")
include("runtime_lib/distributions.jl")
include("runtime_lib/numeric.jl")

# Abstract
include("abstract_lib/base.jl")
include("abstract_lib/distributions.jl")
include("abstract_lib/numeric.jl")

include("interface.jl")
include("incremental.jl")

export Diff
export get_diff, strip_diff
export UnknownChange, NoChange
export SetDiff, DictDiff, VectorDiff
export IntDiff

end # module
