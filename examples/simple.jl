module QuickScratch

include("../src/DiffRules.jl")
using .DiffRules

@inline simple1(x, y) = x + y + cache(:z, +, 5, x)

ret, _, cached = record(simple1, 3, 5)
display(cached)
ret, _, new = change(cached, Δ(11, IntDiff(8)), Δ(4, IntDiff(-1)))
display(new)

@inline simple2(x, y) = cache(:q, +, x, y) + cache(:z, +, 5, x)

ret, _, cached = record(simple2, 3, 5)
display(cached)
ret, retdiff, new = change(cached, Δ(11, IntDiff(8)), Δ(4, IntDiff(-1)))
display(new)

# Example where this technique is not good.
@inline function simple3(x)
    for i in 1 : 1000
        x = cache(Symbol(i), +, x, i)
    end
    x
end

ret, _, cached = record(simple3, 3)
@time ret = simple3(15)
@time ret, retdiff, new = change(cached, Δ(15, IntDiff(8)))
@time ret = simple3(15)
@time ret, retdiff, new = change(cached, Δ(15, NoChange()))

end # module
