
export CStruct, CVector, Layout, CAccessor, pointer_from_vector
export LForwardReference, LFixedVector, LVarVector

import Base: length, getproperty, setproperty!

"""
    CAccessor

Abstract type for julia objects used to access fields and vector elements of C-structures,
which are based by plain C memory. Memory layout is described by `Layout` structs.
"""
abstract type CAccessor end
"""
    Layout

All structs used to describe the memory layout (of a C-data structure) need to be
subtypes of this.
Some controlling objects used in such templates to describe vectors and pointers
have also this type.
A `Layout` structure and a memory pointer are needed to construct an `CAccessor` object.
"""
abstract type Layout end

"""
    CStruct{T}(p::Ptr)

    Given a C-type pointer `p` to a C-struct and the equivalent Julia struct
    with the same memory layout `T`, provide read and write access to the fields.
    `T` must be a bits type.

    Example:
    struct T <: Layout
        a::Cint
        b::Cdouble
    end

    a = Vector{UInt8}(undef, 100)
    p = pointer_from_vector(a) # usually the data are coming from C
    cs = CStruct{T}(p)

    cs.a = 1234
    cs.b = 3.5
    
"""
struct CStruct{T} <: CAccessor
    p::Ptr{Nothing}
    function CStruct{T}(p::Ptr) where T
        isbitstype(T) || throw(ArgumentError("$T is not a bitstype"))
        new{T}(p)
    end
end

struct CVector{T} <: CAccessor
    p::Ptr{Nothing}
    length::Int
    function CVector{T}(p::Ptr, length::Integer=-1) where T
        isbitstype(T) || throw(ArgumentError("$T is not a bitstype"))
        new{T}(p, length)
    end
end


# Layout Elements
struct LFixedVector{T,N} <: Layout
    p::NTuple{N,T}
end
Base.length(::Type{LFixedVector{T,N}}) where {T,N} = N
struct LVarVector{T,F} <: Layout
    p::NTuple{0,T}
end
Base.length(::Type{LVarVector{T,F}}, x) where {T,F} = F(x)
struct LForwardReference{L} <: Layout
    p::Ptr{Nothing}
end
reftype(::Type{LForwardReference{L}}) where {L} = eval(L)

# accessing the fields represented by CStruct
# to access the pointer use function `ptr`
function Base.propertynames(::CStruct{T}) where T
    fieldnames(T)
end

function Base.getproperty(cs::CStruct{T}, field::Symbol) where T
    fp = pointer_for_field(cs, field)
    get_from_pointer(fp)
end

function Base.setproperty!(cs::CStruct{T}, field::Symbol, v) where T
    fp = pointer_for_field(cs, field)
    set_at_pointer!(fp, v)
end

function Base.getindex(cv::CVector{T}, i::Integer) where T
    p = pointer_for_index(cv, i)
    get_from_pointer(p)
end

function Base.getindex(cv::CVector{T}, r::OrdinalRange) where T
    [getindex(cv, i) for i in r]
end

function Base.setindex!(cv::CVector{T}, v, i::Integer) where T
    p = pointer_for_index(cv, i)
    set_at_pointer!(p, v)
end

"""
    ptr(::CAccessor)
    length(::CVector)
    accessing the internal fields of accessors
"""
ptr(cs::CAccessor) = getfield(cs, :p)
Base.length(cv::CVector) = getfield(cv, :length)

function Base.show(io::IO, x::CStruct{T}) where T
    show(io, typeof(x))
    print(io, '(')
    nf = length(T.types)
    if !Base.show_circular(io, x)
        recur_io = IOContext(io, Pair{Symbol,Any}(:SHOWN_SET, x),
                                Pair{Symbol,Any}(:typeinfo, Any))
        for i in 1:nf
            f = fieldname(T, i)
            show(recur_io, getproperty(x, f))
            if i < nf
                print(io, ", ")
            end
        end
    end
    print(io, ')')
end

function Base.show(io::IO, x::CVector{T}) where T
    show(io, typeof(x))
    print(io, '[')
    nf = length(x)
    if nf < 0
        print(io, "#= unknown length =#")
    elseif !Base.show_circular(io, x)
        recur_io = IOContext(io, Pair{Symbol,Any}(:SHOWN_SET, x),
                                Pair{Symbol,Any}(:typeinfo, Any))
        for i in 1:nf
            show(recur_io, getindex(x, i))
            if i < nf
                print(io, ", ")
            end
        end
    end
    print(io, ']')
end

"""
    get_from_pointer(::Ptr{T})

For primitive types simply load value, convert to Julia accessor if required.
For Vector types, create CVector accessor.
For struct types, create CStruct accessor.
"""
function get_from_pointer(fp::Ptr)
    FT = reftype(fp)
    if isprimitivetype(FT)
        v = unsafe_load(fp)
        jconvert(FT, v)
    elseif FT isa Vector
        CVector{eltype(FT)}(fp)
    else
        CStruct{FT}(fp)
    end
end

"""
    set_at_pointer(:Ptr, value)

Convert to C primitive or composed object. Store bytes at memory position.
"""
function set_at_pointer!(fp::Ptr, v)
    FT = reftype(fp)
    v = Base.unsafe_convert(FT, Base.cconvert(FT, v))
    unsafe_store!(fp, v)
end

"""
    pointer_for_field(cs::CStruct{T}, fieldname) where T

For `cs` return pointer to member field `fieldname`.
The pointer has type `Ptr{fieldtype(T, i)}` with `i` the number of the field
within struct type `T`. 
"""
function pointer_for_field(cs::CStruct{T}, field::Symbol) where T
    i = findfirst(Base.Fix1(isequal, field), fieldnames(T))
    i === nothing && throw(ArgumentError("type $T has no field $field"))
    Ptr{fieldtype(T, i)}(getfield(cs, :p) + fieldoffset(T, i))
end

function pointer_for_index(cv::CVector{T}, i::Integer) where T
    Ptr{T}(getfield(cv, :p) + sizeof(T) * (i - 1))
end

reftype(::Ptr{T}) where T = T

jconvert(::Type, v) = v
jconvert(::Type{Cstring}, v) = v == C_NULL ? "" : Base.unsafe_string(v)
jconvert(::Type{Ptr{Vector{T}}}, v) where T = v == C_NULL ? nothing : CVector{T}(v)
jconvert(::Type{Ptr{T}}, v) where T = v == C_NULL ? nothing : CStruct{T}(v)
jconvert(::Type{T}, v) where T<:CStruct = T(v)

Base.unsafe_convert(::Type{Ptr{T}}, cs::CStruct{T}) where T = getfield(cs, :p) 
Base.unsafe_convert(::Type{Ptr{Vector{T}}}, cs::CVector{T}) where T = getfield(cs, :p) 
"""
    p = pointer_from_vector(a::Vector{T})::Ptr{T}

return pointer to `a[1]`. The existence of the resulting Ptr will not protect the object
from garbage collection, so you must ensure that the object remains referenced for the whole
time that the Ptr will be used.
The condition `a[i] === unsafe_load(p, i)` is usually true.
Given `p` it is possible to access arbitrary bits data by byte offset and type `S` using
`unsafe_load(Ptr{S}(p + offset))`.

This function is mainly used to simulate a C memory in the data
area of vector `a`.
"""
pointer_from_vector(a::Vector{T}) where T = Base.unsafe_convert(Ptr{T}, a)
