import SeisIO: parse_charr, parse_chstr, parse_sl

# Seedlink with command-line stations
config_file = path*"/SampleFiles/seedlink.conf"
sta = ["CC.SEP", "UW.HDW"]
pat = ["?????.D"; "?????.D"]
trl = ".??.???.D"
sta_matrix = String.(reshape(split(sta[2],'.'), 1,2))

printstyled("SeedLink\n", color=:light_green, bold=true)
printstyled("  (test requires 5 minutes)\n", color=:green)

# has_stream
printstyled("  has_stream...\n", color=:light_green)
tf1 = has_stream(sta, u="rtserve.iris.washington.edu")[2]
tf2 = has_stream(sta, pat, u="rtserve.iris.washington.edu", d='.')[2]
tf3 = has_stream(join(sta, ','), u="rtserve.iris.washington.edu")[2]
tf4 = has_stream(sta_matrix, u="rtserve.iris.washington.edu")[1]
@test tf1 == tf2 == tf3 == tf4

# has_stream
printstyled("  has_sta...\n", color=:light_green)
tf1 = has_sta(sta[1], u="rtserve.iris.washington.edu")[1]
tf2 = has_sta(sta[1]*trl, u="rtserve.iris.washington.edu")[1]
tf3 = has_sta(sta, u="rtserve.iris.washington.edu")[1]
tf4 = has_sta(parse_charr(sta), u="rtserve.iris.washington.edu")[1]
@test tf1 == tf2 == tf3 == tf4

# DATA mode
printstyled("  SeedLink DATA mode...\n", color=:light_green)
T = SeisData()

printstyled("    ...link 1: command-line station list...\n", color=:light_green)
SeedLink!(T, sta, mode="DATA", refresh=13.1, kai=90.0)

printstyled("    ...link 2: station file...\n", color=:light_green)
printstyled("      (sleep 90.0 s)\n", color=:green)
open("show.log", "w") do out
  redirect_stdout(out) do
    SeedLink!(T, config_file, mode="DATA", refresh=9.9, v=3)

    sleep(60.0)
    for i = 1:length(T.c)
      close(T.c[i])
    end

    sleep(30.0)
  end
end
@test isempty(T)==false
sync!(T, s="first")

# SeedLink time mode (more complicated)
printstyled("  SeedLink TIME mode...\n", color=:light_green)

# To ensure precise timing, we'll pass d0 and d1 as strings
st = 0.0
en = 60.0
dt = en-st
(d0,d1) = parsetimewin(st,en)

S = SeisData()
SeedLink!(S, sta, mode="TIME", refresh=10.0, s=d0, t=d1, w=true)
printstyled("    ...first link initialized...\n", color=:light_green)

# Seedlink with a config file
SeedLink!(S, config_file, refresh=10.0, mode="TIME", s=d0, t=d1)
printstyled("    ...second link initialized...\n", color=:light_green)

# Seedlink with a config string
SeedLink!(S, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", refresh=10.0, s=d0, t=d1)
printstyled("    ...third link initialized...\n", color=:light_green)
printstyled(string("      (sleep ", dt + 30.0, " s)\n"), color=:green)

# This takes time
sleep(dt)
open("show.log", "w") do out
  redirect_stdout(out) do
    for i = 1:length(S.c)
        i == 3 && show(S)
        close(S.c[i])
    end
  end
end
@test isempty(S)==false

# Synchronize (the reason we used d0,d1 above)
sleep(30)
sync!(S, s="first", t="last")

printstyled("  SeedLink FETCH mode...\n", color=:light_green)

# To ensure precise timing, we'll pass d0 and d1 as strings
S = SeisData()
SeedLink!(S, config_file, refresh=10.0, mode="FETCH", s=d0, t=d1)
printstyled("    ...link initialized...\n", color=:light_green)
printstyled(string("      (sleep ", dt + 20.0, " s)\n"), color=:green)
sleep(dt)
close(S.c[1])
sleep(20)

# Attempting to produce errors
printstyled("  Checking that errors and warnings are written correctly...\n", color=:light_green)
S = SeisData()
pat = ["*****.X"]
@test_throws ErrorException SeedLink!(S, [sta[1]], pat)

pat = ["?????.D"]
@test_throws ErrorException SeedLink!(S, [replace(sta[1], "SEP" => "XOX")], pat)
