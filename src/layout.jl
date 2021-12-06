export Layout, LForwardReference, LFixedVector, LVarVector
export is_template_fixed, is_template_variable

"""
Layout

All structs used to describe the memory layout (of a C-data structure) need to be
subtypes of this.
Some controlling objects used in such templates to describe vectors and pointers
have also this type.
A `Layout` structure and a memory pointer are needed to construct an `CAccessor` object.
"""
abstract type Layout end

abstract type LVector{T} <: Layout end

Base.eltype(::Type{<:LVector{T}}) where T = T

# Layout Elements
"""
    LFixedVector{T,N}

Denote a fixed size vector with element type `T` and size `N`.
"""
struct LFixedVector{T,N} <: LVector{T}
    p::NTuple{N,T}
end
Base.length(::Type{LFixedVector{T,N}}, ::Any) where {T,N} = N

"""
    LVarVector{T,F}

Denote a variable length vector with element type `T` in a template.
`F` is a function, which calculates the length of the vector, given the
accessor object containing the vector.

Example:
    struct A <: Layout
        len::Int
        vec::NVarVector{Float64, (x) -> x.len}
    end

"""
struct LVarVector{T,F}  <: LVector{T}
    p::NTuple{0,T}
end
Base.length(::Type{LVarVector{T,F}}, x) where {T,F} = F(x)

struct LForwardReference{M,L} <: Layout
    p::Ptr{Nothing}
end
reftype(::Type{LForwardReference{M,L}}) where {M,L} = M.name.module.eval(L)

const TEMPLATE_FIXED = true
const TEMPLATE_VAR = false
"""
    is_template_variable(type)

Has the layout described by `type` a variable size
(for example variable sized vector in last field of a struct)?
"""
is_template_variable(T::Type) = !is_template_fixed(T)

"""
    is_template_fixed(type)

Has the layout described by `type` a fixed size.
"""
is_template_fixed(T::Type) = is_template_fixed(T, Dict())
function is_template_fixed(::Type{T}, dup) where T
    isprimitivetype(T) || throw(ArgumentError("$T is not a supported layout type"))
    TEMPLATE_FIXED
end
function is_template_fixed(::Type{S}, dup) where {T,S<:Ptr{T}}
    T <: Ptr && throw(ArgumentError("$S is not a supported layout type"))
    get!(dup, S) do
        dup[S] = TEMPLATE_FIXED
        is_template_fixed(T, dup)
        TEMPLATE_FIXED
    end
end
function is_template_fixed(::Type{S}, dup) where {S<:LForwardReference}
    is_template_fixed(Ptr{reftype(S)}, dup)
end
function is_template_fixed(::Type{S}, dup) where {T,N,S<:LFixedVector{T,N}}
    get!(dup, S) do
        dup[S] = TEMPLATE_FIXED
        k = is_template_fixed(T, dup)
        if N > 1 && k == TEMPLATE_VAR
            throw(ArgumentError("$S with variable length elements"))
        end 
        N == 0 ? TEMPLATE_FIXED : k
    end
end
function is_template_fixed(::Type{S}, dup) where {T,S<:LVarVector{T}}
    get!(dup, S) do
        dup[S] = TEMPLATE_FIXED
        k = is_template_fixed(T, dup)
        min(k, TEMPLATE_VAR)
    end
end
function is_template_fixed(::Type{T}, dup) where {T<:Layout}
    get!(dup, T) do
        k = dup[T] = TEMPLATE_FIXED
        if !isbitstype(T)
            text = isconcretetype(T) ? "bits" : "concrete"
            throw(ArgumentError("$T is not a $text type struct"))
        end
        fields = fieldnames(T)
        n = length(fields)
        for i = 1:n
            f = fields[i]
            F = fieldtype(T, f)
            k = is_template_fixed(F, dup)
            if i < n && k == TEMPLATE_VAR
                throw(ArgumentError("$F has variable length in '$T.$f' - not last field"))
            end
        end
        k
    end
end
