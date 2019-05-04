printstyled("  resp\n", color=:light_green)
C = randSeisChannel()
taper!(C)

r = fctopz(0.2, hc=1.0/sqrt(2.0))
@test_throws ErrorException fctopz(0.2, units="m/s^2")

S = randSeisData(3, s=1.0)
S.resp[1] = r
S.resp[2] = r
S.resp[3] = fctopz(2.0, hc=1.0)
S.x[1] = randn(Float32, S.t[1][end,1])
T = equalize_resp(S, r)
@test typeof(T.x[1]) == Array{Float32,1}
equalize_resp!(S, r) # doesnt work
@test S==T

# Method extensions
V = randSeisEvent()
W = equalize_resp(V, r)
equalize_resp!(V, r)
@test V == W

C = randSeisChannel()
D = equalize_resp(C, r)
equalize_resp!(C, r)
@test C == D
