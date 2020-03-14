printstyled("RandSeis\n", color=:light_green)

fs_range = exp10.(range(-6, stop=4, length=50))
fc_range = exp10.(range(-4, stop=2, length=20))

printstyled("  getbandcode\n", color=:light_green)
for fs in fs_range
  for fc in fc_range
    getbandcode(fs, fc=fc)
  end
end

printstyled("  rand_misc\n", color=:light_green)
for i = 1:100
  D = rand_misc(1000)
end

# Similarly for the yp2 codes
printstyled("  iccodes_and_units\n", color=:light_green)
for i = 1:1000
  cha, u = RandSeis.iccodes_and_units('s', true)
  @test isa(cha, String)
  @test isa(u, String)

  cha, u = RandSeis.iccodes_and_units('s', false)
  @test isa(cha, String)
  @test isa(u, String)
end

# check that rand_t produces sane gaps
printstyled("  rand_t\n", color=:light_green)
fs = 100.0
nx = 100

printstyled("    controlled gaps\n", color=:light_green)
t = RandSeis.rand_t(fs, nx, 10, 1)
@test size(t, 1) == 12
t = RandSeis.rand_t(fs, nx, 0, 1)
@test size(t, 1) == 2
t = RandSeis.rand_t(100.0, 1000, 4, 200)
@test size(t, 1) == 6
@test t[:,1] == [1, 200, 400, 600, 800, 1000]

printstyled("    gap < Δ/2 + 1\n", color=:light_green)
for i in 1:1000
  fs = rand(RandSeis.fs_vals)
  nx = round(Int64, rand(1200:7200)*fs)
  t = RandSeis.rand_t(fs, nx, 0, 1)
  δt = div(round(Int64, sμ/fs), 2) + 1
  gaps = t[2:end-1, 2]

  if length(gaps) > 0
    @test minimum(gaps) ≥ δt
  end
  @test minimum(diff(t[:,1])) > 0
end

printstyled("  rand_resp\n", color=:light_green)
R = RandSeis.rand_resp(1.0, 8)
@test length(R.z) == length(R.p) == 8

printstyled("  namestrip\n", color=:light_green)
str = String(0x00:0xff)
S = randSeisData(3)
S.name[2] = str

for key in keys(bad_chars)
  test_str = namestrip(str, key)
  @test length(test_str) == 256 - (32 + length(bad_chars[key]))
end
redirect_stdout(out) do
  test_str = namestrip(str, "Nonexistent List")
end
namestrip!(S)
@test length(S.name[2]) == 210

printstyled("  repop_id!\n", color=:light_green)
S = randSeisData()
S.id[end] = deepcopy(S.id[1])
id = deepcopy(S.id)
RandSeis.repop_id!(S)
@test id != S.id

printstyled("  randSeis*\n", color=:light_green)
for i = 1:10
  randSeisChannel()
  randSeisData()
  randSeisHdr()
  randSeisSrc()
  randSeisEvent()
end

printstyled("    keywords\n", color=:light_green)
printstyled("      a0\n", color=:light_green)
try
  randSeisData(a0=true)
catch err
  println("a0 = true threw error ", err)
end

printstyled("      c\n", color=:light_green)
for i = 1:10
  S = randSeisData(10, c=1.0)
  @test maximum(S.fs) == 0.0
end

printstyled("      fc\n", color=:light_green)
C = randSeisChannel(fc = 2.0)
resp_a0!(C.resp)
r1 = fctoresp(2.0f0, 1.0f0)
r2 = fctoresp(2.0f0, Float32(1.0/sqrt(2)))
resp_a0!(r1)
resp_a0!(r2)
r = C.resp
for f in (:a0, :f0, :z, :p)
  @test isapprox(getfield(r, f), getfield(r1, f), rtol=eps(Float32)) || isapprox(getfield(r, f), getfield(r2, f), rtol=eps(Float32))
end

printstyled("      s\n", color=:light_green)
for i = 1:10
  S = randSeisData(10, s=1.0)
  @test maximum(S.fs) > 0.0
end
