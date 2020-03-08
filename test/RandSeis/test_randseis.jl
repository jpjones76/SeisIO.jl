printstyled("RandSeis\n", color=:light_green)

fs_range = exp10.(range(-6, stop=4, length=50))
fc_range = exp10.(range(-4, stop=2, length=20))

printstyled("  getbandcode\n", color=:light_green)
for fs in fs_range
  for fc in fc_range
    getbandcode(fs, fc=fc)
  end
end

printstyled("  pop_rand_dict!\n", color=:light_green)
# This should do it
D = Dict{String,Any}()
for i = 1:10
  RandSeis.pop_rand_dict!(D, 1000)
end

# Similarly for the yp2 codes
printstyled("  getyp2codes\n", color=:light_green)
for i = 1:1000
  i,c,u = RandSeis.getyp2codes('s', true)
  @test isa(i, Char)
  @test isa(c, Char)
  @test isa(u, String)

  i,c,u = RandSeis.getyp2codes('s', false)
  @test isa(i, Char)
  @test isa(c, Char)
  @test isa(u, String)
end

# check that rand_t produces sane gaps
printstyled("  rand_t\n", color=:light_green)
fs = 100.0
nx = 100

printstyled("    controlled n_gaps\n", color=:light_green)
t = RandSeis.rand_t(fs, nx, 10)
@test size(t, 1) == 12
t = RandSeis.rand_t(fs, nx, 0)
@test size(t, 1) == 2

printstyled("    gap < Δ/2 + 1\n", color=:light_green)
for i in 1:1000
  fs = rand(RandSeis.fs_vals)
  nx = round(Int64, rand(1200:7200)*fs)
  t = RandSeis.rand_t(fs, nx, 0)
  δt = div(round(Int64, 1.0e6/fs), 2) + 1
  gaps = t[2:end-1, 2]

  if length(gaps) > 0
    @test minimum(gaps) ≥ δt
  end
  @test minimum(diff(t[:,1])) > 0
end

printstyled("  randResp\n", color=:light_green)
R = RandSeis.randResp(8)
@test length(R.z) == length(R.p) == 8

printstyled("  randSeis*\n", color=:light_green)
for i = 1:10
  randSeisChannel()
  randSeisData()
  randSeisHdr()
  randSeisSrc()
  randSeisEvent()
end

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
