using ASCIIrasters
using Test

@testset verbose = true "ASCIIrasters.jl" begin
    asc = read_ascii("../example/small.asc")
    @testset "read" begin
        @test read_ascii("../example/small.asc"; lazy = true) isa NamedTuple
        @test asc[1][2,3] == 3
        @test asc[1][4,5] == 6
        @test typeof(asc[1]) == Matrix{Int32}
        @test_throws ArgumentError read_ascii("doesntexist.asc")
    end

    pars = (
            ncols = 4,
            nrows = 4,
            xll = 15,
            yll = 12,
            dx = 1,
            dy = 1,
            nodatavalue = 1,
        )
    dat = [1 1 1 1;2 2 2 2;3 3 3 3;4 4 4 4]

    @testset "write" begin
        pars2 = (
            ncols = 4,
            nrows = 4,
            xll = 15,
            yll = 12,
            dx = 1,
            dy = 1,
        ) # optional nodatavalue argument
        @test write_ascii("./test.asc", dat, pars) == "./test.asc"
        @test write_ascii("./test.asc", dat, pars2) == "./test.asc"
    end

    float_asc = read_ascii("test.asc")

    @testset "read and write" begin
        @test float_asc != asc
        @test typeof(float_asc[1]) == Matrix{Float32}
        example2 = write_ascii("../example/small2.asc", asc[1], asc[2])
        @test read_ascii("../example/small2.asc")[1] == asc[1]
    end

    @testset "type conversion" begin
        # nodatavalue is 1 so array will be coerced to 1
        test2 = write_ascii("./test2.asc", dat, pars; detecttype = true)
        @test typeof(read_ascii(test2)[1][1,1]) == Int32

        # trying to detecttype with wrong arguments will throw an IE
        # because Int(x::Float32) is not defined
        dat2 = [1.5 1 1 1;2 2 2 2;3 3 3 3;4 4 4 4]
        @test_throws InexactError write_ascii("./test3.asc", dat2, pars; detecttype = true)

        # Float32(x::Int) is allowed
        @test write_ascii("./test4.asc", dat2, (
            ncols = 4,
            nrows = 4,
            xll = 15,
            yll = 12,
            dx = 1,
            dy = 1,
            nodatavalue = 1.0,
        ); detecttype = true) == "./test4.asc"

        # weird nodatavalue types are explicitly not allowed
        @test_throws TypeError write_ascii("./test4.asc", dat2, (
            ncols = 4,
            nrows = 4,
            xll = 15,
            yll = 12,
            dx = 1,
            dy = 1,
            nodatavalue = "1.0",
        ); detecttype = true)
    end

    @testset "_read_header" begin
        a = ASCIIrasters._read_header("../example/cellsize.asc")
        b = ASCIIrasters._read_header("../example/cellsizeanddx.asc")
        c = ASCIIrasters._read_header("../example/nonodata.asc")
        @test length(a) == 9
        @test length(b) == 9
        @test length(c) == 9
        @test !haskey(b, "cellsize")
        @test !haskey(a, "cellsize")
        @test c["datatype"] == Any
    end

    @testset "detect type from data" begin
        d = ASCIIrasters.read_ascii("../example/nonodata.asc")
        e = ASCIIrasters.read_ascii("../example/nonodatafloat.asc")
        @test typeof(d[1]) == Matrix{Int32}
        @test typeof(e[1]) == Matrix{Float32}

        @test_throws "nrows not found in file header" ASCIIrasters.read_ascii("../example/missingnrow.asc")
    end

    @testset "test different whitespaces" begin
        d,h = ASCIIrasters.read_ascii("../example/swisstopo.asc")
        @test size(d)==(h.nrows,h.ncols)
    end

    # cleanup
    rm("./test.asc")
    rm("./test2.asc")
    rm("./test4.asc")
    rm("../example/small2.asc")
end
