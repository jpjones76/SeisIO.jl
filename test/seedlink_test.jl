using Base.Test, Compat

# Seedlink with command-line stations
sta = ["SEP CC"; "HDW UW"]
st = 0.0
en = 30.0
dt = en-st

# To ensure precise timing, we'll pass d0 and d1 as strings
(d0,d1) = parsetimewin(st,en)
(C,SL) = SeedLink(sta, mode="TIME", r=10.0, s=d0, t=d1)

# This takes time
println(string("Sleeping for ", 2*dt, " seconds while SL fills..."))
sleep(dt)
close(C)
sleep(dt)

# Synchronize (the reason we used d0,d1 above)
sync!(SL, s=d0, t=d1)

# Are they about the same time length? (should be within 1 samp at longest fs)
L = [length(SL.x[i])/SL.fs[i] for i = 1:SL.n]
t = [SL.t[i][1,2] for i = 1:SL.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test_approx_eq(L_max - L_min <= maximum(1./SL.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./SL.fs), true)

# Seedlink with a config file
config_file = "./SampleFiles/seedlink.conf"
(d0,d1) = parsetimewin(st,en)
(C2,S2) = SeedLink(config_file, r=10.0, mode="TIME", s=d0, t=d1)

# This takes time
println(string("Sleeping for ", 2*dt, " seconds while SL fills..."))
sleep(dt)
close(C2)
sleep(dt)

# Synchronize (the reason we used d0,d1 above)
sync!(S2, s=d0, t=d1)

# Are they about the same time length? (should be within 1 samp at longest fs)
L = [length(S2.x[i])/S2.fs[i] for i = 1:S2.n]
t = [S2.t[i][1,2] for i = 1:S2.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test_approx_eq(L_max - L_min <= maximum(1./S2.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./S2.fs), true)

println("...done!")
