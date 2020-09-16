(d::Type{D})(args...) where {D <: Distribution, Df <: Diffed} = d(map(a -> Jaynes.unwrap(a), args)...)
