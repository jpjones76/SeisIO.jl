# Seedlink with command-line stations
config_file = path*"/SampleFiles/seedlink.conf"
st = 0.0
en = 60.0
seq = "500000"
sta = ["CC.SEP", "UW.HDW"]
pat = ["?????.D", "?????.D"]
trl = ".??.???.D"
sta_matrix = String.(reshape(split(sta[2],'.'), 1,2))

printstyled("  SeedLink\n", color=:light_green)
printstyled("  (SeedLink tests require up to 6 minutes)\n", color=:green)

# has_stream
printstyled("    has_stream\n", color=:light_green)
ta = Array{Union{Task,Nothing}, 1}(undef, 4)
ta[1] = @async has_stream(sta)[2]
ta[2] = @async has_stream(sta, pat, d='.')[2]
ta[3] = @async has_stream(join(sta, ','))[2]
ta[4] = @async has_stream(sta_matrix)[1]
SL_wait(ta, 1)

# has_stream
printstyled("    has_sta\n", color=:light_green)
ta[1] = @async has_sta(sta[1])[1]
ta[2] = @async has_sta(sta[1]*trl)[1]
ta[3] = @async has_sta(sta)[1]
ta[4] = @async has_sta(parse_charr(sta, '.', false))[1]
SL_wait(ta, 1)

# Attempting to produce errors
printstyled("    produce expected errors and warnings\n", color=:light_green)
redirect_stdout(out) do
  S1 = SeisData()

  @test_throws ErrorException seedlink!(S1, "DATA", [sta[1]], ["*****.X"])

  S2 = seedlink("DATA", [sta[1]], pat, x_on_err=false)
  write(S2.c[1], "BYE\r")
  close(S2.c[1])
  @test_throws ErrorException seedlink!(S2, "DATA", [replace(sta[1], "SEP" => "XOX")], ["?????.D"])

  S3 = seedlink("DATA", [replace(sta[1], "SEP" => "XOX")], ["*****.X"], x_on_err=false)
  write(S3.c[1], "BYE\r")
  close(S3.c[1])

  S4 = seedlink("DATA", hcat(sta_matrix, "***", "***", "X"), x_on_err=false)
  write(S4.c[1], "BYE\r")
  close(S4.c[1])
end

# DATA mode
printstyled("    DATA mode\n", color=:light_green)
printstyled("      link 1: command-line station list\n", color=:light_green)
T = SeisData()
redirect_stdout(out) do
  seedlink!(T, "DATA", sta, refresh=9.9, kai=7.0, v=1)
end

printstyled("      link 2: station file\n", color=:light_green)
redirect_stdout(out) do
  seedlink!(T, "DATA", config_file, refresh=13.3, v=3)
end
wait_on_data!(T, 60.0)

# To ensure precise timing, we'll pass d0 and d1 as strings
dt = en-st
(d0,d1) = parsetimewin(st,en)


# FETCH mode (indistinguishable from DATA mode for most users)
printstyled("    FETCH mode with seq (should fail)\n", color=:light_green)
redirect_stdout(out) do
  V = seedlink("FETCH", refresh=10.0, config_file, seq=seq, s=now()-Hour(1), v=2)
  wait_on_data!(V, 30.0)
end

printstyled("    FETCH mode\n", color=:light_green)
V = seedlink("FETCH", refresh=10.0, config_file)
printstyled("      link initialized\n", color=:light_green)
wait_on_data!(V, 30.0)

# SeedLink time mode (more complicated)
printstyled("    TIME mode\n", color=:light_green)
U = SeisData()
seedlink!(U, "TIME", sta, refresh=10.0, s=d0, t=d1, w=true)
printstyled("      first link initialized\n", color=:light_green)

# Seedlink with a config file
seedlink!(U, "TIME", config_file, refresh=10.0, s=d0, t=d1)
printstyled("      second link initialized\n", color=:light_green)

# Seedlink with a config string
redirect_stdout(out) do
  seedlink!(U, "TIME", "CC.VALT..???, UW.ELK..EHZ", refresh=10.0, s=d0, t=d1, v=3)
end
printstyled("      third link initialized\n", color=:light_green)
wait_on_data!(U, 60.0)
