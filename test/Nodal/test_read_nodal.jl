printstyled("  read_nodal\n", color=:light_green)

segy_nodal = string(path, "/SampleFiles/SEGY/FORGE_78-32_iDASv3-P11_UTC190428135038.sgy")

printstyled("    Nodal SEG Y\n", color=:light_green)
S = read_nodal("segy", segy_nodal)
@test S.n == 33
@test S.id[1] == "N0.00001..OG0"
@test S.id[2] == "N0.00002..OG0"
@test S.id[S.n] == "N0.00033..OG0"
@test isapprox(S.fs[1], 2000.0)
@test isapprox(S.fs[2], 2000.0)
@test isapprox(S.fs[S.n], 2000.0)
@test S.name[1] == "43249_1"
@test S.gain[1] != NaN
@test S.units[1] == "m/m"
@test S.t[1][1,2] == 1556458718000000

printstyled("      channel unit tests\n", color=:light_green)
redirect_stdout(out) do
  S = read_nodal("segy", segy_nodal, chans=2:10, v=3)
end

printstyled("        defaults\n", color=:light_green)
S1 = read_nodal("segy", segy_nodal)

printstyled("        start channel only\n", color=:light_green)
S = read_nodal("segy", segy_nodal, chans=2:33)
@test size(S.data) == (30000, 32)
@test S1.data[:, 2:end] == S.data

printstyled("        end channel only\n", color=:light_green)
S = read_nodal("segy", segy_nodal, chans=1:32)
@test size(S.data) == (30000, 32)
@test S1.data[:, 1:end-1] == S.data

printstyled("        only one channel\n", color=:light_green)
j = 31
S = read_nodal("segy", segy_nodal, chans=j)
@test size(S.data) == (30000, 1)
@test S1.data[:, j:j] == S.data
@test S1.name[j] == S.name[1]

printstyled("        start & end channel\n", color=:light_green)
S = read_nodal("segy", segy_nodal, chans=collect(11:30))
@test size(S.data) == (30000, 20)
@test S1.data[:, 11:30] == S.data

printstyled("    Silixa TDMS\n", color=:light_green)

# Base read, no modifiers
S1 = read_nodal("silixa", fstr)
@test isapprox(S1.data, XX)
@test_throws ErrorException read_nodal("foo", fstr)

# Start and end time unit tests
printstyled("      time & channel unit tests\n", color=:light_green)
redirect_stdout(out) do
  S = read_nodal("silixa", fstr, s=2.0, t=40.0, chans=2:10, v=3)
end

printstyled("        defaults\n", color=:light_green)
S1 = read_nodal("silixa", fstr)

printstyled("        start time only\n", color=:light_green)
S = read_nodal("silixa", fstr, s=1.0)
@test size(S.data) == (59000, 448)
@test S1.data[1001:end, :] == S.data

printstyled("        start index in chunk > 1\n", color=:light_green)
S = read_nodal("silixa", fstr, s=2.0)
@test size(S.data) == (58000, 448)
@test S1.data[2001:end, :] == S.data

printstyled("        end time only\n", color=:light_green)
S = read_nodal("silixa", fstr, t=59.0)
@test size(S.data) == (59000, 448)
@test S1.data[1:59000, :] == S.data

printstyled("          end index in chunk < last\n", color=:light_green)
S = read_nodal("silixa", fstr, t=59.0)
@test size(S.data) == (59000, 448)
@test S1.data[1:59000, :] == S.data

printstyled("        start & end time\n", color=:light_green)
S = read_nodal("silixa", fstr, s=1.0, t=59.0)
@test size(S.data) == (58000, 448)
@test S1.data[1001:59000, :] == S.data

printstyled("        start channel only\n", color=:light_green)
S = read_nodal("silixa", fstr, chans=2:448)
@test size(S.data) == (60000, 447)
@test S1.data[:, 2:end] == S.data

printstyled("        end channel only\n", color=:light_green)
S = read_nodal("silixa", fstr, chans=1:447)
@test size(S.data) == (60000, 447)
@test S1.data[:, 1:end-1] == S.data

printstyled("        only one channel\n", color=:light_green)
S = read_nodal("silixa", fstr, chans=23)
@test size(S.data) == (60000, 1)
@test S1.data[:, 23:23] == S.data
@test S1.name[23] == S.name[1]

printstyled("        start & end channel\n", color=:light_green)
S = read_nodal("silixa", fstr, chans=collect(101:200))
@test size(S.data) == (60000, 100)
@test S1.data[:, 101:200] == S.data

printstyled("        all four\n", color=:light_green)
S = read_nodal("silixa", fstr, s=2.0, t=40.0, chans=2:10)
@test size(S.data) == (38000, 9)
@test S1.data[2001:40000, 2:10] == S.data
