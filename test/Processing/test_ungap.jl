printstyled("  ungap\n", color=:light_green)

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
