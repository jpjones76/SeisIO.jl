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

# Test a bum data format
printstyled("    bad data format\n", color=:light_green)
sta_matrix = vcat(["UW" "LON" "" "BHZ"],["UW" "LON" "" "BHE"])
test_sta = deepcopy(sta_matrix)
redirect_stdout(out) do
  T = get_data("IRIS", sta_matrix, s=-600, t=0, v=2, fmt="audio")
  T = get_data("IRIS", sta_matrix, s=-600, t=0, v=2, fmt="ascii")
end

# check that these aren't modified in-place by the request
@test sta_matrix == test_sta

# Test a bad request
printstyled("    bad request format\n", color=:light_green)
T = get_data("IRIS", "DE.NENA.99.LUFTBALLOONS", src="IRIS", s=ts, t=te, fmt="mseed", v=0)

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
