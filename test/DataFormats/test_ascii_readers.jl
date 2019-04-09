lenn_file = string(path, "/SampleFiles/0215162000.c00")
geocsv_file = string(path, "/SampleFiles/FDSNWS.IRIS.geocsv")

printstyled("  Lennartz ASCII\n", color=:light_green)
C = rlennasc(lenn_file)
@test(occursin("rlennasc", C.src))
@test ≈(C.fs, 62.5)

printstyled("  GeoCSV timeseries\n", color=:light_green)
S = readgeocsv(geocsv_file)
@test S.n == 8
i = findid("CC.JRO..BHZ", S)
@test ≈(S.fs[i], 50.0)
@test ≈(S.loc[i], [46.275269, -122.218262, 1219.0, 0.0, -90.0, 0.0])
