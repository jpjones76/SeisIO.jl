using Base.Test, Compat
path = Base.source_dir()

# Seedlink with command-line stations
println("...SeedLink! TIME mode...")
sta = ["SEP CC"; "HDW UW"]
st = 0.0
en = 30.0
dt = en-st

# To ensure precise timing, we'll pass d0 and d1 as strings
(d0,d1) = parsetimewin(st,en)
S = SeisData()
SeedLink!(S, sta, mode="TIME", r=10.0, s=d0, t=d1)
println("...first link initialized...")

# Seedlink with a config file
config_file = path*"/SampleFiles/seedlink.conf"
SeedLink!(S, config_file, r=10.0, mode="TIME", s=d0, t=d1)
println("...second link initialized...")

# This takes time
println(string("Sleeping for ", 2*dt, " seconds while S fills..."))
sleep(dt)
for i = 1:length(S.c)
  close(S.c[i])
end

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
@test_approx_eq(L_max - L_min <= maximum(1./S.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./S.fs), true)

println("...SeedLink! DATA mode...")
T = SeisData()
println("...link 1: command-line station list...")
SeedLink!(T, sta, mode="DATA", r=11.1)
println("...link 2: station file...")
SeedLink!(T, config_file, mode="DATA", r=13.3)
sleep(dt)
for i = 1:length(S.c)
  close(T.c[i])
end
sleep(dt/2)
println("...moving on now.")
sync!(T)

println("...done!")
