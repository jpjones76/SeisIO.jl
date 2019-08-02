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
