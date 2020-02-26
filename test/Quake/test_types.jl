printstyled("  convert\n", color=:light_green)
C = randSeisChannel()
C1 = convert(EventChannel, C)
TD = convert(EventTraceData, C1)
@test sizeof(TD) > 136

C2 = convert(SeisChannel, C)
@test C == C2

EC = convert(EventChannel, randSeisChannel())

TD = unsafe_convert(EventTraceData, randSeisData(10))
for f in datafields
  @test length(getfield(TD, f)) == 10
end

S = unsafe_convert(SeisData, randSeisEvent(10).data)
for f in datafields
  @test length(getfield(S, f)) == 10
end

printstyled("  show\n", color=:light_green)
redirect_stdout(out) do
  for i = 1:10
    for T in (SeisHdr, SeisSrc, SeisEvent, EventTraceData, EventChannel, EQMag, EQLoc, SourceTime)
      repr(T(), context=:compact=>true)
      repr(T(), context=:compact=>false)
      show(T())
    end
    summary(randSeisEvent())
    summary(randSeisHdr())
    summary(randSeisSrc())
    show(randSeisEvent())
    show(randSeisHdr())
    show(randSeisSrc())
  end
end

# EQMag
Δ = 75.3
m1 = EQMag(3.2f0, "Ml", 23, Δ, "localmag")
m2 = EQMag(3.2f0, "Ml", 23, Δ, "localmag")
@test hash(m1) == hash(m2)

# SourceTime
@test isempty(SourceTime())
ST1 = SourceTime()
@test hash(ST1) == hash(SourceTime())

# SeisSrc
@test isempty(SeisSrc())
@test isempty(SeisSrc(m0=1.0e22)) == false
@test isempty(SeisSrc(id = "123")) == false
