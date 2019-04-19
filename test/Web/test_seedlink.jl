import SeisIO: parse_charr, parse_chstr, parse_sl

# Seedlink with command-line stations
config_file = path*"/SampleFiles/seedlink.conf"
sta = ["CC.SEP", "UW.HDW"]
pat = ["?????.D"; "?????.D"]
trl = ".??.???.D"
sta_matrix = String.(reshape(split(sta[2],'.'), 1,2))

printstyled("SeedLink\n", color=:light_green, bold=true)
printstyled("  (SeedLink tests require up to 10 minutes)\n", color=:green)

# has_stream
printstyled("  has_stream\n", color=:light_green)
tf1 = has_stream(sta, u="rtserve.iris.washington.edu")[2]
tf2 = has_stream(sta, pat, u="rtserve.iris.washington.edu", d='.')[2]
tf3 = has_stream(join(sta, ','), u="rtserve.iris.washington.edu")[2]
tf4 = has_stream(sta_matrix, u="rtserve.iris.washington.edu")[1]
@test tf1 == tf2 == tf3 == tf4

# has_stream
printstyled("  has_sta\n", color=:light_green)
tf1 = has_sta(sta[1], u="rtserve.iris.washington.edu")[1]
tf2 = has_sta(sta[1]*trl, u="rtserve.iris.washington.edu")[1]
tf3 = has_sta(sta, u="rtserve.iris.washington.edu")[1]
tf4 = has_sta(parse_charr(sta), u="rtserve.iris.washington.edu")[1]
@test tf1 == tf2 == tf3 == tf4

# Attempting to produce errors
printstyled("  Checking that errors and warnings are written correctly\n", color=:light_green)
S1 = SeisData()
open("runtests.log", "a") do out
  redirect_stdout(out) do
    @test_throws ErrorException SeedLink!(S1, [sta[1]], ["*****.X"])

    S2 = SeedLink([sta[1]], pat, x_on_err=false)
    write(S2.c[1], "BYE\r")
    close(S2.c[1])
    @test_throws ErrorException SeedLink!(S2, [replace(sta[1], "SEP" => "XOX")], ["?????.D"])

    S3 = SeedLink([replace(sta[1], "SEP" => "XOX")], ["*****.X"], x_on_err=false)
    write(S3.c[1], "BYE\r")
    close(S3.c[1])
  end
end

# DATA mode
printstyled("  SeedLink DATA mode\n", color=:light_green)
printstyled("    link 1: command-line station list\n", color=:light_green)
T = SeisData()
open("runtests.log", "a") do out
  redirect_stdout(out) do
    SeedLink!(T, sta, mode="DATA", refresh=9.9, kai=7.0, v=1)
  end
end

printstyled("    link 2: station file\n", color=:light_green)
open("runtests.log", "a") do out
  redirect_stdout(out) do
    SeedLink!(T, config_file, mode="DATA", refresh=13.3, v=3)
  end
end
wait_on_data!(T)

# FETCH mode (indistinguishable from DATA mode for most users)
printstyled("  SeedLink FETCH mode\n", color=:light_green)
V = SeedLink("GE.ISP..BH?.D", refresh=10.0, mode="FETCH", v=1)
printstyled("    link initialized\n", color=:light_green)
wait_on_data!(V, tmax=50.0)

# SeedLink time mode (more complicated)
printstyled("  SeedLink TIME mode\n", color=:light_green)

# To ensure precise timing, we'll pass d0 and d1 as strings
st = 0.0
en = 60.0
dt = en-st
(d0,d1) = parsetimewin(st,en)

U = SeisData()
SeedLink!(U, sta, mode="TIME", refresh=10.0, s=d0, t=d1, w=true)
printstyled("    first link initialized\n", color=:light_green)

# Seedlink with a config file
SeedLink!(U, config_file, refresh=10.0, mode="TIME", s=d0, t=d1)
printstyled("    second link initialized\n", color=:light_green)

# Seedlink with a config string
SeedLink!(U, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", refresh=10.0, s=d0, t=d1)
printstyled("    third link initialized\n", color=:light_green)
wait_on_data!(U)
