# Locs
printstyled("  InstrumentPosition\n", color=:light_green)
redirect_stdout(out) do
  L = GenLoc{Float32}(); show(stdout, L)
  @test isempty(L) == true
  @test hash(L) == hash(GenLoc{Float32}())

  L = GenLoc(rand(Float64,12))
  @test getindex(L, 10) == getindex(L.loc, 10)
  setindex!(L, 1.0, 10)
  @test getindex(L.loc, 10) == 1.0
  @test isempty(L) == false
  @test sizeof(L) > sizeof(L.loc)

  L1 = GeoLoc(datum="WGS84")
  L2 = GeoLoc(datum="Unknown")
  show(stdout, L1)
  @test !(L1 == L2)
  @test sizeof(L1) > 104

  L = UTMLoc()
  show(stdout, L)
  @test isempty(L)
  @test hash(L) == hash(UTMLoc())
  @test L == UTMLoc()
  sizeof(L) > 114

  L = XYLoc()
  show(stdout, L)
  @test isempty(L)
  @test hash(L) == hash(XYLoc())
  L.x = 10.0
  L.datum = "Ye olde map of 1833"
  @test !isempty(L)
  @test !(L == UTMLoc())
  @test sizeof(L) > 136

  L = EQLoc()
  show(stdout, L)
  @test isempty(L)
  @test hash(L) == hash(EQLoc())
  @test L == EQLoc()
  sizeof(L) > 114
end

# Responses
printstyled("  InstrumentResponse\n", color=:light_green)
redirect_stdout(out) do
  @test isempty(GenResp())

  v = 1.0 + 1.0*im
  X = rand(12,3)
  Y = rand(12,3)
  R = GenResp("", X, Y)
  @test R == GenResp(complex.(X,Y))
  @test hash(R) == hash(GenResp(complex.(X,Y)))
  @test sizeof(R) > sizeof(X)+sizeof(Y)
  @test R[10] == getindex(R.resp, 10) == getindex(R, 10)
  @test R[11,2] == getindex(R.resp, 11, 2) == getindex(R, 11, 2)
  R[3] = v
  R[4,2] = 1.0
  @test getindex(R.resp, 3) == v == getindex(R, 3, 1)
  @test real(getindex(R.resp, 4, 2)) == 1.0

  show(stdout, R)
  repr(R, context=:compact=>true)
end

# Seismic phases
printstyled("  SeisPha\n", color=:light_green)
@test isempty(SeisPha())

printstyled("  PhaseCat\n", color=:light_green)
@test isempty(PhaseCat())

# Seismic phase catalogs
@test isempty(PhaseCat())
P = PhaseCat()
@test isequal(PhaseCat(), P)

# disk i/o
wrote_Pha = randPhaseCat()
open("phasecat.txt", "w") do fio
  write(fio, wrote_Pha)
end
fio = open("phasecat.txt", "r")
read_Pha = read(fio, PhaseCat)
close(fio)
@test read_Pha == wrote_Pha
rm("phasecat.txt")

# EventChannel, EventTraceData
printstyled("  EventChannel, EventTraceData\n", color=:light_green)
EC1 = EventChannel()
@test isempty(EC1)

TD = EventTraceData()
@test isempty(TD)

@test EventTraceData(EC1) == EventTraceData(EventChannel())

TD1 = convert(EventTraceData, randSeisData())
TD2 = convert(EventTraceData, randSeisData())

EC1 = TD1[1]
EC1.id = "CC.VALT..BHZ"
TD1.id[2] = "CC.VALT..BHZ"
@test !isempty(EC1)

EC2 = EventChannel( az = 180*rand(),
                    baz = 180*rand(),
                    dist = 360*rand(),
                    fs = 10.0*rand(1:10),
                    gain = 10.0^rand(1:10),
                    id = "YY.MONGO..FOO",
                    loc = UTMLoc(),
                    misc = Dict{String,Any}("Dont" => "Science While Drink"),
                    name = "<I Made This>",
                    notes = Array{String,1}([tnote("It clipped"), tnote("It clipped again")]),
                    pha = PhaseCat("P" => SeisPha(),
                                   "S" => SeisPha(rand()*100.0,
                                                  rand()*100.0,
                                                  rand()*100.0,
                                                  rand()*100.0,
                                                  rand()*100.0,
                                                  'D')),
                    resp = GenResp(),
                    src = "foo",
                    t = Array{Int64,2}([1 1000; 2*length(EC1.x) 0]),
                    units = "m/s",
                    x = randn(2*length(EC1.x))
                  )

@test findid(EC1, TD1) == 2 == findid(TD1, EC1)
@test findid(TD2, EC1) == 0 == findid(EC1, TD2)
@test sizeof(TD1) > sizeof(EC1) > 136
@test sizeof(TD2) > sizeof(EC1) > 136

# Cross-Type Tests
C = randSeisChannel()
C.id = identity(EC1.id)
@test findid(C, TD1) == 2 == findid(TD1, C)
@test findid(TD2, C) == 0 == findid(C, TD2)

S1 = randSeisData(12)
S2 = randSeisData(12)
S1.id[11] = "CC.VALT..BHZ"
@test findid(EC1, S1) == 11 == findid(S1, EC1)
@test findid(S2, EC1) == findid(EC1, S2)

TD = EventTraceData(EC2, convert(EventTraceData, randSeisData()))
EC3 = pull(TD, 1)
@test findid(EC3, TD) == 0

setindex!(TD, EC3, 2)
@test findid(EC3, TD) == 2
namestrip!(EC3)
@test EC3.name == "I Made This"

Ev = SeisEvent(hdr=randSeisHdr(), data=TD)
@test sizeof(Ev) > 16

# SeisHdr
@test isempty(SeisHdr())
