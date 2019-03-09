C = randSeisChannel()
autotap!(C)

printstyled("  resp\n", color=:light_green)
S = randSeisData()
r = fctopz(0.2, hc=1.0/sqrt(2.0))
@test_throws ErrorException fctopz(0.2, units="m/s^2")
T = equalize_resp(S, r)
equalize_resp!(S, r) # doesnt work
@test S==T

# does this work?
# Ensure one segment is short enough to invoke bad behavior in ungap
Ev = randSeisEvent()
Ev.data.fs[1] = 100.0
Ev.data.x[1] = rand(1024)
Ev.data.t[1] = vcat(Ev.data.t[1][1:1,:], [5 2*ceil(S.fs[1])*SeisIO.sμ], [8 2*ceil(S.fs[1])*SeisIO.sμ], [1024 0])
open("show.log", "a") do out
  redirect_stdout(out) do
    ungap!(Ev)
  end
end
