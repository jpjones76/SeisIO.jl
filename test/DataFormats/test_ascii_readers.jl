lenn_file   = string(path, "/SampleFiles/ASCII/0215162000.c00")
geocsv_file = string(path, "/SampleFiles/ASCII/geo-tspair.csv")
slist_file  = string(path, "/SampleFiles/ASCII/2m-62.5hz.slist")
lenn_pat    = string(path, "/SampleFiles/ASCII/021516*c00")
geocsv_pat  = string(path, "/SampleFiles/ASCII/geo-tspair.*")
slist_pat   = string(path, "/SampleFiles/ASCII/*.slist")
geoslist_f  = string(path, "/SampleFiles/ASCII/geo-slist.csv")

printstyled("  Lennartz ASCII\n", color=:light_green)
C = verified_read_data("lennartz", lenn_file, vl=true)[1]
@test ≈(C.fs, 62.5)

printstyled("    wildcard support\n", color=:light_green)
S = verified_read_data("lennartz", lenn_pat)

printstyled("  GeoCSV timeseries\n", color=:light_green)
S = verified_read_data("geocsv", geocsv_file, vl=true)
@test S.n == 8
if Sys.iswindows()
  println("    IDs = ", join(S.id, ","))
end
i = findid("CC.JRO..BHZ", S.id)
if i > 0
  @test ≈(S.fs[i], 50.0)
  @test ==(S.loc[i], GeoLoc(lat=46.275269, lon=-122.218262, el=1219.0, inc=180.0))
end

printstyled("  GeoCSV slist\n", color=:light_green)
S = verified_read_data("geocsv.slist", geoslist_f)

printstyled("    wildcard support\n", color=:light_green)
S = verified_read_data("geocsv", geocsv_pat)

printstyled("  slist\n", color=:light_green)
S = verified_read_data("slist", slist_file, vl=true)
nx = length(S.x[1])
@test S.id[1] == "YY.ERTA..EHZ"
@test ≈(S.fs[1], 62.5)
@test isapprox(C.x[1:nx], S.x[1])

printstyled("    empty channel + check_for_gap!\n", color=:light_green)
S.t[1] = Array{Int64}(undef, 0, 2)
S.x[1] = Float32[]
verified_read_data!(S, "slist", slist_file)
@test S.id[1] == "YY.ERTA..EHZ"
@test ≈(S.fs[1], 62.5)
@test C.t[1,2] == S.t[1][1,2]
@test isapprox(C.x[1:nx], S.x[1])

printstyled("    wildcard support\n", color=:light_green)
S = verified_read_data("slist", slist_pat)
@test S.id[1] == "YY.ERTA..EHZ"
@test ≈(S.fs[1], 62.5)
@test isapprox(C.x[1:nx], S.x[1])

printstyled("  channel continuation (Issue 34)\n", color=:light_green)
printstyled("    GeoCSV.tspair\n", color=:light_green)
test_chan_ext(geocsv_file, "geocsv.tspair", "CC.JRO..BHZ", 50.0, 1, 1554777720010000)

printstyled("    GeoCSV.slist\n", color=:light_green)
test_chan_ext(geoslist_f, "geocsv.slist", "IU.ANMO.00.LHZ", 1.0, 3, 1551249000000000)

printstyled("    slist\n", color=:light_green)
test_chan_ext(slist_file, "slist", "YY.ERTA..EHZ", 62.5, 1, 1013790000000000)

printstyled("    lennartz\n", color=:light_green)
test_chan_ext(lenn_file, "lennartz", ".ERTA..c00", 62.5, 1, 1013790000000000)
