using Base.Test, Compat

# US Test
STA = "SEP,SHW,HSR,VALT"
CHA = "*"
NET = "CC,UW"
T = 60
S = FDSNget(net=NET, sta=STA, cha=CHA, t=T, v=true)
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

# Potsdam test
STA = "BKB"
NET = "GE"
CHA = "BH*" # 1 station, 18 channels...? Whyyyyyyyy is this useful...?
SRC = "GFZ"
ts = "2011-03-11T06:00:00"
te = "2011-03-11T06:05:00"
R = FDSNget(src=SRC, net=NET, sta=STA, cha=CHA, s=ts, t=te, v=true, y=false)

println("...done!")
