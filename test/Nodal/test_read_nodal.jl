printstyled("  Silixa (TDMS variant)\n", color=:light_green)

# Base read, no modifiers
S1 = read_nodal(fstr)
@test isapprox(S1.data, XX)
@test_throws ErrorException read_nodal(fstr, fmt="foo")

# Start and end time unit tests
printstyled("    time & channel unit tests\n", color=:light_green)
redirect_stdout(out) do
  S = read_nodal(fstr, s=2.0, t=40.0, ch_s = 2, ch_e = 10, v=3)
end

printstyled("      defaults\n", color=:light_green)
S1 = read_nodal(fstr)

printstyled("      start time only\n", color=:light_green)
S = read_nodal(fstr, s=1.0)
@test size(S.data) == (59000, 448)
@test S1.data[1001:end, :] == S.data

printstyled("        start index in chunk > 1\n", color=:light_green)
S = read_nodal(fstr, s=2.0)
@test size(S.data) == (58000, 448)
@test S1.data[2001:end, :] == S.data

printstyled("      end time only\n", color=:light_green)
S = read_nodal(fstr, t=59.0)
@test size(S.data) == (59000, 448)
@test S1.data[1:59000, :] == S.data

printstyled("        end index in chunk < last\n", color=:light_green)
S = read_nodal(fstr, t=59.0)
@test size(S.data) == (59000, 448)
@test S1.data[1:59000, :] == S.data

printstyled("      start & end time\n", color=:light_green)
S = read_nodal(fstr, s=1.0, t=59.0)
@test size(S.data) == (58000, 448)
@test S1.data[1001:59000, :] == S.data

printstyled("      start channel only\n", color=:light_green)
S = read_nodal(fstr, ch_s = 2)
@test size(S.data) == (60000, 447)
@test S1.data[:, 2:end] == S.data

printstyled("      end channel only\n", color=:light_green)
S = read_nodal(fstr, ch_e = 447)
@test size(S.data) == (60000, 447)
@test S1.data[:, 1:end-1] == S.data

printstyled("      start & end channel\n", color=:light_green)
S = read_nodal(fstr, ch_s = 101, ch_e = 200)
@test size(S.data) == (60000, 100)
@test S1.data[:, 101:200] == S.data

printstyled("      all four\n", color=:light_green)
S = read_nodal(fstr, s=2.0, t=40.0, ch_s = 2, ch_e = 10)
@test size(S.data) == (38000, 9)
@test S1.data[2001:40000, 2:10] == S.data
