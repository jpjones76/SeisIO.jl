import SeisIO: getpf

uwf1 = joinpath(path, "SampleFiles/99011116541")
uwf2 = joinpath(path, "SampleFiles/94100613522o")
uwf3 = joinpath(path, "SampleFiles/02062915175o")

froot = splitdir(uwf1)[2]
@test getpf(froot*"xxx", collect(UInt8, 0x61:0x7a)) == froot*"xxx\0"

printstyled("  UW\n", color=:light_green)

printstyled("    data files\n", color=:light_green)

# Can we read from pickfile only? datafile only?
W = readuw(uwf1*"o")
W = readuw(uwf1*"W")
for i in ["UW.WWVB..TIM","UW.TCG..TIM","UW.TDH..EHZ","UW.VLM..EHZ"]
  @test !isempty(findall(W.data.id.==i))
  @test !isempty(findall(W.data.name.==i))
  n = findfirst(W.data.id.==i)
  @test ≈(W.data.fs[n], 100.0)
end

# Can we read from filename stub?
W = readuw(uwf1)
@test W.hdr.mag[1] == 3.0f0
@test occursin("99011116541o", W.hdr.src)
@test W.hdr.ot == DateTime("1999-01-11T16:54:11.96")

S = breaking_seis()
n = S.n
S += W.data
@test S.n == n + W.data.n

i = findfirst(W.data.id.=="UW.TDH..EHZ")
@test ≈(W.data.misc[i]["t_p"][1], 14.506)
i = findfirst(W.data.id.=="UW.VFP..EHZ")
@test ≈(W.data.misc[i]["t_d"][1], 116.0)
i = findfirst(W.data.id.=="UW.VLM..EHZ")
@test ≈(W.data.misc[i]["t_s"][1], 24.236)

printstyled("    pick files\n", color=:light_green)

# What about when there is no data file?
W = readuw(uwf2)
@test W.hdr.mag[1] == 0.9f0
@test occursin("94100613522o", W.hdr.src)
@test W.hdr.ot == DateTime("1994-10-06T13:52:39.02")

W = readuw(uwf3)
@test W.hdr.id == 41568
