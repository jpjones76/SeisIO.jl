segy_file = "SampleFiles/02.050.02.01.34.0572.6"
lenn_file = "SampleFiles/0215162000.c00"
uw_root = "SampleFiles/99062109485W"
sac_file = "SampleFiles/test.sac"

println("SEGY...")
SEG = readsegy(segy_file, nmt=true, fast=false)
println("...header accuracy...")
@test_approx_eq(1/SEG.gain, 1.9073486328125e-6)
@test_approx_eq(SEG.misc["year"], 2002)
@test_approx_eq(SEG.misc["day"], 50)
@test_approx_eq(SEG.misc["hour"], 2)
@test_approx_eq(SEG.misc["min"], 1)
@test_approx_eq(SEG.misc["sec"], 34)
@test_approx_eq(SEG.fs, 100.0)
println("...data accuracy...")
@test_approx_eq(SEG.x[1:10], [-1217,-1248,-1252,-1258,-1251,-1243,-1204,-1178,-1188,-1157])

println("Lennartz ASCII...")
A = rlennasc(lenn_file)
@test_approx_eq(contains(A.src,"rlennasc"),true)
@test_approx_eq(A.fs, 62.5)
S += A

println("UW...")
W = readuw(uw_root)
println("...header accuracy...")
for i in ["UW.WWVB..TIM","UW.TCG..TIM","UW.SSO..EHZ","UW.VLM..EHZ"]
  @test_approx_eq(isempty(find(W.data.id.==i)), false)
  @test_approx_eq(isempty(find(W.data.name.==i)), false)
  n = findfirst(W.data.id.==i)
  @test_approx_eq(W.data.fs[n],100.0)
end
println("...pick accuracy...")
i = findfirst(W.data.id.=="UW.TDH..EHZ")
@test_approx_eq(W.data.misc[i]["t_p"][1], 67.183)
i = findfirst(W.data.id.=="UW.VFP..EHZ")
@test_approx_eq(W.data.misc[i]["t_d"][1], 19.0)

println("...done!")
