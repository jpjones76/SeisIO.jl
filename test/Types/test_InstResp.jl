# Responses
printstyled("  T <: InstrumentResponse\n", color=:light_green)
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
end

printstyled("    resp codes\n", color=:light_green)
for c in (0x00, 0x01, 0x02, 0x03, 0x04, 0xff)
  T = code2resptyp(c)()
  @test c == resptyp2code(T)
end
