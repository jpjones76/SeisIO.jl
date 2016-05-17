using Base.Test, Compat
include("../FDSN.jl")
println("FDSN test...")

# US Test
STA = "SEP,SHW,HSR,VALT"
CHA = "*"
NET = "CC,UW"
T = 120

S = FDSNget(net=NET, sta=STA, cha=CHA, t=T, v=true)
for i = 1:1:S.Nc
  for j = i:1:S.Nc
    @test_approx_eq(length(S.Data[i]), length(S.Time[j]))
    @test_approx_eq(S.Start[i], S.Start[j])
    @test_approx_eq(S.End[i], S.End[j])
  end
end
!isempty(find(S.Name .== "SHW  ELZUW")) && RmSeisChan(S, "SHW  ELZUW")
!isempty(find(S.Name .== "HSR  ELZUW")) && RmSeisChan(S, "HSR  ELZUW")
PlotSeis(S)

# Potsdam test
STA = "BKB"
NET = "GE"
CHA = "BH*" # 1 station, 18 channels...? Whyyyyyyyy is this useful...?
SRC = "GFZ"
ts = "2011-03-11T06:00:00Z"
te = "2011-03-11T06:05:00Z"
 S = FDSNget(src=SRC, net=NET, sta=STA, cha=CHA, s=ts, t=te, v=true,
             do_filt=false, do_sync=false)
PlotSeis(S)

# IPGP test
# STA = "DSO,BOR"; NET = "PF"; CHA = "*"; SRC = "IGPG"
# ...meta-data only? Ffffffff---

println("...done!")
