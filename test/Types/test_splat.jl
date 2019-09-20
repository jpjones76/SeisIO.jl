printstyled("  \"splat\" structure creation\n", color=:light_green)
U = randSeisData()
C = randSeisChannel()
W = randSeisEvent()
TD = convert(EventTraceData, randSeisData())
EC = convert(EventChannel, randSeisChannel())

S = SeisData( U, C, EC, TD, W)
T = EventTraceData( U, C, EC, TD, W)

for f in datafields
  @test getfield(S, f) == getfield(T, f)
end
