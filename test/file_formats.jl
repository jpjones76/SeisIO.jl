segy_file = "SampleFiles/02.050.02.01.34.0572.6"
lenn_file = "SampleFiles/0215162000.c00"
uw_root = "SampleFiles/99062109485W"
sac_file = "SampleFiles/test.sac"

println("SEGY...")
SEG = r_segy(segy_file, f="nmt")
println("...header accuracy...")
@test_approx_eq(SEG["scale_fac"]/SEG["gainConst"], 1.90735e-06)
@test_approx_eq(SEG["nzyear"], 2002)
@test_approx_eq(SEG["nzjday"], 50)
@test_approx_eq(SEG["nzhour"], 2)
@test_approx_eq(SEG["nzmin"], 1)
@test_approx_eq(SEG["nzsec"], 34)
@test_approx_eq(SEG["nzmsec"], 913)
@test_approx_eq(SEG["sampDT"], 10000)
println("...data accuracy...")
@test_approx_eq(SEG["data"][1:10], [-1217,-1248,-1252,-1258,-1251,-1243,-1204,-1178,-1188,-1157])

println("Lennartz ASCII...")
A = rlennasc(lenn_file)
@test_approx_eq(A.src=="lennartz ascii",true)
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
