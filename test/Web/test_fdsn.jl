fname = path*"/SampleFiles/fdsn.conf"
hood_reg = Float64[44.8, 46.0, -122.4, -121.0]
rainier_rad = Float64[46.852886, -121.760374, 0.0, 0.1]
sac_pz_file = path*"/SampleFiles/test_sac.pz"

printstyled("  FDSN web requests\n", color=:light_green)

# FDSNsta
printstyled("    FDSNsta\n", color=:light_green)
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")
@test (findid(S, "PB.B001.T0.BS1")>0)
@test (findid(S, "PB.B001..EHZ")>0)
@test (findid(S, "CC.VALT..BHZ")>0)

printstyled("      radius search (rad=)\n", color=:light_green)
rad = Float64[45.373514, -121.695919, 0.0, 0.1]
S = FDSNsta(rad=rainier_rad)
@test S.n > 0 # Test will break if everything around Mt. Rainier is offline

printstyled("      rectangular search (reg=)\n", color=:light_green)
S = FDSNsta(reg=hood_reg)
@test S.n > 0 # Test will break if everything around Mt. Hood is offline

printstyled("    get_data\n", color=:light_green)


printstyled("      GeoCSV output\n", color=:light_green)
S = get_data("FDSN", "CC.JRO..BHZ,IU.COLA.00.*", src="IRIS", s=-600, t=0, fmt="geocsv", w=true)
S = get_data("FDSN", "CC.JRO..BHZ,CC.VALT.*", src="IRIS", s=-300, t=0, fmt="geocsv.slist")

printstyled("      config file for channel spec\n", color=:light_green)

S = SeisData()
get_data!(S, "FDSN", fname, src="IRIS", s=-600, t=0, w=true)
deleteat!(S, findall(S.fs.<25.0))
filtfilt!(S, fl=0.01, fh=10.0)

# Ensure station headers are set
ids = ["UW.HOOD..ENE", "CC.VALT..BHZ", "UW.TDH..EHZ", "UW.VLL.EHZ"]
fss = [100.0, 50.0, 100.0, 100.0]
codes = ['N', 'H', 'H', 'H']
for i = 1:4
  j = findid(S, ids[i])
  if j > 0
    @test ≈(S.fs[j], fss[i])
    @test inst_code(S, j) == codes[i]
    break
  end
end

# Check that headers with PZResp info
Nc = S.n
read_sacpz!(S, sac_pz_file)
@test S.n > Nc
i = findid("CC.VALT..BHZ", S)
if i > 0
  @test S.misc[i]["OUTPUT UNIT"] == "COUNTS"
end
i = findid("UW.HOOD..ENE", S)
if i > 0
  @test S.misc[i]["INSTTYPE"] == "ES-T-3339=Q330S+-6410"
end

# Ensure we got data
L = [length(x) for x in S.x]
if isempty(L) == false
  @test (maximum(L) > 0)
end

# Try a string array for input
printstyled("      string array for channel spec\n", color=:light_green)
S = SeisData()
get_data!(S, "FDSN", ["UW.HOOD..E??", "CC.VALT..???", "UW.XNXNX.99.QQQ"], src="IRIS", s=-600, t=0, opts="szsrecs=true")

# Try a single string
printstyled("      string for channel spec\n", color=:light_green)
S = get_data("FDSN", "CC.JRO..BHZ,IU.COLA.00.*", src="IRIS", s=-600, t=0, v=1,
  demean=true,
  detrend=true,
  rr=true,
  taper=true,
  ungap=true,
  unscale=true)

# This should return exactly 4 days of data, which we know IRIS' FDSN server has
printstyled("      multi-day request\n", color=:light_green)
S = get_data("FDSN","CI.ADO..BH?",s="2018-02-01T00:00:00",t="2018-02-03T00:00:00")
i = findid(S, "CI.ADO..BHE")

# Check that we have two complete days of data with no gaps
@test (length(S.x[i]) / (86400*S.fs[i])) == 2.0

# Check that these data can be written and read faithfully in SAC and SeisIO formats
writesac(S)
wseis("sacreq.seis", S)
S1 = read_data("sac", "2018.032*CI.ADO..BH*SAC")
S2 = rseis("sacreq.seis")[1]
@test S == S2

# These are the only fields preserved; :loc is preserved to Float32 precision
for f in (:id, :fs, :gain, :t, :x)
  @test getfield(S, f) == getfield(S1, f)
end
for f in (:lat, :lon, :el, :dep, :az, :inc)
  @test isapprox(getfield(S.loc[i], f), getfield(S1.loc[i], f), atol=1.0e-3)
end

# clean this up
rm("sacreq.seis")

# A bad data format should produce a warning
printstyled("      request an unparseable format (sac.zip)\n", color=:light_green)

redirect_stdout(out) do
  get_data!(S, "FDSN", "UW.LON.."; src="IRIS", s=-600, t=0, v=3, fmt="sac.zip")
end

# Potsdam test
printstyled("      request from GFZ\n", color=:light_green)
R = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
@test (isempty(R)==false)
