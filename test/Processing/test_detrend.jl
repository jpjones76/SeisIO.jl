import Statistics:mean
printstyled("  demean, detrend...\n", color=:light_green)

S = randSeisData(2, s=1.0)[2:2]
fs = 100.0
nx = 14400
t = floor(Int64, time()-60.0)*SeisIO.sμ

S.fs[1] = 100.0
S.t[1] = [1 t; nx 0]
x = (rand(nx) .- 0.5)
broadcast!(-, x, x, mean(x))
S.x[1] = x
S₀ = deepcopy(S)

# Test 1: de-mean
μ = 6.0
S.x[1] .+= μ
T = demean(S)

@test maximum(S.x[1] .- T.x[1]) ≤ 6.01
@test minimum(S.x[1] .- T.x[1]) ≥ 5.99
@test maximum(abs.(T.x[1]-S₀.x[1])) < 0.01
@test abs(mean(T)) < 0.01

# Test 2: de-trend
m = 0.01
demean!(S)
S.x[1] += (m.*(1.0:1.0:Float64(nx)))
U = detrend(S)
@test maximum(abs.(U.x[1]-S₀.x[1])) < 0.1
@test maximum(abs.(U.x[1]-T.x[1])) < 0.1
@test abs(mean(U.x[1])) < 1.0e-8
