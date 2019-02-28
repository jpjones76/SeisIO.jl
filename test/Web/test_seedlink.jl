# Seedlink with command-line stations
sta = ["CC.SEP", "UW.HDW"]
config_file = path*"/SampleFiles/seedlink.conf"

printstyled("SeedLink\n", color=:light_green, bold=true)

# Checking
printstyled("  has_stream...\n", color=:light_green)
tf = has_stream(sta, u="rtserve.iris.washington.edu")

printstyled("  has_sta...\n", color=:light_green)
tf = has_sta(sta[1], u="rtserve.iris.washington.edu")

# SeedLink DATA mode (easier)
printstyled("  DATA mode...\n", color=:light_green)
T = SeisData()
printstyled("    ...link 1: command-line station list...\n", color=:light_green)
SeedLink!(T, sta, mode="DATA", refresh=11.1)
printstyled("    ...link 2: station file...\n", color=:light_green)
SeedLink!(T, config_file, mode="DATA", refresh=13.3)
printstyled("    ...sleep 60.0s while SeedLink session receives data...\n", color=:green)
sleep(60.0)
for i = 1:length(T.c)
  close(T.c[i])
end
printstyled("    ...sleep 60.0s while SeedLink session closes...\n", color=:green)
sleep(60.0)
@test isempty(T)==false
printstyled("  ...moving on now.\n", color=:light_green)
sync!(T)

# SeedLink time mode (more complicated)
printstyled("  TIME mode...\n", color=:light_green)

# To ensure precise timing, we'll pass d0 and d1 as strings
st = 0.0
en = 60.0
dt = en-st
(d0,d1) = parsetimewin(st,en)

S = SeisData()
SeedLink!(S, sta, mode="TIME", refresh=10.0, s=d0, t=d1, v=0)
printstyled("    ...first link initialized...\n", color=:light_green)

# Seedlink with a config file
SeedLink!(S, config_file, refresh=10.0, mode="TIME", s=d0, t=d1)
printstyled("    ...second link initialized...\n", color=:light_green)

# Seedlink with a config string
SeedLink!(S, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", refresh=10.0, s=d0, t=d1)
printstyled("    ...third link initialized...\n", color=:light_green)

# This takes time
printstyled(string("    ...sleep ", dt, " s while SeedLink session receives data...\n"), color=:green)
sleep(dt)
for i = 1:length(S.c)
    i == 3 && show(S)
    close(S.c[i])
end

@test isempty(S)==false

# Synchronize (the reason we used d0,d1 above)
printstyled(string("    ...sleep ", dt, " s while SeedLink closes...\n"), color=:green)
sleep(dt)
printstyled("  ...moving on now.\n", color=:light_green)
sync!(S, s=d0, t=d1)

# Are they about the same time length? (should be within 1 samp at longest fs)
L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
t = [S.t[i][1,2] for i = 1:S.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test L_max - L_min <= maximum(2.0./S.fs)
@test t_max - t_min <= maximum(2.0./S.fs)
