fname = path*"/SampleFiles/fdsn.conf"
hood_reg = Float64[44.8, 46.0, -122.4, -121.0]
rainier_rad = Float64[46.852886, -121.760374, 0.0, 0.1]

printstyled("  FDSN web requests\n", color=:light_green)

printstyled("    get_data with GeoCSV\n", color=:light_green)
S = get_data("FDSN", "CC.JRO..BHZ,IU.COLA.00.*", src="IRIS", s=-600, t=0, fmt="geocsv", w=true)

# FDSNsta
printstyled("    FDSNsta\n", color=:light_green)
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")
@test (findid(S, "PB.B001.T0.BS1")>0)
@test (findid(S, "PB.B001..EHZ")>0)
@test (findid(S, "CC.VALT..BHZ")>0)

printstyled("    FDSNsta with a radius search (rad=)\n", color=:light_green)
rad = Float64[45.373514, -121.695919, 0.0, 0.1]
S = FDSNsta(rad=rainier_rad)
@test S.n > 0 # Test will break if everything around Mt. Rainier is offline

printstyled("    FDSNsta with a rectangular search (reg=)\n", color=:light_green)
S = FDSNsta(reg=hood_reg)
@test S.n > 0 # Test will break if everything around Mt. Hood is offline

printstyled("    get_data with a config file for channel spec\n", color=:light_green)

S = SeisData()
get_data!(S, "FDSN", fname, src="IRIS", s=-600, t=0, w=true)
deleteat!(S, findall(S.fs.<25.0))
filtfilt!(S, fl=0.01, fh=10.0)

# Ensure station headers are set
j = findid(S, "UW.HOOD..ENE")
@test ≈(S.fs[j], 100.0)

# Ensure we got data
L = [length(x) for x in S.x]
@test (isempty(L) == false)
@test (maximum(L) > 0)

# Try a string array for input
printstyled("    get_data with a string array for channel spec\n", color=:light_green)
S = SeisData()
get_data!(S, "FDSN", ["UW.HOOD..E??", "CC.VALT..???", "UW.XNXNX.99.QQQ"], src="IRIS", s=-600, t=0, opts="szsrecs=true")

# Try a single string
printstyled("    get_data with a string for channel spec\n", color=:light_green)
S = get_data("FDSN", "CC.JRO..BHZ,IU.COLA.00.*", src="IRIS", s=-600, t=0)

# A bad data format should produce a warning
printstyled("    get_data from IRIS with a bad request (should produce info but no warning)\n", color=:light_green)
open("runtests.log", "a") do out
  redirect_stdout(out) do
    get_data!(S, "FDSN", "UW.LON.."; src="IRIS", s=-600, t=0, v=3, fmt="sac.zip")
  end
end

# Potsdam test
printstyled("    get_data from GFZ\n", color=:light_green)
R = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
@test (isempty(R)==false)

# FDSNevq
printstyled("    FDSNevq (event header query)\n", color=:light_green)
S = FDSNevq("201103110547", mag=[3.0, 9.9], nev=10, src="IRIS", v=0)
@test length(S)==9

printstyled("    FDSNevq with a radius search (rad=)\n", color=:light_green)
S = FDSNevq("20190101000000", rad=rainier_rad, evw=[31536000.0, 31536000.0], mag=[0.0, 2.9], nev=100, src="IRIS", v=0)

printstyled("    FDSNevq with a partly-specified region search (reg=)\n", color=:light_green)
S = FDSNevq("20120601000000", reg=hood_reg, evw=[31536000.0, 31536000.0], mag=[0.0, 2.9], nev=100, src="IRIS", v=0)

# FDSNevt
printstyled("    FDSNevt (event header and data query)\n", color=:light_green)
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?", v=0)
