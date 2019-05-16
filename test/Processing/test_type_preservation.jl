# resp
printstyled("  Type preservation after processing\n", color=:light_green)

for f in String["demean!", "detrend!", "filtfilt!", "merge!", "sync!", "taper!", "ungap!", "unscale!"]
  printstyled(string("    ", f, "\n"), color=:light_green)
  S = randSeisData(s=1.0)
  if f == "filtfilt!"
    while true
      i = findall(S.fs .< 30.0)
      deleteat!(S, i)
      if S.n > 0
        break
      end
      S = randSeisData(s=1.0)
    end
  end
  T = [eltype(S.x[i]) for i=1:S.n]
  id = S.id
  getfield(SeisIO, Symbol(f))(S)
  for i = 1:S.n
    j = findfirst(id.==S.id[i])
    @test T[j] == eltype(S.x[i])
  end
end

printstyled(string("    equalize_resp!\n"), color=:light_green)
(p,z) = fctopz(1.0, 1.0/sqrt(2.0)); r = PZResp64(1.0, p, z)
(p, z) = fctopz(0.0333, 1.0/sqrt(2.0)); r2 = PZResp64(1.0, p, z)
S = randSeisData(3, s=1.0)
S.resp[1] = r
S.resp[2] = r
S.resp[3] = r2
S.x[1] = randn(Float32, S.t[1][end,1])
T = [eltype(S.x[i]) for i=1:S.n]
equalize_resp!(S, r)
for i=1:S.n
  @test T[i] == eltype(S.x[i])
end
