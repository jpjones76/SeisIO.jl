using SeisIO.UW
import SeisIO.UW: readuwevt, uwdf, uwdf!, uwpf, uwpf!

printstyled("  UW\n", color=:light_green)
uwf0 = joinpath(path, "SampleFiles/UW/00*W")
uwf1 = joinpath(path, "SampleFiles/UW/99011116541")
uwf2 = joinpath(path, "SampleFiles/UW/94100613522o")
uwf3 = joinpath(path, "SampleFiles/UW/02062915175o")
uwf4 = joinpath(path, "SampleFiles/UW/00012502123W")
uwf5 = joinpath(path, "SampleFiles/UW/02062915205o")

S = read_data("uw", uwf0)
S1 = SeisData()
uwdf!(S1, joinpath(path, "SampleFiles/UW/00012502123W"))
@test S == S1


printstyled("  readuwevt\n", color=:light_green)

# Can we read from pickfile only? datafile only?
printstyled("    read (pickfile, datafile) from pickfile name\n", color=:light_green)
W = readuwevt(uwf1*"o")

printstyled("    read (pickfile, datafile) from datafile name\n", color=:light_green)

redirect_stdout(out) do
  W = readuwevt(uwf1*"W", v=3)
end

for i in ["UW.WWVB..TIM","UW.TCG..TIM","UW.TDH..EHZ","UW.VLM..EHZ"]
  @test !isempty(findall(W.data.id.==i))
  n = findfirst(W.data.id.==i)
  @test ≈(W.data.fs[n], 100.0)
end

# Can we read from filename stub?
printstyled("    read (pickfile, datafile) from filename stub\n", color=:light_green)
W = readuwevt(uwf1)
@test W.hdr.mag.val == 3.0f0
@test occursin("99011116541o", W.hdr.src)
@test W.hdr.ot == DateTime("1999-01-11T16:54:11.96")

S = breaking_seis()
n = S.n
S += convert(SeisData, W.data)
@test S.n == n + W.data.n

δt = 1.0e-6*(rem(W.hdr.ot.instant.periods.value*1000 - SeisIO.dtconst, 60000000))

i = findfirst(W.data.id.=="UW.TDH..EHZ")
pha = W.data[i].pha["P"].tt
@test ≈(pha + δt, 14.506)

i = findfirst(W.data.id.=="UW.VLM..EHZ")
pha = W.data[i].pha["S"].tt
@test ≈(pha + δt, 24.236)

i = findfirst(W.data.id.=="UW.VFP..EHZ")
@test W.data.misc[i]["dur"] == 116.0

printstyled("    pickfile handling\n", color=:light_green)

# What about when there is no data file?
W = readuwevt(uwf2)
@test W.hdr.mag.val == 0.9f0
@test occursin("94100613522o", W.hdr.src)
@test W.hdr.ot == DateTime("1994-10-06T13:52:39.02")

W = readuwevt(uwf3)
@test W.hdr.id == "041568"

printstyled("    data file with a time correction structure\n", color=:light_green)
redirect_stdout(out) do
  W = readuwevt(uwf4, v=2)
end

printstyled("    pick file with nonnumeric error info\n", color=:light_green)
redirect_stdout(out) do
  W = readuwevt(uwf5, v=2)
end
