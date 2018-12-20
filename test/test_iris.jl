ts = "2016-03-23T23:10:00"
te = "2016-03-23T23:17:00"

println("...IRISws...")
S = irisws("CC.JRO..BHZ", s=ts, t=te, fmt="sacbl")
T = irisws("CC.JRO..BHZ", s=ts, t=te, fmt="miniseed")
@assert(isempty(S)==false)
@assert(isempty(T)==false)
sync!(S, s=ts, t=te)
sync!(T, s=ts, t=te)

@test ≈(length(S.x[1]), length(T.x[1]))
@test ≈(S.x[1], T.x[1])

println("...IRISget...")
#chans = ["UW.TDH..EHZ", "UW.VLL..EHZ", "UW.HOOD..BHZ"]
chans = ["UW.TDH..EHZ", "UW.VLL..EHZ"] # HOOD is either offline or not on IRISws right now
st = -86400.0
en = -86100.0
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
@assert(L_max - L_min <= maximum(2 ./ U.fs))
@assert(t_max - t_min <= round(Int64, 1.0e6 * 2.0/maximum(U.fs)))
