
# US Test
println(stdout, "...FDSN data request from IRIS...")
fname = path*"/SampleFiles/fdsn.conf"
S = SeisData()
get_data!(S, "FDSN", fname; src="IRIS", s=-600, t=0, v=0);

# Ensure station headers are set
j = findid(S, "UW.HOOD..ENE")
@test ≈(S.fs[j], 100.0)

# Ensure we got data
L = [length(x) for x in S.x]
@test (isempty(L) == false)
@test (maximum(L) > 0)

# Test a bum data format
get_data!(S, "FDSN", "UW.LON.."; src="IRIS", s=-600, t=0, v=3, fmt="geocsv");

# FDSNevq
println(stdout, "...FDSNevq...")
S = FDSNevq("201103110547", mag=[3.0, 9.9], nev=10, src="IRIS", v=0);
@assert(length(S)==9)

# FDSNsta
println(stdout, "...FDSN station query (seismometers + strainmeters)...");
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??", v=0);
@test (findid(S, "PB.B001.T0.BS1")>0)
@test (findid(S, "PB.B001..EHZ")>0)
@test (findid(S, "CC.VALT..BHZ")>0)

# FDSNevt
println(stdout, "...FDSN event request...")
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?", v=0);

# Potsdam test
println(stdout, "...Potsdam FDSN data request...")
R = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
@assert(isempty(R)==false)
println("...done!")
