module Fibonacci

include("../src/DiffRules.jl")
using .DiffRules

@inline fib(x) = (x == 0 || x == 1) ? 1 : cache(:fst, fib, x - 1) + cache(:snd, fib, x - 2)

ret, retdiff, cached = record(fib, 25)
display(cached)

end # module
