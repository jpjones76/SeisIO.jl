printstyled("  RandSeis utils\n", color=:light_green)


# This should do it
D = Dict{String,Any}()
for i = 1:10
  RandSeis.pop_rand_dict!(D, 1000)
end

# Similarly for the yp2 codes
for i = 1:100
  i,c,u = RandSeis.getyp2codes('s', true)
  @test isa(i, Char)
  @test isa(c, Char)
  @test isa(u, String)
end

for i = 1:10000
  i,c,u = RandSeis.getyp2codes('s', false)
  @test isa(i, Char)
  @test isa(c, Char)
  @test isa(u, String)
end

printstyled("  randSeis*\n", color=:light_green)
for i = 1:10
  randSeisChannel()
  randSeisData()
  randSeisHdr()
  randSeisEvent()
end

printstyled("    namestrip, namestrip!\n", color=:light_green)
str = String(0x00:0xff)
S = randSeisData(3)
S.name[2] = str

for key in keys(bad_chars)
  test_str = namestrip(str, key)
  @test length(test_str) == 256 - (32 + length(bad_chars[key]))
end
open("runtests.log", "a") do out
  redirect_stdout(out) do
    test_str = namestrip(str, "Nonexistent List")
  end
end
namestrip!(S)
@test length(S.name[2]) == 210
