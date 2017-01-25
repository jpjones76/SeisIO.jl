using Base.Test, Compat

# evq
println(STDOUT, "...evq...")
S = evq("201103110547", mag=[3.0 9.9], n=10, src="all");

# FDSNsta
println(STDOUT, "...FDSN station query (seismometers + strainmeters)...")
CC = "CC VALT, PB B001  BS?, PB B001 E??"
S = FDSNsta(CC)
@test_approx_eq(findfirst(S.id .== "PB.B001.T0.BS1")>0, true)
@test_approx_eq(findfirst(S.id .== "PB.B001..EHZ")>0, true)
@test_approx_eq(findfirst(S.id .== "CC.VALT..BHZ")>0, true)

# FDSN_evt
println(STDOUT, "...FDSN event request...")
S = FDSN_evt("201103110547", "PB B004  EH?,PB B004  BS?,PB B001  BS?,PB B001  EH?")

# US Test
println(STDOUT, "...IRIS FDSN data request...")
STA = "SEP,SHW,HSR,VALT"
CHA = "*"
NET = "CC,UW"
T = -60
S = FDSNget(net=NET, sta=STA, cha=CHA, s=0, t=T, v=1)
if S.n == 0
  warn("No data retrieved! Can't fully test FDSNget accuracy, please try again later")
else
  !isempty(find(S.name .== "SHW  ELZUW")) && (S -= "SHW  ELZUW")
  !isempty(find(S.name .== "HSR  ELZUW")) && (S -= "HSR  ELZUW")
  L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
  t = [S.t[i][1,2] for i = 1:S.n]
  L_min = minimum(L)
  L_max = maximum(L)
  t_min = minimum(t)
  t_max = maximum(t)
  @test_approx_eq(L_max - L_min <= maximum(1./S.fs), true)
  @test_approx_eq(t_max - t_min <= maximum(1./S.fs), true)
end

# Potsdam test
println(STDOUT, "...Potsdam FDSN data request...")
STA = "BKB"
NET = "GE"
CHA = "BH*" # 1 station, 18 channels...? Whyyyyyyyy is this useful...?
SRC = "GFZ"
ts = "2011-03-11T06:00:00"
te = "2011-03-11T06:05:00"
R = FDSNget(src=SRC, net=NET, sta=STA, cha=CHA, s=ts, t=te, v=1, y=false)

println("...done!")
