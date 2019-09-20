import SeisIO.SeisHDF:read_asdf, read_asdf!, id_match
printstyled("  ASDF\n", color=:light_green)
printstyled("    read_hdf5\n", color=:light_green)

id = "CI.SDD..HHZ"
idr = "C*.SDD..HH?"
hdf = path*"/SampleFiles/2019_07_07_00_00_00T2019_07_09_00_00_00.h5"
ts = "2019-07-07T23:00:00"
te = "2019-07-08T02:00:00"

# id_match
S2 = SeisData(SeisChannel(), SeisChannel(id="CI.SDD..HHZ"))
@test id_match(id, S2) == id_match(idr, S2) == [2]

S1 = SeisData()
read_hdf5!(S1, hdf, id = id, s = ts, t = te)
S2 = read_hdf5(hdf, id = id, s = ts, t = te)
@test S1 == S2
S2 = read_asdf(hdf, id, ts, te, true, 0)
@test S1 == S2

# check file wildcards
hdf_pat = path*"/SampleFiles/2019_07_07_00_00_00T2019_07_09_00_00_00.h*"
S2 = read_hdf5(hdf_pat, id = id, s = ts, t = te)
@test S1 == S2

# check that FDSN-style wildcards work
S2 = read_asdf(hdf, idr, ts, te, true, 0)
@test S1 == S2

# Check channel matching
S2 = SeisData(SeisChannel(id="CI.SDD..HHZ"))
read_asdf!(S2, hdf, idr, ts, te, true, 0)
@test S1 == S2

printstyled("    scan_hdf5\n", color=:light_green)
@test scan_hdf5(hdf) == ["CI.SDD"]
@test scan_hdf5(hdf, level="channel") == ["/Waveforms/CI.SDD/CI.SDD..HHZ",
                                          "/Waveforms/CI.SDD/StationXML" ]
@test_throws ErrorException scan_hdf5(hdf, level="response")
@test_throws ErrorException scan_hdf5(hdf, fmt="MatlabLol")
