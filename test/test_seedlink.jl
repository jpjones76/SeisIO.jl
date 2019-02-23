# Seedlink with command-line stations
sta = ["CC.SEP", "UW.HDW"]
config_file = path*"/SampleFiles/seedlink.conf"

# Checking
tf = has_live_stream(sta, "rtserve.iris.washington.edu")

# SeedLink DATA mode (easier)
println("...SeedLink! DATA mode...")
T = SeisData()
println("...link 1: command-line station list...")
SeedLink!(T, sta, mode="DATA", refresh=11.1)
println("...link 2: station file...")
SeedLink!(T, config_file, mode="DATA", refresh=13.3)
println("...sleep 60.0s while SeedLink session receives data...")
sleep(60.0)
for i = 1:length(T.c)
  close(T.c[i])
end
println("...sleep 60.0s while SeedLink session closes...")
sleep(60.0)
@assert(isempty(T)==false)
println("...moving on now.")
sync!(T)

# SeedLink time mode (more complicated)
println("...SeedLink! TIME mode...")

# To ensure precise timing, we'll pass d0 and d1 as strings
st = 0.0
en = 60.0
dt = en-st
(d0,d1) = parsetimewin(st,en)

S = SeisData()
SeedLink!(S, sta, mode="TIME", refresh=10.0, s=d0, t=d1, v=0)
println("...first link initialized...")

# Seedlink with a config file
SeedLink!(S, config_file, refresh=10.0, mode="TIME", s=d0, t=d1)
println("...second link initialized...")

# Seedlink with a config string
SeedLink!(S, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", refresh=10.0, s=d0, t=d1)
println("...third link initialized...")

# This takes time
println(string("Sleeping for ", 2*dt, " seconds while S fills..."))
sleep(dt)
for i = 1:length(S.c)
  close(S.c[i])
end
@assert(isempty(S)==false)

# Synchronize (the reason we used d0,d1 above)
sleep(dt)
println("...moving on now.")
sync!(S, s=d0, t=d1)

# Are they about the same time length? (should be within 1 samp at longest fs)
L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
t = [S.t[i][1,2] for i = 1:S.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@assert(L_max - L_min <= maximum(2.0./S.fs))
@assert(t_max - t_min <= maximum(2.0./S.fs))


println("...done!")
