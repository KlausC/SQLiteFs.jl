

struct AAA
    a::Bool
    b::Int32
    c::Float64
end

struct AA
    a::Ptr{AA}
end

@testset "field access" begin
    a = fill(UInt64(0), 3)
    p = pointer_from_vector(a)
    cs = CStruct{AAA}(p)
    v1 = true
    v2 = 0x12345678
    v3 = 47.11
    cs.a = v1
    cs.b = v2
    cs.c = v3
    @test cs.a == v1
    @test cs.b == v2
    @test cs.c == v3
end

@testset "self-referencing" begin
    a = fill(UInt8(0), 100)
    p = pointer_from_vector(a)
    cs = CStruct{AA}(p)
    @test cs.a === nothing
    io = IOBuffer()
    show(io, cs)
    @test String(take!(io)) == "CStruct{AA}(nothing)"
    cs.a = cs
    @test cs.a === cs
    show(io, cs)
    @test String(take!(io)) == "CStruct{AA}(CStruct{AA}(#= circular reference @-1 =#))"
end
