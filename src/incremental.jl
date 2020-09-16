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
