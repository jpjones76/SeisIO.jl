printstyled("  poly\n", color=:light_green)
import SeisIO:polyfit, polyval
N = 1000
C = 2.0
P = 3
at = 1.0e-5

t = collect(1.0:1.0:Float64(N))
x = C.*t

pf = polyfit(t, x, 1)
@test isapprox(pf[1], C, atol=at)
@test isapprox(pf[2], 0.0, atol=at)

pf = polyfit(t, x, 3)
@test isapprox(pf[1], 0.0, atol=at)
@test isapprox(pf[2], 0.0, atol=at)
@test isapprox(pf[3], C, atol=at)
@test isapprox(pf[4], 0.0, atol=at)

pv = polyval(pf, t)
@test isapprox(pv, x)

y = t.^P
pf = polyfit(t, y, P)
@test isapprox(pf[1], 1.0, atol=at)
for i = 2:P+1
  @test isapprox(pf[i], 0.0, atol=at)
end

# this is the current response of CC.VALT..BHE as of 2014,079,00:00:00
resp = PZResp(a0 = 9.092142f11, f0 = 1.0f0,
  p = Complex{Float32}[-0.1486+0.1486im, -0.1486-0.1486im, -391.96+850.69im, -391.96-850.69im, -471.24+0.0im, -2199.1+0.0im],
  z = Complex{Float32}[0.0+0.0im, 0.0+0.0im])

# test: recover a0 from poles and zeroes in response file using above poly, polyval, polyfit functions
T = typeof(resp.a0)
Z = poly(resp.z)
P = poly(resp.p)
s = Complex{T}(2*pi*im*resp.f0)
a0 = one(T)/T(abs(polyval(Z, s)/polyval(P, s)))
@test isapprox(a0, resp.a0)

# test: adapted from Octave
r = Float64.(collect(0:10:50))
p = poly(r)
p ./= maximum(abs.(p))
x = Float64.(collect(0:5:50))
y = polyval(p,x) + 0.25*sin.(100.0*x)
y2 = similar(y)
for i = 1:length(y)
  y2[i] = polyval(p, x[i]) + 0.25*sin(100.0*x[i])
end
pf = polyfit(x, y, length(r))
y3 = polyval(pf, x)
y_expect = [0.00000, -1.34741,  0.20672,  0.16168,  0.23251, -0.45550,  0.05480,  0.47582, -0.17088, -0.99408, -0.24699]
y3_expect = [-0.021348, -1.234641, -0.027165,  0.412554,  0.035480, -0.273558, -0.034148,  0.358771,  0.031322, -1.105561, -0.225033]

@test isapprox(y, y_expect, atol=1.0e-5)
@test isapprox(y2, y_expect, atol=1.0e-5)
@test isapprox(y3, y3_expect, atol=1.0e-5)
