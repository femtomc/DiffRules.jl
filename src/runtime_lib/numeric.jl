# built-in mathematical operators and functions

macro diffed_unary_function(fn)
    quote
        function $(fn)(value::Diffed{T,NoChange}) where {T}
            Diffed($(fn)(strip_diff(value)), NoChange())
        end

        function $(fn)(value::Diffed{T,Change}) where {T}
            Diffed($(fn)(strip_diff(value)), Change())
        end
    end
end


macro diffed_binary_function(fn)
    quote
        function $(fn)(a::Diffed{T,NoChange}, b::Diffed{U,NoChange}) where {T,U}
            result = $(fn)(strip_diff(a), strip_diff(b))
            Diffed(result, NoChange())
        end

        function $(fn)(a, b::Diffed{U,NoChange}) where {U}
            result = $(fn)(a, strip_diff(b))
            Diffed(result, NoChange())
        end

        function $(fn)(a::Diffed{T,NoChange}, b) where {T}
            result = $(fn)(strip_diff(a), b)
            Diffed(result, NoChange())
        end

        function $(fn)(a, b::Diffed{U,DU}) where {U,DU}
            result = $(fn)(a, strip_diff(b))
            Diffed(result, Change())
        end

        function $(fn)(a::Diffed{T,DT}, b) where {T,DT}
            result = $(fn)(strip_diff(a), b)
            Diffed(result, Change())
        end

        function $(fn)(a::Diffed{T,DT}, b::Diffed{U,DU}) where {T,U,DT,DU}
            result = $(fn)(strip_diff(a), strip_diff(b))
            Diffed(result, Change())
        end

        function $(fn)(a::Diffed{T,NoChange}, b::Diffed{U,DU}) where {T,U,DU}
            result = $(fn)(strip_diff(a), strip_diff(b))
            Diffed(result, Change())
        end

        function $(fn)(a::Diffed{T,DT}, b::Diffed{U,NoChange}) where {T,U,DT}
            result = $(fn)(strip_diff(a), strip_diff(b))
            Diffed(result, Change())
        end
    end
end

@diffed_binary_function Base.:+
@diffed_binary_function Base.:*
@diffed_binary_function Base.:-
@diffed_binary_function Base.:/
@diffed_binary_function Base.atan

@diffed_unary_function Base.exp
@diffed_unary_function Base.log
@diffed_unary_function Base.sqrt
@diffed_unary_function Base.sin
@diffed_unary_function Base.cos
@diffed_unary_function Base.tan
