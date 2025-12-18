using Documenter
using TerrariaWiringHelper
using TerrariaWiringHelper: AND, XOR, logicsymb, fuse, gate2string, lampstate2string
using Test


@testset "Utils" begin
    @testset "AND" begin
        @test AND(true)
        @test !AND(false)

        @test AND(true, true)
        @test !AND(true, false)
        @test !AND(false, true)
        @test !AND(false, false)

        @test AND(true, true, true)
        @test !AND(true, true, false)
        @test !AND(true, false, true)
        @test !AND(false, true, true)
        @test !AND(true, false, false)
        @test !AND(false, true, false)
        @test !AND(false, false, true)
        @test !AND(false, false, false)
    end
    @testset "XOR" begin
        @test XOR(true)
        @test !XOR(false)

        @test !XOR(true, true)
        @test XOR(true, false)
        @test XOR(false, true)
        @test !XOR(false, false)

        @test !XOR(true, true, true)
        @test !XOR(true, true, false)
        @test !XOR(true, false, true)
        @test !XOR(false, true, true)
        @test XOR(true, false, false)
        @test XOR(false, true, false)
        @test XOR(false, false, true)
        @test !XOR(false, false, false)
    end
    @testset "logicsymb" begin
        @test logicsymb(AND) == '&'
        @test logicsymb(XOR) == '^'
    end
    @testset "fuse" begin
        @test !fuse(0)
        @test fuse(1)
        @test fuse(2)
        @test !fuse(3)
        @test fuse(4)
        @test !fuse(5)
        @test !fuse(6)
        @test fuse(7)

        @test !fuse(0, 0)
        @test fuse(1, 1)
    end
end

@testset "Z2LinearAlgebra" begin
    @testset "constructor" begin
        @test Z2Vector(0b10110, 5) isa AbstractVector{Bool}
        @test Z2Vector([false, true, true, false, true]) == Z2Vector(0b10110, 5)

        v = Z2Vector(0b110110, 5)
        @test v.data ≡ 0b10110
        @test v.size ≡ 5
    end
    @testset "index" begin
        v = Z2Vector(0b10110, 5)

        @test_throws BoundsError v[0]
        @test_throws BoundsError v[6]

        @test v == [false, true, true, false, true]

        @test typeof(v[:]) == typeof(v[1:5]) == typeof(v)
        @test v[:] == v[1:5] == v
    end
    @testset "reduce" begin
        v = Z2Vector(0b10110, 5)
        @test sum(v) ≡ true
        @test prod(v) ≡ false
        @test any(v) ≡ true
        @test all(v) ≡ false
    end
    @testset "algebra" begin
        u = Z2Vector(0b01101, 5)
        v = Z2Vector(0b10110, 5)

        @test u + v == Z2Vector(0b11011, 5)
        @test u - v == Z2Vector(0b11011, 5)
        @test u ⋅ v ≡ true
    end
end

@testset "LogicalGates" begin
    @testset "constructor" begin
        @test AndGate(false, 2, [0]) isa AndGate
        @test XorGate(true, 3, [0, 2]) isa XorGate
    end
    @testset "interface" begin
        @testset "==" begin
            @test AndGate(false, 2, [0]) == AndGate(false, 2, [0])
            @test AndGate(false, 2, [0]) != AndGate(true, 2, [0])
            @test AndGate(false, 2, [0]) != AndGate(false, 3, [0])
            @test AndGate(false, 2, [0]) != AndGate(false, 2, [1])

            @test XorGate(true, 3, [0, 2]) == XorGate(true, 3, [0, 2])
            @test XorGate(true, 3, [0, 2]) != XorGate(false, 3, [0, 2])
            @test XorGate(true, 3, [0, 2]) != XorGate(true, 4, [0, 2])
            @test XorGate(true, 3, [0, 2]) != XorGate(true, 3, [1, 2])

            @test AndGate(false, 2, [0]) != XorGate(false, 2, [0])
        end
        @testset "lampstates" begin
            @test lampstates(AndGate(false, 2, [0])) == [0]
            @test lampstates(XorGate(true, 3, [0, 2])) == [0, 2]
        end
        @testset "length" begin
            @test length(AndGate(false, 2, [0])) == 1
            @test length(XorGate(true, 3, [0, 2])) == 2
        end
        @testset "logicsymb" begin
            @test logicsymb(AndGate(false, 2, [0])) == '&'
            @test logicsymb(XorGate(true, 3, [0, 2])) == '^'
        end
        @testset "show" begin
            @testset "lampstate2string" begin
                @test lampstate2string(0, 2) == ""
                @test lampstate2string(1, 2) == "a"
                @test lampstate2string(2, 2) == "b"
                @test lampstate2string(3, 2) == "ab"
                @test lampstate2string(4, 2) == "~"
                @test lampstate2string(5, 2) == "~a"
                @test lampstate2string(6, 2) == "~b"
                @test lampstate2string(7, 2) == "~ab"
            end
            @testset "gate2string" begin
                @test gate2string(AndGate(false, 4, [0x12, 0x09, 0x04])) == "&(~b, ad, c)"
                @test gate2string(XorGate(true, 3, [0, 2])) == "~^(, b)"
            end
        end
    end
    @testset "colors" begin
        @testset "filtercolor" begin
            @test filtercolor(0b10101010, 0b00111100) == 0b00101000
            @test filtercolor(0b00111100) isa Function
            @test filtercolor(0b00111100)(0b10101010) == 0b00101000
        end
    end
end

DocMeta.setdocmeta!(TerrariaWiringHelper, :DocTestSetup, :(
    using TerrariaWiringHelper;
    using TerrariaWiringHelper: z2number, lampstate2string, bit2type, setbit, getbit, datamask
); recursive=true)

@testset "Doctest" begin
    doctest(TerrariaWiringHelper)
end
