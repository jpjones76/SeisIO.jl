path = Base.source_dir()

# The file test.mseed comes from an older IRIS libmseed, found by anowacki
# It has a more complicated structure than the test.mseed file in more recent
# versions of libmseed, which reads with no issues
println("...file read...")
S = readmseed(string(path, "/SampleFiles/test.mseed"), v=3)

println("...channel info accuracy...")
@test isequal(S.id[1], "NL.HGN.00.BHZ")
@test ≈(S.fs[1], 40.0)
@test ≈(S.gain[1], 1.0)
@test isequal(string(u2d(S.t[1][1,2]*1.0e-6)), "2003-05-29T02:13:22.043")
println("...data accuracy...")
@test ≈(S.x[1][1:5], [ 2787, 2776, 2774, 2780, 2783 ])
