# FDSNevq
println(stdout, "...FDSNevq...")
S = FDSNevq("201103110547", mag=[3.0 9.9], n=10, src="IRIS", v=0);
@assert(length(S)==9)
# NCEDC may not still exist as a source
# Potsdam query is really fragile

# FDSNsta
println(stdout, "...FDSN station query (seismometers + strainmeters)...");
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??", v=0);
@assert(findfirst(S.id .== "PB.B001.T0.BS1")>0)
@assert(findfirst(S.id .== "PB.B001..EHZ")>0)
@assert(findfirst(S.id .== "CC.VALT..BHZ")>0)

# FDSNevt
println(stdout, "...FDSN event request...")
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?", v=0);

# US Test
println(stdout, "...IRIS FDSN data request...")
fname = path*"/SampleFiles/fdsn.conf"
S = get_ts_data(FDSNget, fname, 0, 600, v=0);
# ts = 3600
# S = SeisData()
# c = 1
# while isempty(S)
#     ts = ts - 3600
#     S = FDSNget(fname, s=ts, t=ts-600, v=1)
#
#     # Change: only do next section if the counter is non-null, otherwise warn and move on
#     !isempty(findall(S.id .== "UW.SHW..ELZ")) && (S -= "UW.SHW..ELZ")
#     !isempty(findall(S.id .== "UW.HSR..ELZ")) && (S -= "UW.HSR..ELZ")
#
#     if isempty(S)
#         c += 1
#         if c < 10
#             @warn("Decrementing time and trying again. If problem persists, check that time zone is set correctly.")
#             ts = ts - 3600
#         else
#             error("Too many retries, exiting test with error. Check that network is configured correctly.")
#         end
#     end
# end
# sync!(S)
# L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
# t = [S.t[i][1,2] for i = 1:S.n]
# L_min = minimum(L)
# L_max = maximum(L)
# t_min = minimum(t)
# t_max = maximum(t)
# @assert(L_max - L_min <= maximum(2.0./S.fs))
# @assert(t_max - t_min <= maximum(2.0./S.fs))

# Potsdam test
println(stdout, "...Potsdam FDSN data request...")
R = FDSNget("GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
@assert(isempty(R)==false)
println("...done!")
