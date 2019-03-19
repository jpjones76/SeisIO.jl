C = randSeisChannel()
autotap!(C)

printstyled("  resp\n", color=:light_green)
r = fctopz(0.2, hc=1.0/sqrt(2.0))
@test_throws ErrorException fctopz(0.2, units="m/s^2")

S = randSeisData(3, s=1.0)
S.resp[1] = r
S.resp[2] = r
S.resp[3] = fctopz(2.0, hc=1.0)
T = equalize_resp(S, r)
equalize_resp!(S, r) # doesnt work
@test S==T

# does this work?
# Ensure one segment is short enough to invoke bad behavior in ungap
Ev = randSeisEvent()
Ev.data.fs[1] = 100.0
Ev.data.x[1] = rand(1024)
Ev.data.t[1] = vcat(Ev.data.t[1][1:1,:], [5 2*ceil(S.fs[1])*sμ], [8 2*ceil(S.fs[1])*sμ], [1024 0])
open("runtests.log", "a") do out
  redirect_stdout(out) do
    ungap!(Ev)
  end
end
