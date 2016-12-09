using Base.Test, Compat
f_irisws = "out1.sac"
f_irisget = "out2.sac"
ts = "2016-03-23T23:10:00"
te = "2016-03-23T23:17:00"
chans = ["UW.TDH.EHZ"; "UW.VLL.EHZ"; "UW.HOOD.BHZ"]

println("...IRISws...")
SAC = irisws(net="CC", sta="JRO", cha="BHZ", s=ts, t=te, fmt="sacbl",w=true)
T = irisws(net="CC", sta="JRO", cha="BHZ", s=ts, t=te, fmt="miniseed",w=true)
@test_approx_eq(SAC.x[1], T.x[1])
@test_approx_eq(length(SAC.x[1]), length(T.x[1]))
rm("2016.83.23.10.00.CC.TIMB..EHZ.R.SAC")
rm("2016.83.23.10.00.CC.TIMB..EHZ.R.mseed")

println("...IRISget...")
st = 0.0
en = 60.0
(d0,d1) = parsetimewin(st,en)
U = IRISget(chans, s=d0, t=d1, w=true)
if isempty(U)
  warn("No data retrieved; rerun test later, stations are offline.")
else
  L = [length(U.x[i])/U.fs[i] for i = 1:U.n]
  t = [U.t[i][1,2] for i = 1:U.n]
  L_min = minimum(L)
  L_max = maximum(L)
  t_min = minimum(t)
  t_max = maximum(t)
  @test_approx_eq(L_max - L_min <= maximum(1./U.fs), true)
  @test_approx_eq(t_max - t_min <= maximum(1./U.fs), true)
end
