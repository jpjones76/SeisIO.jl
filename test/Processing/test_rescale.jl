printstyled("  rescale\n", color=:light_green)
g = 32.0
g1 = 7.0
g2 = 11.0
segy_nodal = string(path, "/SampleFiles/SEGY/FORGE_78-32_iDASv3-P11_UTC190428135038.sgy")
U = read_data("segy", segy_nodal, ll=0x01)
@test U.n == 33
S = U[1:7]
fill!(S.gain, 1.0)
C = deepcopy(S[1])
U = deepcopy(S)
D = deepcopy(C)


printstyled("    rescale!(S)\n", color=:light_green)
S = deepcopy(U)
S.gain[1] = g1
S2 = rescale(S)
rescale!(S)
@test S == S2
G = S.gain
@test all([getindex(G, i) == g1 for i in 1:S.n])
for i in 2:S.n
  @test isapprox(S.x[i]/g1, U.x[i])
end

printstyled("    rescale!(S, g)\n", color=:light_green)
S = deepcopy(U)
S2 = rescale(S, g)
rescale!(S, g)
@test S == S2
G = S.gain
X = S.x
@test all([getindex(G, i) == g for i in 1:S.n])
@test all([isapprox(X[i], U.x[i].*g) for i in 1:S.n])

printstyled("      channel range\n", color=:light_green)
S = deepcopy(U)
chans = collect(2:2:6)
rest  = setdiff(1:S.n, chans)
S2 = rescale(S, g, chans=chans)
rescale!(S, g, chans=chans)
@test S == S2
G = S.gain
X = S.x
@test all([getindex(G, i) == g for i in chans])
@test any([getindex(G, i) == g for i in rest]) == false
@test all([isapprox(X[i], U.x[i].*g) for i in chans])
@test any([isapprox(X[i], U.x[i].*g) for i in rest]) == false

printstyled("    rescale!(S_targ, S_src)\n", color=:light_green)
S = deepcopy(U)
fill!(U.gain, g2)
S2 = rescale(S, U)
rescale!(S, U)
@test S == S2
G = S.gain
X = S.x
@test all([getindex(G, i) == g2 for i in 1:S.n])
@test all([isapprox(X[i], U.x[i].*g2) for i in 1:S.n])

printstyled("    rescale!(C, g)\n", color=:light_green)
B = rescale(C, g)
rescale!(C, g)
@test B == C
@test C.gain == g
@test isapprox((C.x).*g, D.x)

printstyled("    rescale!(C, D)\n", color=:light_green)
C = deepcopy(D)
D.gain = g2
B = rescale(C, D)
rescale!(C, D)
@test B == C
@test isapprox(C.x, (D.x).*g2)
@test eltype(C.x) == Float32
