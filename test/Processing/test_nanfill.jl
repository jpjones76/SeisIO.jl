printstyled("  nanfill\n", color=:light_green)
S = randSeisData()
L = length(S.x[1])
C = deepcopy(S[1])
Ev = SeisEvent(hdr=randSeisHdr(), data=deepcopy(S))

inds = rand(1:L, div(L,2))
S.x[1][inds] .= NaN

inds = rand(1:L, div(L,2))
Ev.data.x[1][inds] .= NaN

inds = rand(1:L, div(L,2))
C.x[inds] .= NaN

nanfill!(Ev)
nanfill!(S)
nanfill!(C)

Ev2 = ungap(Ev, tap=true)
ungap!(Ev, tap=true)
for f in SeisIO.datafields
  if f != :notes
    @test getfield(Ev.data,f) == getfield(Ev2.data,f)
  end
end
ungap!(C, tap=true)
ungap!(S, tap=true)

demean!(C)
detrend!(C)
demean!(Ev)
detrend!(Ev)
