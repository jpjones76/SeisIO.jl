printstyled("  resp\n", color=:light_green)
C = randSeisChannel()
taper!(C)

T = Float64
fs = 100.0
Nx = 128
Nz = 2
Np = 12
f = T.([collect(0.0:1.0:Nx/2.0); collect(-Nx/2.0+1.0:1.0:-1.0)]*fs/Nx)
z = zeros(Complex{T}, Nz)
p = zeros(Complex{T}, Np)
g = one(T)
h = one(T)
rr = resp_f(z, p, g, h, f, fs)
@test length(z) == Nz
@test length(p) == Np

printstyled("    fctopz\n", color=:light_green)
p1, z1 = fctopz(0.2f0, 1.0f0/sqrt(2.0f0)); r = PZResp(1.0f0, p1, z1)
p2, z2 = fctopz(2.0f0, 1.0f0); r2 = PZResp(1.0f0, p2, z2)
S = randSeisData(3, s=1.0)
S.resp[1] = r
S.resp[2] = r
S.resp[3] = r2
S.x[1] = randn(Float32, S.t[1][end,1])

printstyled("    equalize_resp (SeisData)\n", color=:light_green)
T = equalize_resp(S, r)
@test typeof(T.x[1]) == Array{Float32,1}
equalize_resp!(S, r) # doesnt work?
@test S==T

# SeisEvent method extension
printstyled("    equalize_resp (SeisEvent)\n", color=:light_green)
V = randSeisEvent()
for i = 1:V.data.n
  V.data.resp[i] = r
end
W = equalize_resp(V, r2)
equalize_resp!(V, r2)
@test V == W
for i = 1:V.data.n
  @test V.data.x[i] != zeros(eltype(V.data.x[i]), lastindex(V.data.x[i]))
end

# SeisChannel method extension
printstyled("    equalize_resp (SeisChannel)\n", color=:light_green)
C = randSeisChannel()
C.resp = r2
D = equalize_resp(C, r)
equalize_resp!(C, r)
@test C == D
@test C.x != zeros(eltype(C.x), lastindex(C.x))
