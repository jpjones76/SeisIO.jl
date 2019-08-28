bstr = [path * "/SampleFiles/Bottle/B024*",
        path * "/SampleFiles/Bottle/B2021901700*",
        path * "/SampleFiles/Bottle/B203*",
        path * "/SampleFiles/Bottle/B20319115Rainfallmm"]

printstyled("  Bottle (UNAVCO strain data)\n", color=:light_green)
for i = 1:4
  S = read_data("bottle", bstr[i], nx_new=14400, nx_add=14400)
  fill_pbo!(S)
  if i == 4
    @test S.name[1] == "quarry203bwa2007"
    @test isapprox(S.fs[1], 1.0/(30*60))
    @test isapprox(S.loc[1].el, 814.4)
    @test S.units[1] == "mm"
  end
end

redirect_stdout(out) do
  S = SeisIO.read_bottle(bstr[4], 0, 14400, 14400)
end
