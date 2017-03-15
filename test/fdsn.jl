using Base.Test, Compat

# FDSNevq
println(STDOUT, "...FDSNevq...")
S = FDSNevq("201103110547", mag=[3.0 9.9], n=10, src="all");
@assert(length(S)==9)

# FDSNsta
println(STDOUT, "...FDSN station query (seismometers + strainmeters)...")
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")
@assert(findfirst(S.id .== "PB.B001.T0.BS1")>0)
@assert(findfirst(S.id .== "PB.B001..EHZ")>0)
@assert(findfirst(S.id .== "CC.VALT..BHZ")>0)

# FDSNevt
println(STDOUT, "...FDSN event request...")
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")

# US Test
println(STDOUT, "...IRIS FDSN data request...")
fname = path*"/SampleFiles/fdsn.conf"
T = -60
S = FDSNget(fname, s=0, t=T, v=1)
@assert(isempty(S)==false)
!isempty(find(S.id .== "UW.SHW..ELZ")) && (S -= "UW.SHW..ELZ")
!isempty(find(S.id .== "UW.HSR..ELZ")) && (S -= "UW.HSR..ELZ")
sync!(S)
L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
t = [S.t[i][1,2] for i = 1:S.n]
L_min = minimum(L)
L_max = maximum(L)
t_min = minimum(t)
t_max = maximum(t)
@assert(L_max - L_min <= maximum(1./S.fs))
@assert(t_max - t_min <= maximum(1./S.fs))

# Potsdam test
println(STDOUT, "...Potsdam FDSN data request...")
R = FDSNget("GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=1, y=false)
@assert(isempty(R)==false)
println("...done!")
