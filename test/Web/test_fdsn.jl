fname = path*"/SampleFiles/fdsn.conf"
hood_reg = Float64[44.8, 46.0, -122.4, -121.0]
rainier_rad = Float64[46.852886, -121.760374, 0.0, 0.1]
sac_pz_file = path*"/SampleFiles/test_sac.pz"

printstyled("  FDSN web requests\n", color=:light_green)

# FDSNsta
printstyled("    FDSNsta\n", color=:light_green)
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")
for i in ("PB.B001.T0.BS1", "PB.B001..EHZ", "CC.VALT..BHZ")
  j = findid(S, i)
  try
    @test j > 0
  catch
    @warn(string("No data from ", i, "; check connection!"))
  end
end

# FDSNsta with MultiStageResp
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??", msr=true)

printstyled("      radius search (rad=)\n", color=:light_green)
rad = Float64[45.373514, -121.695919, 0.0, 0.1]
S = FDSNsta(rad=rainier_rad)
try
  @test S.n > 0 # Test will break if everything around Mt. Rainier is offline
catch
  @warn("Stations around Mt. Rainier appear to be offline.")
end

printstyled("      rectangular search (reg=)\n", color=:light_green)
S = FDSNsta(reg=hood_reg)
try
  @test S.n > 0 # Test will break if everything around Mt. Hood is offline
catch
  @warn("Stations around Mt. Rainier appear to be offline.")
end
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
  else
    @warn(string("No data from ", ids[i], "; check connection!"))
  end
end

# Check that headers get overwritten with SACPZ info when we use read_sacpz
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

# Check that msr=true works
S = SeisData()
get_data!(S, "FDSN", fname, src="IRIS", msr=true, s=-600, t=0)
if isempty(S)
  warn("Empty request; check connectivity!")
else
  for i in 1:S.n
    @test typeof(S.resp[i]) == MultiStageResp
  end
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
id = "CI.ADO..BHE"
i = findid(S, id)
if i == 0
  @warn(string("No data from ", id, "; check connection!"))
elseif isempty(S)
  @warn(string("Request empty; rest of test skipped!"))
else
  # Check that we have two complete days of data with no gaps

  if (length(S.x[i]) / (86400*S.fs[i])) != 2.0
    @warn(string("Partial outage; missing data from ", id, "; check connection!"))
  end

  # Check that these data can be written and read faithfully in SAC and SeisIO formats
  writesac(S)
  wseis("sacreq.seis", S)
  S2 = rseis("sacreq.seis")[1]
  @test S == S2

  # These are the only fields preserved; :loc is preserved to Float32 precision
  S1 = read_data("sac", "2018.032*CI.ADO..BH*SAC")
  for f in (:id, :fs, :gain, :t, :x)
    @test getfield(S, f) == getfield(S1, f)
  end
  for f in (:lat, :lon, :el, :dep, :az, :inc)
    @test isapprox(getfield(S.loc[i], f), getfield(S1.loc[i], f), atol=1.0e-3)
  end

  # clean up
  rm("sacreq.seis")
end


# A bad data format should produce a warning
printstyled("      request an unparseable format (sac.zip)\n", color=:light_green)

redirect_stdout(out) do
  get_data!(S, "FDSN", "UW.LON.."; src="IRIS", s=-600, t=0, v=3, fmt="sac.zip")
end

# Potsdam test
printstyled("      request from GFZ\n", color=:light_green)
S = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
if isempty(S)
  @warn(string("No data from GFZ request; check connection!"))
end

# ❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄ (oh, California...)
printstyled("    servers with special headers:\n", color=:light_green)
ds = now()-Day(1)
ds -= Millisecond(ds)
s = string(ds)
t = string(ds+Hour(1))

rubric = [
  "NCEDC" "BK.MOD..BHE"
  "SCEDC" "CI.SDD..BHZ"
]
❄ = size(rubric, 1)

for i = 1:❄
  printstyled("      ", rubric[i,1], ":\n", color=:light_green)
  printstyled("        station info\n", color=:light_green)
  S = FDSNsta(rubric[i,2], s=s, t=t, msr=true, src=rubric[i,1])
  if isempty(S)
    printstyled("        No data; check headers & connection!\n", color=:red)
  end

  printstyled("        trace data\n", color=:light_green)
  S = get_data("FDSN", rubric[i,2], src=rubric[i,1], s=s, t=t, msr=true, w=true)
  if isempty(S)
    printstyled("        No data; check headers & connection!\n", color=:red)
  end
end
