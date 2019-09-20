# Seedlink with command-line stations
config_file = path*"/SampleFiles/seedlink.conf"
sta = ["CC.SEP", "UW.HDW"]
pat = ["?????.D"; "?????.D"]
trl = ".??.???.D"
sta_matrix = String.(reshape(split(sta[2],'.'), 1,2))

function SL_wait(ta::Array{Union{Task,Nothing}, 1}, t_interval::Int64)
  t = 0
  while t < 300
    if any([!istaskdone(t) for t in ta])
      sleep(t_interval)
      t += t_interval
    elseif t ≥ 60
      println("      one or more queries incomplete after 60 s; skipping test.")
      for i = 1:4
        ta[i] = Nothing
        GC.gc()
      end
      break
    else
      tf1 = fetch(ta[1])
      tf2 = fetch(ta[2])
      tf3 = fetch(ta[3])
      tf4 = fetch(ta[4])
      @test tf1 == tf2 == tf3 == tf4
      break
    end
  end
  return nothing
end

printstyled("  SeedLink\n", color=:light_green, bold=true)
printstyled("  (SeedLink tests require 4-6 minutes)\n", color=:green)

# has_stream
printstyled("    has_stream\n", color=:light_green)
ta = Array{Union{Task,Nothing}, 1}(undef, 4)
ta[1] = @async has_stream(sta, u="rtserve.iris.washington.edu")[2]
ta[2] = @async has_stream(sta, pat, u="rtserve.iris.washington.edu", d='.')[2]
ta[3] = @async has_stream(join(sta, ','), u="rtserve.iris.washington.edu")[2]
ta[4] = @async has_stream(sta_matrix, u="rtserve.iris.washington.edu")[1]
SL_wait(ta, 1)

# has_stream
printstyled("    has_sta\n", color=:light_green)
ta[1] = @async has_sta(sta[1], u="rtserve.iris.washington.edu")[1]
ta[2] = @async has_sta(sta[1]*trl, u="rtserve.iris.washington.edu")[1]
ta[3] = @async has_sta(sta, u="rtserve.iris.washington.edu")[1]
ta[4] = @async has_sta(parse_charr(sta), u="rtserve.iris.washington.edu")[1]
SL_wait(ta, 1)

# Attempting to produce errors
printstyled("    produce expected errors and warnings\n", color=:light_green)
redirect_stdout(out) do
  S1 = SeisData()

  @test_throws ErrorException SeedLink!(S1, [sta[1]], ["*****.X"])

  S2 = SeedLink([sta[1]], pat, x_on_err=false)
  write(S2.c[1], "BYE\r")
  close(S2.c[1])
  @test_throws ErrorException SeedLink!(S2, [replace(sta[1], "SEP" => "XOX")], ["?????.D"])

  S3 = SeedLink([replace(sta[1], "SEP" => "XOX")], ["*****.X"], x_on_err=false)
  write(S3.c[1], "BYE\r")
  close(S3.c[1])
end

# DATA mode
printstyled("    DATA mode\n", color=:light_green)
printstyled("      link 1: command-line station list\n", color=:light_green)
T = SeisData()
redirect_stdout(out) do
  SeedLink!(T, sta, mode="DATA", refresh=9.9, kai=7.0, v=1)
end

printstyled("      link 2: station file\n", color=:light_green)
redirect_stdout(out) do
  SeedLink!(T, config_file, mode="DATA", refresh=13.3, v=3)
end
wait_on_data!(T, tmax=50.0)

# FETCH mode (indistinguishable from DATA mode for most users)
printstyled("    FETCH mode\n", color=:light_green)
V = SeedLink("GE.ISP..BH?.D", refresh=10.0, mode="FETCH", v=1)
printstyled("      link initialized\n", color=:light_green)
wait_on_data!(V, tmax=50.0)

# SeedLink time mode (more complicated)
printstyled("    TIME mode\n", color=:light_green)

# To ensure precise timing, we'll pass d0 and d1 as strings
st = 0.0
en = 60.0
dt = en-st
(d0,d1) = parsetimewin(st,en)

U = SeisData()
SeedLink!(U, sta, mode="TIME", refresh=10.0, s=d0, t=d1, w=true)
printstyled("      first link initialized\n", color=:light_green)

# Seedlink with a config file
SeedLink!(U, config_file, refresh=10.0, mode="TIME", s=d0, t=d1)
printstyled("      second link initialized\n", color=:light_green)

# Seedlink with a config string
redirect_stdout(out) do
  SeedLink!(U, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", refresh=10.0, kai=19.0, s=d0, t=d1, v=3)
end
printstyled("      third link initialized\n", color=:light_green)
wait_on_data!(U, tmax=50.0)
