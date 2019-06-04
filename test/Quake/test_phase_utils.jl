src = [46.8523, -121.7603]
src2 = [48.7767, -121.8144]
rec = [45.5135 -122.6801; 44.0442 -123.0925; 42.3265 -122.8756]

G0 = gcdist(src, rec)                           # vec, arr
G1 = gcdist(src[1], src[2], rec)                # lat, lon, arr
G2 = gcdist(src[1], src[2], rec[1,1], rec[1,2]) # s_lat, s_lon, r_lat, r_lon
G3 = gcdist(vcat(src',src2'), rec[1,:])             # arr, arr
G4 = gcdist(vcat(src',src2'), rec[1,:])             # arr, rec[1,:]

@test G0 == G1
@test G0[1,:] == G1[1,:] == G2[1,:]
@test G3 == G4

printstyled("  phase_utils\n", color=:light_green)
GC.gc()
spad = 10.0
epad = 10.0
to = 30
src = "IRIS"
sta = "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?"

# First, a well-formatted string
(H,R) = FDSNevq("2018-11-30T17:29:29.00", nev=1, src="IRIS")
H = H[1]

# Now, not so hot
(H,R) = FDSNevq("201103110547", mag=[3.0, 9.9], nev=1, src="IRIS")
H = H[1]

# Create channel data
s = H.ot                                      # Start time for FDSNsta is event origin time
t = u2d(d2u(s) + 3600.0)                      # End time is 60 minutes later; we'll truncate
S = FDSNsta(sta, s=s, t=t, to=to)

# Check that nothing is initially in the phase catalog
Ev = SeisEvent(hdr=H, data=S[1:1])
@test length(Ev.data.pha[1]) == 0

printstyled("    request with invalid parameter\n", color=:light_green)
redirect_stdout(out) do
  get_pha!(Ev, pha="", model="do.my.little.dance.on.the.catwalk", to=to, v=2)
end
@test length(Ev.data.pha[1]) == 0

printstyled("    request with user-specified phase list\n", color=:light_green)
Ev = SeisEvent(hdr=H, data=S[1:1])
get_pha!(Ev, pha="P,S", to=to)
@test length(Ev.data.pha[1]) == 2
println("")
show_phases(Ev.data.pha[1])
println("")

printstyled("    request styles that return all phases\n", color=:light_green)
Ev = SeisEvent(hdr=H, data=S[1:1])
get_pha!(Ev, pha="", to=to)
pcat1 = Ev.data.pha[1]

Ev = SeisEvent(hdr=H, data=S[1:1])
get_pha!(Ev, pha="all", to=to)
pcat2 = Ev.data.pha[1]

Ev = SeisEvent(hdr=H, data=S[1:1])
get_pha!(Ev, pha="ttall", to=to)
pcat3 = Ev.data.pha[1]

@test pcat1 == pcat2 == pcat3

# This should work for all stations, yielding only the S time
printstyled("    multi-channel request\n", color=:light_green)
J = findall([endswith(id, "EHZ") for id in S.id])

printstyled("      default phase\n", color=:light_green)
Ev = SeisEvent(hdr=H, data=S[J])
SeisIO.KW.pha = "S"
get_pha!(Ev, to=to)
for i = 1:Ev.data.n
  @test length(Ev.data.pha[i]) == 1
  @test haskey(Ev.data.pha[i], "S")
end
SeisIO.KW.pha = "P"

printstyled("      user-specified phase list\n", color=:light_green)
Ev = SeisEvent(hdr=H, data=S[J])
get_pha!(Ev, pha="pP,PP", to=to)
for i = 1:Ev.data.n
  @test length(Ev.data.pha[i]) == 2
  @test haskey(Ev.data.pha[i], "PP")
  @test haskey(Ev.data.pha[i], "pP")
end

# This should work for all stations, yielding all times
printstyled("      all phases\n", color=:light_green)
Ev = SeisEvent(hdr=H, data=S[J])
get_pha!(Ev, pha="all", to=to)
for i = 1:Ev.data.n
  @test length(Ev.data.pha[i]) > 1
  @test haskey(Ev.data.pha[i], "P")
  @test haskey(Ev.data.pha[i], "S")
  @test haskey(Ev.data.pha[i], "pP")
  @test haskey(Ev.data.pha[i], "PP")
end
println("")
show_phases(Ev.data.pha[1])
println("")
