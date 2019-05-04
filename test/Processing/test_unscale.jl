printstyled("  unscale\n", color=:light_green)

# Test in-place unscaling
C = randSeisChannel(s=true)
S = randSeisData()
V = randSeisEvent()
unscale!(C)
unscale!(S, irr=true)
unscale!(V, irr=true)

# Test for out-of-place unscaling
C = randSeisChannel()
S = randSeisData()
V = randSeisEvent()
D = unscale(C)
T = unscale(S)
W = unscale(V)
