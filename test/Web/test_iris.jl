ts = "2016-03-23T23:10:00"; te = "2016-03-23T23:17:00"; sta = "CC.JRO..BHZ"

printstyled("  IRIS Web Services\n", color=:light_green)
printstyled("    IRISWS continuous data requests\n", color=:light_green)
printstyled("    SAC\n", color=:light_green)
S = get_data("IRIS", sta, src="IRIS", s=ts, t=te, fmt="sacbl", v=0, w=true)
@test(isempty(S)==false)

printstyled("    MSEED\n", color=:light_green)
T = get_data("IRIS", [sta], src="IRIS", s=ts, t=te, fmt="mseed", v=0, w=true)

printstyled("     equivalence of SAC and MSEED requests\n", color=:light_green)
@test(isempty(T)==false)
sync!(S, s=ts, t=te)
sync!(T, s=ts, t=te)
@test S.x[1] ≈ Float32.(T.x[1])

# Only notes and src should be different
for f in Symbol[:id, :name, :loc, :fs, :gain, :resp, :units, :misc , :t, :x]
  @test getfield(S,f) == getfield(T,f)
end

printstyled("    GeoCSV\n", color=:light_green)
U = get_data("IRIS", sta, src="IRIS", s=ts, t=te, fmt="geocsv", v=0)

# Test a bum data format
printstyled("    bad data format\n", color=:light_green)
sta_matrix = vcat(["UW" "LON" "" "BHZ"],["UW" "LON" "" "BHE"])
test_sta = deepcopy(sta_matrix)
redirect_stdout(out) do
  T = get_data("IRIS", sta_matrix, s=-600, t=0, v=2, fmt="audio")
end

@test sta_matrix == test_sta

# Test a bad request
printstyled("    bad request format\n", color=:light_green)
T = get_data("IRIS", "DE.NENA.99.LUFTBALLOONS", src="IRIS", s=ts, t=te, fmt="mseed", v=0)

printstyled("    complicated IRISWS request\n", color=:light_green)
chans = ["UW.TDH..EHZ", "UW.VLL..EHZ"] # HOOD is either offline or not on IRISws right now
st = -86400.0
en = -86100.0
(d0,d1) = parsetimewin(st,en)
U = get_data("IRIS", chans, s=d0, t=d1, y=true)
@test(isempty(U)==false)
L = [length(U.x[i])/U.fs[i] for i = 1:U.n]
t = [U.t[i][1,2] for i = 1:U.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test(L_max - L_min <= maximum(2 ./ U.fs))
@test(t_max - t_min <= round(Int64, 1.0e6 * 2.0/maximum(U.fs)))
