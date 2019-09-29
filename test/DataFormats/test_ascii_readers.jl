lenn_file = string(path, "/SampleFiles/0215162000.c00")
geocsv_file = string(path, "/SampleFiles/geo-tspair.csv")
slist_file = string(path, "/SampleFiles/1h-62.5hz.slist")

printstyled("  Lennartz ASCII\n", color=:light_green)
C = read_data("lennasc", lenn_file)[1]
@test ≈(C.fs, 62.5)

printstyled("    wildcard support\n", color=:light_green)
S = read_data("lennasc", string(path, "/SampleFiles/021516*c00"))

printstyled("  GeoCSV timeseries\n", color=:light_green)
S = read_data("geocsv", geocsv_file)
@test S.n == 8
if Sys.iswindows()
  println("    IDs = ", join(S.id, ","))
end
i = findid("CC.JRO..BHZ", S.id)
if i > 0
  @test ≈(S.fs[i], 50.0)
  @test ==(S.loc[i], GeoLoc(lat=46.275269, lon=-122.218262, el=1219.0, inc=180.0))
end

printstyled("    wildcard support\n", color=:light_green)
S = read_data("geocsv", string(path, "/SampleFiles/geo-tspair.*"))

printstyled("  slist\n", color=:light_green)
S2 = read_data("slist", slist_file)
nx = length(S2.x[1])
@test ≈(S2.fs[1], 62.5)
@test isapprox(C.x[1:nx], S2.x[1])

printstyled("    wildcard support\n", color=:light_green)
S = read_data("slist", string(path, "/SampleFiles/*.slist"))
