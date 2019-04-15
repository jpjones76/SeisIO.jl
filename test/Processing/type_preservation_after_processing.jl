# resp
printstyled("  Type preservation after processing\n", color=:light_green)

for f in String["demean!", "detrend!", "merge!", "sync!", "taper!", "ungap!", "unscale!"]
  printstyled(string("    ", f, "\n"), color=:light_green)
  S = randSeisData(s=1.0)
  T = [eltype(S.x[i]) for i=1:S.n]
  getfield(SeisIO, Symbol(f))(S)
  for i = 1:S.n
    @test T[i] == eltype(S.x[i])
  end
end

printstyled(string("    equalize_resp!\n"), color=:light_green)
r = fctopz(1.0, hc=1.0/sqrt(2.0))
S = randSeisData(3, s=1.0)
S.resp[1] = r
S.resp[2] = r
S.resp[3] = fctopz(0.0333, hc=1.0/sqrt(2))
S.x[1] = randn(Float32, S.t[1][end,1])
T = [eltype(S.x[i]) for i=1:S.n]
equalize_resp!(S, r)
for i=1:S.n
  @test T[i] == eltype(S.x[i])
end
