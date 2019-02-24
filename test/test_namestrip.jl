str = String(0x00:0xff)
S = randseisdata(3)
S.name[2] = str

for key in keys(SeisIO.bad_chars)
  println(key, ":"); test_str = namestrip(str, key)
  @test length(test_str) == 256 - (32 + length(SeisIO.bad_chars[key]))
end
namestrip!(S)
@test length(S.name[2]) == 200
