# The file test.mseed comes from an older IRIS libmseed, found by anowacki
# It has a more complicated structure than the test.mseed file in more recent
# versions of libmseed, which reads with no issues
printstyled("  mini-SEED file read\n", color=:light_green)
S = readmseed(string(path, "/SampleFiles/test.mseed"), v=0)
@test isequal(S.id[1], "NL.HGN.00.BHZ")
@test ≈(S.fs[1], 40.0)
@test ≈(S.gain[1], 1.0)
@test isequal(string(u2d(S.t[1][1,2]*1.0e-6)), "2003-05-29T02:13:22.043")
@test ≈(S.x[1][1:5], [ 2787, 2776, 2774, 2780, 2783 ])

if safe_isdir(path*"/SampleFiles/Restricted")
  printstyled("    file reads with many time gaps and unusual structures\n", color=:light_green)
  S = SeisData()

  files = ls("/data2/Code/SeisIO/test/SampleFiles/Restricted/*mseed")
  for f in files
    S = SeisData()
    readmseed!(S, f, v=0)
    if occursin("SHW.UW", f)
      @test size(S.t[1]) == (434, 2)
      @test size(S.t[2]) == (10, 2)
      @test string(u2d(S.t[1][1,2]*1.0e-6)) == "1980-03-22T20:45:18.349"
      @test isequal(S.id, String[ "UW.SHW..EHZ", "UW.SHW..SHZ" ])
      @test ≈(S.fs, Float64[104.085000, 52.038997])
      @test ≈(S.x[1][1:5], Float64[-68.0, -57.0, -71.0, -61.0, -52.0])
    end
  end
end
