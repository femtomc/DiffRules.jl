struct CachedSite{V}
    call::Function
    args::Tuple
    ret::V
end

struct IncrementalContext
    addressed::Dict{Symbol, CachedSite}
end

@dynamo function (inc::IncrementalContext)(a...)
end

@inline cache(addr, fn, args...) = fn(args...)

function (inc::IncrementalContext)(::typeof(cache), addr, fn, args...)
end
