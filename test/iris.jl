using Base.Test, Compat
ts = "2016-03-23T23:10:00"
te = "2016-03-23T23:17:00"

println("...IRISws...")
S = irisws("CC.JRO..BHZ", s=ts, t=te, fmt="sacbl")
T = irisws("CC.JRO..BHZ", s=ts, t=te, fmt="miniseed")
@assert(isempty(S)==false)
@assert(isempty(T)==false)
sync!(S, s=ts, t=te)
sync!(T, s=ts, t=te)

@test_approx_eq(length(S.x[1]), length(T.x[1]))
@test_approx_eq(S.x[1], T.x[1])

println("...IRISget...")
chans = ["UW.TDH..EHZ", "UW.VLL..EHZ", "UW.HOOD..BHZ"]
st = 0.0
en = -60.0
(d0,d1) = parsetimewin(st,en)
U = IRISget(chans, s=d0, t=d1)
@assert(isempty(U)==false)
sync!(U)
L = [length(U.x[i])/U.fs[i] for i = 1:U.n]
t = [U.t[i][1,2] for i = 1:U.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@assert(L_max - L_min <= maximum(1./U.fs))
@assert(t_max - t_min <= maximum(1./U.fs))
