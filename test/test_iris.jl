ts = "2016-03-23T23:10:00"
te = "2016-03-23T23:17:00"

println("...IRISWS...")
println("...equivalence of SAC and MSEED requests...")
S = get_data("IRIS", "CC.JRO..BHZ", src="IRIS", s=ts, t=te, fmt="sacbl", v=0)
@test(isempty(S)==false)
T = get_data("IRIS", "CC.JRO..BHZ", src="IRIS", s=ts, t=te, fmt="miniseed", v=0)
@test(isempty(T)==false)
sync!(S, s=ts, t=te)
sync!(T, s=ts, t=te)

@test ≈(length(S.x[1]), length(T.x[1]))
@test ≈(S.x[1], T.x[1])

println("...a more complex IRISWS request...")
chans = ["UW.TDH..EHZ", "UW.VLL..EHZ"] # HOOD is either offline or not on IRISws right now
st = -86400.0
en = -86100.0
(d0,d1) = parsetimewin(st,en)
U = get_data("IRIS", chans, s=d0, t=d1)
@test(isempty(U)==false)
sync!(U)
L = [length(U.x[i])/U.fs[i] for i = 1:U.n]
t = [U.t[i][1,2] for i = 1:U.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test(L_max - L_min <= maximum(2 ./ U.fs))
@test(t_max - t_min <= round(Int64, 1.0e6 * 2.0/maximum(U.fs)))

# println("To test for faithful SAC write in SeisIO:")
# println("   (1) At the Julia prompt, repeat this test: `U = get_data(\"IRIS\", [\"UW.TDH..EHZ\", \"UW.VLL..EHZ\"], \"IRIS\", s=-86400.0, t=-86100.0)`")
# println("   (1) Type `wsac(U)` at the Julia prompt.")
# println("   (2) Open a terminal, change to the current directory, and start SAC.")
# println("   (4) type `r *TDH*SAC *VLL*SAC; qdp off; plot1; lh default`.")
# println(    (5) Report any irregularities.")
