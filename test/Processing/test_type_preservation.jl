# resp
printstyled("  Type preservation after processing\n", color=:light_green)

for f in String["convert_seis!", "demean!", "detrend!", "filtfilt!", "merge!", "sync!", "taper!", "ungap!", "unscale!"]
  printstyled(string("    ", f, "\n"), color=:light_green)
  S = randSeisData(s=1.0, fs_min=30.0)
  T = [eltype(S.x[i]) for i=1:S.n]
  id = deepcopy(S.id)
  ns = [length(findall(isnan.(S.x[i]))) for i in 1:S.n]
  getfield(SeisIO, Symbol(f))(S)
  for i = 1:S.n
    j = findid(S.id[i], id)
    if j > 0
      @test T[j] == eltype(S.x[i])
      nn = length(findall(isnan.(S.x[j])))
      if ns[j] == 0 && nn > 0
        str = string("channel = ", i, " output ", nn, " NaNs; input had none!")
        @warn(str)    # goes to warning buffer
        println(str)  # replicate warning to STDOUT
      end
    else
      str = string("id = ", id, " deleted from S; check randSeisChannel time ranges.")
      @warn(str)
      println(str)
    end
  end
end

printstyled(string("    remove_resp!\n"), color=:light_green)
r = fctoresp(1.0, 1.0/sqrt(2.0))
r2 = fctoresp(0.0333, 1.0/sqrt(2.0))
S = randSeisData(3, s=1.0)
S.resp[1] = r
S.resp[2] = deepcopy(r)
S.resp[3] = r2
S.x[1] = randn(Float32, S.t[1][end,1])
T = [eltype(S.x[i]) for i=1:S.n]
remove_resp!(S)
for i=1:S.n
  @test T[i] == eltype(S.x[i])
end
