C = randSeisChannel()
autotap!(C)

printstyled("  resp.jl...\n", color=:light_green)
S = randSeisData()
r = fctopz(0.2, hc=1.0/sqrt(2.0))
equalize_resp!(S, r) # doesnt work
