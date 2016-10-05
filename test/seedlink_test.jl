using Base.Test, Compat
config_file = "./SampleFiles/seedlink.conf"

# Seedlink with command-line stations
sta = ["GPW UW"; "MBW UW"]
SL = SeedLink(sta, t=60.0, vv=true, N=8)
L = [length(SL.x[i])/SL.fs[i] for i = 1:SL.n]
t = [SL.t[i][1,2] for i = 1:SL.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test_approx_eq(L_max - L_min <= maximum(1./SL.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./SL.fs), true)

# Seedlink with a config file
S2 = SeedLink(config_file, t=60.0, vv=true, N=8)
L = [length(S2.x[i])/S2.fs[i] for i = 1:S2.n]
t = [S2.t[i][1,2] for i = 1:S2.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@test_approx_eq(L_max - L_min <= maximum(1./S2.fs), true)
@test_approx_eq(t_max - t_min <= maximum(1./S2.fs), true)

println("...done!")
