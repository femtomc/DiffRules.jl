module QuickScratch

include("../src/DiffRules.jl")
using .DiffRules

@inline simple1(x, y) = x + y + cache(:z, +, 5, x)

ret, _, cached = track(simple1, 3, 5)
display(cached)
ret, _, new = change(cached, Δ(11, IntDiff(8)), Δ(4, IntDiff(-1)))
display(new)

@inline simple2(x, y) = cache(:q, +, x, y) + cache(:z, +, 5, x)

ret, _, cached = track(simple2, 3, 5)
display(cached)
ret, retdiff, new = change(cached, Δ(11, IntDiff(8)), Δ(4, IntDiff(-1)))
display(new)
println(ret)

@inline function simple3(x, N)
    for i in 1 : N
        x += 1
    end
    x
end

ret, _, cached = track(simple3, 3, 5)
display(cached)
ret, retdiff, new = change(cached, Δ(11, IntDiff(8)), Δ(4, IntDiff(-1)))
display(new)
println(ret)

end # module
