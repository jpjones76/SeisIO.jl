uw_root = string(path, "/SampleFiles/99062109485W")


printstyled("  UW...\n", color=:light_green)
W = readuw(uw_root)

printstyled("    headers...\n", color=:light_green)
for i in ["UW.WWVB..TIM","UW.TCG..TIM","UW.SSO..EHZ","UW.VLM..EHZ"]
  @test !isempty(findall(W.data.id.==i))
  @test !isempty(findall(W.data.name.==i))
  n = findfirst(W.data.id.==i)
  @test ≈(W.data.fs[n], 100.0)
end

printstyled("    picks...\n", color=:light_green)
i = findfirst(W.data.id.=="UW.TDH..EHZ")
@test ≈(W.data.misc[i]["t_p"][1], 67.183)
i = findfirst(W.data.id.=="UW.VFP..EHZ")
@test ≈(W.data.misc[i]["t_d"][1], 19.0)

S += W.data
