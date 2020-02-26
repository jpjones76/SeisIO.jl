ts = "2019-03-23T23:10:00"
te = "2019-03-23T23:17:00"
chans = [ "CC.JRO..BHZ",
          "CC.LON..BHZ",
          "CC.VALT..BHZ",
          "UW.HOOD..ENZ",
          "UW.HOOD..ENN",
          "UW.HOOD..ENE" ]

printstyled("  IRIS Web Services\n", color=:light_green)
printstyled("    IRISWS continuous data requests\n", color=:light_green)
printstyled("    SAC\n", color=:light_green)
for i = 1:length(chans)
  cha = chans[i]
  S = get_data("IRIS", cha, src="IRIS", s=ts, t=te, fmt="sacbl", v=0, w=true)
  sleep(5)
  T = get_data("IRIS", cha, src="IRIS", s=ts, t=te, fmt="mseed", v=0, w=true)

  if S.n == 0 || T.n == 0
    @warn(string(cha, " appears to be offline; trying next."))
    if i == lastindex(chans)
      error("No data for any station; failing test due to connection errors.")
    end
  else
    printstyled("     equivalence of SAC and MSEED requests\n", color=:light_green)
    sync!(S, s=ts, t=te)
    sync!(T, s=ts, t=te)
    @test S.x[1] ≈ T.x[1]

    # Only notes and src should be different
    for f in Symbol[:id, :name, :loc, :fs, :gain, :resp, :units, :misc , :t, :x]
      @test getfield(S,f) == getfield(T,f)
    end

    printstyled("    GeoCSV\n", color=:light_green)
    U = get_data("IRIS", cha, src="IRIS", s=ts, t=te, fmt="geocsv", v=0)
    break
  end
end

# Test bad data formats
printstyled("    bad requests and unparseable formats\n", color=:light_green)
sta_matrix = vcat(["IU" "ANMO" "00" "BHZ"],["IU" "ANMO" "00" "BHE"])
test_sta = deepcopy(sta_matrix)
ts = "2005-01-01T00:00:00"
te = "2005-01-02T00:00:00"
redirect_stdout(out) do
  # this is an unparseable format
  S = get_data("IRIS", sta_matrix, s=ts, t=te, v=2, fmt="audio")

  # this is a bad request due to the wild card
  get_data!(S, "IRIS", "IU.ANMO.*.*", s=ts, t=te, v=2, fmt="ascii")

  @test S.n == 3

  @test S.id[2] == "XX.FAIL..001"
  @test any([occursin("request failed", n) for n in S.notes[2]])
  @test haskey(S.misc[2], "msg")

  @test S.id[1] == "XX.FMT..001"
  @test any([occursin("unparseable format", n) for n in S.notes[1]])
  @test haskey(S.misc[1], "raw")
end

# check that these aren't modified in-place by the request (very old bug)
@test sta_matrix == test_sta

printstyled("    complicated IRISWS request\n", color=:light_green)
chans = ["UW.TDH..EHZ", "UW.VLL..EHZ", "CC.JRO..BHZ"] # HOOD is either offline or not on IRISws right now
st = -86400.0
en = -86100.0
(d0,d1) = parsetimewin(st,en)
S = get_data("IRIS", chans, s=d0, t=d1, y=true)
if isempty(S)
  @warn(string("No data for channels ", join(chans, ", "), "; test skipped."))
else
  L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
  t = [S.t[i][1,2] for i = 1:S.n]
  L_min = minimum(L)
  L_max = maximum(L)
  t_min = minimum(t)
  t_max = maximum(t)
  try
    @test(L_max - L_min <= maximum(2 ./ S.fs))
    @test(t_max - t_min <= round(Int64, 1.0e6 * 2.0/maximum(S.fs)))
  catch
    @warn(string("Unexpected request length; check for partial outage at IRIS for ", join(chans, ", "), "!"))
  end
end
