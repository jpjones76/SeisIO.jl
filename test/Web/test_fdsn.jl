fname = path*"/SampleFiles/fdsn.conf"
sac_pz_file = path*"/SampleFiles/SAC/test_sac.pz"
hood_reg = Float64[44.8, 46.0, -122.4, -121.0]
rainier_rad = Float64[46.852886, -121.760374, 0.0, 0.1]
h5file = "sacreq.h5"
seisfile = "sacreq.seis"

printstyled("  FDSN web requests\n", color=:light_green)

safe_isfile(h5file) && safe_rm(h5file)

printstyled("    fdsn_chp\n", color=:light_green)

# fdsn_chp
c1 = "CC.VALT..,PB.B001..BS?,PB.B001..E??,XX.YYY.00.BHZ"
c2 = ["CC.VALT..", "PB.B001..BS?", "PB.B001..E??", "XX.YYY.00.BHZ"]
c3 = ["CC" "VALT" "" ""; "PB" "B001" "" "BS?"; "PB" "B001" "" "E??"; "XX" "YYY" "00" "BHZ"]
try
  @test (minreq(SeisIO.fdsn_chp(c1, 0)))[:,1:4] == SeisIO.fdsn_chp(c2, 0)[:,1:4] == minreq(SeisIO.fdsn_chp(c3, 0))
catch err
  @warn("Inconsistent reslts from fdsn_chp!")
end

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

# With autoname
printstyled("      get_data(\"FDSN\", ..., autoname=true)\n", color=:light_green)
req_f = "2019.001.00.00.00.000.UW.VLL..EHZ.R.mseed"
req_ok = (try
    S = check_get_data("FDSN", "UW.VLL..EHZ", src="IRIS", s="2019-01-01", t=3600, autoname=true)
    true
  catch
    @warn("Station VLL appears to be offline; test skipped.")
    false
  end)
if req_ok
  @test safe_isfile(req_f)
  rm(req_f)

  printstyled("        test match to IRIS filename convention\n", color=:light_green)
  S = check_get_data("IRIS", "UW.VLL..EHZ", s="2019-01-01", t=3600, autoname=true)
  @test safe_isfile(req_f)
end

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
S = check_get_data("FDSN", "CC.JRO..BHZ,IU.COLA.00.*", src="IRIS", s=-600, t=0, fmt="geocsv", w=true)
S = check_get_data("FDSN", "CC.JRO..BHZ,CC.VALT.*", src="IRIS", s=-300, t=0, fmt="geocsv.slist")

printstyled("      config file for channel spec\n", color=:light_green)

S = SeisData()
check_get_data!(S, "FDSN", fname, src="IRIS", s=-600, t=0, w=true)
# Ensure we got data
if (isempty(S) ? 0 : maximum([length(x) for x in S.x])) == 0
  @warn("Request returned no data")
else
  printstyled("        writesac with channel range on this request\n", color=:light_green)
  if S.n > 3
    writesac(S, chans=1:2)
    for i in 1:2
      @test any([(occursin("writesac", n) && occursin(S.id[i], n)) for n in S.notes[i]])
    end
  end

  printstyled("        bandpass filtering of this request\n", color=:light_green)
  deleteat!(S, findall(S.fs.<25.0))
  filtfilt!(S, fl=0.01, fh=10.0)
  for i in 1:2
    @test any([occursin("processing", n) for n in S.notes[i]])
  end
end

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

# Check that msr=true works
S = SeisData()
check_get_data!(S, "FDSN", fname, src="IRIS", msr=true, s=-600, t=0)
if isempty(S)
  @warn("Empty request; check connectivity!")
else
  for i in 1:S.n
    @test typeof(S.resp[i]) == MultiStageResp
  end
end

# Try a string array for input
printstyled("      string array for channel spec\n", color=:light_green)
S = SeisData()
check_get_data!(S, "FDSN", ["UW.HOOD..E??", "CC.VALT..???", "UW.XNXNX.99.QQQ"], src="IRIS", s=-600, t=0, opts="szsrecs=true")

# Try a single string
printstyled("      string for channel spec\n", color=:light_green)
S = check_get_data("FDSN", "CC.JRO..BHZ,IU.COLA.00.*", src="IRIS", s=-600, t=0, v=1,
  demean=true,
  detrend=true,
  rr=true,
  taper=true,
  ungap=true,
  unscale=true)

# This should return exactly 4 days of data, which we know IRIS' FDSN server has
printstyled("      multi-day request\n", color=:light_green)
ts = "2018-01-31T00:00:00"
te = "2018-02-02T00:00:00"
S = get_data("FDSN", "CI.ADO..BH?", s=ts, t=te)
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

  printstyled("        are data written identically?\n", color=:green)

  # get rid of bad request channels
  k = Int64[]
  append!(k, findall([startswith(id, "XX.FAIL") for id in S.id]))
  append!(k, findall([startswith(id, "XX.FMT") for id in S.id]))
  isempty(k) || deleteat!(S, k)

  # write ASDF first, since this modifies the first sample start time in S
  write_hdf5(h5file, S, add=true, ovr=true, len=Day(2))
  S1 = read_hdf5(h5file, ts, te, msr=false)

  for f in (:id, :loc, :fs, :gain, :resp, :units, :misc)
    @test isequal(getfield(S1,f), getfield(S,f))
  end
  for i in 1:S.n
    (isempty(S.x[i]) || isempty(S1.x[i])) && continue
    x1 = S1.x[i]
    x2 = S.x[i]
    if (any(isnan.(x1)) == false) && (any(isnan.(x2)) == false)
      @test x1 ≈ x2
    end
  end

  # Check that these data can be written and read faithfully in ASDF, SAC, and SeisIO
  writesac(S)
  wseis(seisfile, S)
  S2 = rseis(seisfile)[1]
  if !(isempty(S) || isempty(S2))
    for f in (:id, :loc, :fs, :gain, :resp, :units, :misc)
      @test isequal(getfield(S2,f), getfield(S,f))
    end
    for i in 1:S.n
      x1 = S.x[i]
      x2 = S2.x[i]
      if (any(isnan.(x1)) == false) && (any(isnan.(x2)) == false)
        @test x1 ≈ x2
      end
    end
  end

  # These are the only fields preserved; :loc is preserved to Float32 precision
  d0 = DateTime(ts)
  y0 = Year(d0).value
  j0 = md2j(y0, Month(d0).value, Day(d0).value)
  sac_str = string(y0, ".", lpad(j0, 3, '0'), "*CI.ADO..BH*SAC")
  S1 = read_data("sac", sac_str)
  for f in (:id, :fs, :gain, :t)
    @test getfield(S, f) == getfield(S1, f)
    @test getfield(S, f) == getfield(S2, f)
  end
  for f in (:lat, :lon, :el, :dep, :az, :inc)
    @test isapprox(getfield(S.loc[i], f), getfield(S1.loc[i], f), atol=1.0e-3)
  end
  for i in 1:S.n
    x = S.x[i]
    x1 = S1.x[i]
    x2 = S2.x[i]
    if (any(isnan.(x)) == false) && (any(isnan.(x1)) == false) && (any(isnan.(x2)) == false)
      @test x ≈ x1
      @test x1 ≈ x2
    end
  end

  # clean up
  safe_rm(seisfile)
  safe_rm(h5file)
end

# A bad data format should produce warnings and "error" channels
printstyled("      bad request logging\n", color=:light_green)
redirect_stdout(out) do
  try
    S = SeisData()
    bad_id = "DE.NENA.99.LUFT"

    # this should return a request error channel with ID = XX.FAIL..001
    get_data!(S, "FDSN", bad_id, v=3, si=false, fmt="sac.zip")

    # this should return a format error channel with ID = XX.FMT..001
    get_data!(S, "FDSN", "UW.LON.."; src="IRIS", s=-600, t=0, v=3, fmt="sac.zip")

    # Check that the info appears where it needs to
    @test S.id[1] == "XX.FAIL..001"
    @test any([occursin("request failed", n) for n in S.notes[1]])
    @test haskey(S.misc[1], "msg")

    @test S.id[S.n] == "XX.FMT..001"
    @test any([occursin("unparseable format", n) for n in S.notes[S.n]])
    @test haskey(S.misc[S.n], "raw")
  catch err
    @warn(string("Bad request logging test failed; caught error ", err))
  end
end

# Potsdam test
printstyled("      request from GFZ\n", color=:light_green)
S = check_get_data("FDSN", "GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
if isempty(S)
  @warn(string("No data from GFZ request; check connection!"))
end

# ❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄ (oh, California...)
printstyled("    servers with special headers:\n", color=:light_green)
rubric = [
  "NCEDC" "BK.MOD..BHE"
  "SCEDC" "CI.SDD..BHZ"
]
❄ = size(rubric, 1)

for i = 1:❄
  printstyled("      ", rubric[i,1], ":\n", color=:light_green)
  ds = now()-Day(1)
  ds -= Millisecond(ds)
  s = string(ds)
  t = string(ds+Hour(1))
  try
    printstyled("        station info\n", color=:light_green)
    S = FDSNsta(rubric[i,2], s=s, t=t, msr=true, src=rubric[i,1])
    printstyled("        trace data\n", color=:light_green)
    get_data!(S, "FDSN", rubric[i,2], src=rubric[i,1], s=s, t=t, msr=true)
    if isempty(S)
      printstyled("        No data; check headers & connection!\n", color=:red)
    end
  catch err
    @warn(string("Request errored; error output below.\n\n", err))
  end
end

printstyled("    issues 42 & 43\n", color=:light_green)
redirect_stdout(out) do
  S = get_data("FDSN", "IU.ANMO.00.LHZ", s="2019-02-14", t="2019-02-15", v=3)

  # This should have two "fail" channels; one from each day with no data
  S = get_data("FDSN", "C0.HAYD.00.LHZ", s="2019-01-01", t="2019-01-05", v=3)
  @test S.n == 3
end

# test IRISPH5 mseed
printstyled("    IRISPH5\n", color=:light_green)
s = DateTime(2016,6,23)
t = s + Minute(1) # this is 250 Hz data
id = "YW.1002..DP?"
printstyled("      station info\n", color=:light_green)
S = FDSNsta(id, src="IRISPH5", s=s, t=t, msr=true)
printstyled("      trace data\n", color=:light_green)
printstyled("        mini-SEED\n", color=:light_green)
get_data!(S, "FDSN", id, src="IRISPH5", s=s, t=t, msr=true)
S = get_data("PH5", id, s=s, t=t, opts="reduction=10")
printstyled("        GeoCSV tspair\n", color=:light_green)
S = get_data("FDSN", id, src="IRISPH5", s=s, t=t, msr=true, fmt="geocsv.tspair")
printstyled("        GeoCSV slist\n", color=:light_green)
S = get_data("FDSN", id, src="IRISPH5", s=s, t=t, msr=true, fmt="geocsv.slist")

# these will fail
# need to implement multi-channel version of read_sac_stream
# segy in FDSN-like requests is NYI
printstyled("        SAC (should fail)\n", color=:light_green)
S = get_data("FDSN", id, src="IRISPH5", s=s, t=t, msr=true, fmt="sac")
printstyled("        segy1 (NYI)\n", color=:light_green)
S = get_data("FDSN", id, src="IRISPH5", s=s, t=t, msr=true, fmt="segy1")
printstyled("        segy2 (NYI)\n", color=:light_green)
S = get_data("FDSN", id, src="IRISPH5", s=s, t=t, msr=true, fmt="segy2")

printstyled("        unsupported format\n", color=:light_green)
S = get_data("FDSN", id, src="IRISPH5", s=s, t=t, fmt="nothing")
