
export Caccessor, CStruct, CVector
export pointer_from_vector

import Base: length, getproperty, setproperty!, size, length

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

struct CStruct{T}
    pointer::Ptr{Nothing}
    function CStruct{T}(p::Ptr) where T
        isbitstype(T) || throw(ArgumentError("$T is not a bitstype"))
        new{T}(p)
    end
end

"""
    CVector

Abstract vector type for julia objects used to access elements of C-vectors,
which are based by plain C memory. Memory layout is described by `Layout` structs.
"""
struct CVector{T} <: AbstractVector{T}
    pointer::Ptr{Nothing}
    length::Int
    function CVector{T}(p::Ptr, length::Integer=-1) where T
        isbitstype(T) || throw(ArgumentError("$T is not a bitstype"))
        new{T}(p, length)
    end
end

const CAccessor = Union{CStruct, CVector}
# accessing the fields represented by CStruct
# to access the pointer use function `pointer`
function Base.propertynames(::CStruct{T}) where T
    fieldnames(T)
end

function Base.getproperty(cs::CStruct{T}, field::Symbol) where T
    fp = pointer_for_field(cs, field)
    get_from_pointer(fp, cs)
end

function Base.setproperty!(cs::CStruct{T}, field::Symbol, v) where T
    fp = pointer_for_field(cs, field)
    set_at_pointer!(fp, v)
end

function Base.getindex(cv::CVector{T}, i::Integer) where T
    p = pointer_for_index(cv, i)
    get_from_pointer(p, cv)
end

function Base.getindex(cv::CVector{T}, r::OrdinalRange) where T
    [getindex(cv, i) for i in r]
end

function Base.setindex!(cv::CVector{T}, v, i::Integer) where T
    p = pointer_for_index(cv, i)
    set_at_pointer!(p, v)
end

size(cv::CVector) = (length(cv),)

"""
    pointer(::Union{CStruct,CVector})
    length(::CVector)

get the internal fields of accessors
"""
pointer(cs::CAccessor) = getfield(cs, :pointer)
length(cv::CVector) = getfield(cv, :length)

function Base.show(io::IO, x::CStruct{T}) where T
    show(io, typeof(x))
    print(io, '(')
    nf = length(T.types)
    px = pointer(x)
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
For struct types, create CStruct accessor.
For vector types, create CVector accessor.
"""
function get_from_pointer(fp::Ptr{FT}, parent) where FT <: Ptr
    v = unsafe_load(fp)
    v == C_NULL ? nothing : get_from_pointer(v, parent)
end

function get_from_pointer(fp::Ptr{FT}, parent) where {T,FT<:LVector{T}}
    CVector{T}(fp, length(FT, parent))
end

function get_from_pointer(fp::Ptr{FT}, parent) where FT <: Layout
    CStruct{FT}(fp)
end

function get_from_pointer(fp::Ptr{FT}, parent) where FT <: Cstring
    v = unsafe_load(fp)
    v == Cstring(C_NULL) ? "" : Base.unsafe_string(Ptr{UInt8}(v))
end

function get_from_pointer(fp::Ptr{FT}, parent) where FT
    if isprimitivetype(FT)
        unsafe_load(fp)
    else
        throw(ArgumentError("not supported layout type: $FT"))
    end
end

"""
    set_at_pointer(:Ptr, value)

Convert to C primitive or composed object. Store bytes at memory position.
"""
function set_at_pointer!(fp::Ptr{FT}, v) where FT
    w = Base.unsafe_convert(FT, Base.cconvert(FT, v))
    unsafe_store!(fp, w)
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
    Ptr{fieldtype(T, i)}(getfield(cs, :pointer) + fieldoffset(T, i))
end

function pointer_for_index(cv::CVector{T}, i::Integer) where T
    Ptr{T}(getfield(cv, :pointer) + sizeof(T) * (i - 1))
end

Base.unsafe_convert(::Type{Ptr{T}}, cs::CStruct{T}) where T = getfield(cs, :pointer) 
Base.unsafe_convert(::Type{Ptr{Vector{T}}}, cs::CVector{T}) where T = getfield(cs, :pointer) 
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
