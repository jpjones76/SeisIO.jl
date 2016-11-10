using Base.Test, Compat

# Seedlink with command-line stations
sta = ["GPW UW"; "MBW UW"]
(C,SL) = SeedLink(sta, mode="TIME", t=30.0)
println("Sleeping for 45 seconds while SL fills...")
sleep(45)
close(C)
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
(C2,S2) = SeedLink(config_file, mode="TIME", t=30.0)
println("Sleeping for 60 seconds while S2 fills...")
sleep(45)
close(C2)
L = [length(S2.x[i])/S2.fs[i] for i = 1:S2.n]
t = [S2.t[i][1,2] for i = 1:S2.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test_approx_eq(L_max - L_min <= maximum(1./S2.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./S2.fs), true)

println("...done!")
