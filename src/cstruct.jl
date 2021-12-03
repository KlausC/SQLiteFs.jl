
export CStruct, pointer_from_vector

"""
    CStruct{T}(p::Ptr)

    Given a C-type pointer `p` to a C-struct and the equivalent Julia struct
    with the same memory layout `T`, provide read and write access to the fields.
    `T` must be a bits type.

    Example:
    struct T
        a::Cint
        b::Cdouble
    end

    a = Vector{UInt8}(undef, 100)
    p = pointer_from_vector(a)
    cs = CStruct{T}(p)

    cs.a = 1234
    cs.b = 3.5
    
"""
struct CStruct{T}
    p::Ptr{Nothing}
    function CStruct{T}(p::Ptr) where T
        # isbitstype(T) || throw(ArgumentError("$T is not a bitstype"))
        new{T}(p)
    end
end

function Base.propertynames(::CStruct{T}) where T
    fieldnames(T)
end

function Base.getproperty(cs::CStruct{T}, field::Symbol) where T
    fp = pointer_from_field(cs, field)
    FT = reftype(fp)
    if isprimitivetype(FT)
        v = unsafe_load(fp)
        jconvert(FT, v)
    else
        CStruct{FT}(fp)
    end
end

function Base.setproperty!(cs::CStruct{T}, field::Symbol, v) where T
    fp = pointer_from_field(cs, field)
    FT = reftype(fp)
    v = Base.unsafe_convert(FT, Base.cconvert(FT, v))
    unsafe_store!(fp, v)
end

function Base.show(io::IO, x::CStruct{T}) where T
    show(io, typeof(x))
    print(io, '(')
    nf = length(T.types)
    ref = getfield(x, :p)
    if !Base.show_circular(io, ref)
        recur_io = IOContext(io, Pair{Symbol,Any}(:SHOWN_SET, ref),
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

"""
    pointer_from_field(cs::CStruct{T}, fieldname) where T

For `cs` return pointer to member field `fieldname`.
The pointer has type `Ptr{fieldtype(T, i)}` with `i` the number of the field
within struct type `T`. 
"""
function pointer_from_field(cs::CStruct{T}, field::Symbol) where T
    i = findfirst(Base.Fix1(isequal, field), fieldnames(T))
    i === nothing && throw(ArgumentError("type $T has no field $field"))
    Ptr{fieldtype(T, i)}(getfield(cs, :p) + fieldoffset(T, i))
end

reftype(::Ptr{T}) where T = T

jconvert(::Type, v) = v
jconvert(::Type{Cstring}, v) = v == C_NULL ? "" : Base.unsafe_string(v)
jconvert(::Type{Ptr{T}}, v) where T = v == C_NULL ? nothing : CStruct{T}(v)
jconvert(::Type{T}, v) where T<:CStruct = T(v)

Base.unsafe_convert(::Type{Ptr{T}}, cs::CStruct{T}) where T = getfield(cs, :p) 
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
