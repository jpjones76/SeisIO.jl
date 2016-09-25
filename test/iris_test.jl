using Base.Test, Compat
println("IRIS tests...")

f_irisws = "out1.sac"
f_irisget = "out2.sac"
ts = "2016-03-23T23:10:00"
te = "2016-03-23T23:17:00"
chans = ["UW.TDH.EHZ"; "UW.VLL.EHZ"; "CC.TIMB.EHZ"]

println("...IRISws...")
SAC = irisws(net="CC", sta="TIMB", cha="EHZ", s=ts, t=te, fmt="sacbl")
T = irisws(net="CC", sta="TIMB", cha="EHZ", s=ts, t=te, fmt="miniseed")
@test_approx_eq(SAC["data"][1], T.x[1][1])
@test_approx_eq(SAC["npts"], length(T.x[1]))

println("...IRISget...")
U = IRISget(chans, t=300, v=true)
L = [length(U.x[i])/U.fs[i] for i = 1:U.n]
t = [U.t[i][1,2] for i = 1:U.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test_approx_eq(L_max - L_min <= maximum(1./U.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./U.fs), true)
