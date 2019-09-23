# Responses
printstyled("  InstrumentResponse subtypes\n", color=:light_green)
redirect_stdout(out) do
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

  for T in (CoeffResp, GenResp, MultiStageResp, PZResp, PZResp64)
    R = T()
    @test isempty(R) == true
    show(stdout, R)
    repr(R, context=:compact=>true)
    repr(R, context=:compact=>false)

    R2 = T()
    @test R == R2
    @test hash(R) == hash(R2)
    @test code2resptyp(resptyp2code(R)) == T
    @test sizeof(R) == sizeof(R2)
  end

  nr = 255
  R = MultiStageResp(nr)
  for f in (:fs, :gain, :fg, :delay, :corr, :fac, :os)
    setfield!(R, f, rand(eltype(getfield(R, f)), nr))
  end
  i = Array{String,1}(undef,nr)
  o = Array{String,1}(undef,nr)
  o[1] = "m/s"
  i[1] = "{counts}"
  for j = 2:nr
    i[j] = randstring(2^rand(2:6))
    o[j] = i[j-1]
  end
  R.i = i
  R.o = o
  R.stage[1] = RandSeis.randResp()
  for i = 2:nr
    R.stage[i] = CoeffResp(b = rand(rand(1:1200)))
  end
  show(R)
end

printstyled("    resp codes\n", color=:light_green)
codes = (0x00, 0x01, 0x02, 0x03, 0x04, 0xff)
types = (GenResp, PZResp, PZResp64, CoeffResp, MultiStageResp, Nothing)
for c in codes
  T = code2resptyp(c)()
  @test c == resptyp2code(T)
end
for (i, T) in enumerate(types)
  resp = T()
  @test resptyp2code(resp) == codes[i]
end
