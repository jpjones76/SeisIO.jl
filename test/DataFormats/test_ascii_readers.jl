lenn_file = string(path, "/SampleFiles/0215162000.c00")
geocsv_file = string(path, "/SampleFiles/FDSNWS.IRIS.geocsv")

printstyled("  Lennartz ASCII\n", color=:light_green)
C = read_data("lennasc", lenn_file)[1]
@test ≈(C.fs, 62.5)

printstyled("    wildcard support\n", color=:light_green)
S = read_data("lennasc", string(path, "/SampleFiles/021516*c00"))

printstyled("  GeoCSV timeseries\n", color=:light_green)
S = read_data("geocsv", geocsv_file)
@test S.n == 8
i = findid("CC.JRO..BHZ", S)
@test ≈(S.fs[i], 50.0)
@test ==(S.loc[i], GeoLoc(lat=46.275269, lon=-122.218262, el=1219.0, inc=180.0))

printstyled("    wildcard support\n", color=:light_green)
S = read_data("geocsv", string(path, "/SampleFiles/FDSNWS.IRIS.geo*"))
