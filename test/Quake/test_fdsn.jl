fname = path*"/SampleFiles/fdsn.conf"
hood_reg = Float64[44.8, 46.0, -122.4, -121.0]
rainier_rad = Float64[46.852886, -121.760374, 0.0, 0.1]

printstyled("  FDSNevq\n", color=:light_green)

# FDSNevq
printstyled("    single-server query\n", color=:light_green)
(H,R) = FDSNevq("2011-03-11T05:47:00", mag=[3.0, 9.9], nev=1, src="IRIS", v=0)
(H,R) = FDSNevq("201103110547", mag=[3.0, 9.9], nev=10, src="IRIS", v=0)
@test length(H)==9

printstyled("    single-server query without nev specified\n", color=:light_green)
(H,R) = FDSNevq("2018-06-01",reg=[32.0,38.0,-120.0,-115.0,-50.0,50.0],mag=[2.0,8.0],evw=[0.,375243600.0]);
@test length(H) == length(R)
@test length(H) > 1000

printstyled("    multi-server query\n", color=:light_green)
open("FDSNevq.log", "w") do out
  redirect_stdout(out) do
    ot = replace(split(string(now()),'.')[1], r"[-,:,A-Z,a-z]" => "")
    (H,R) = FDSNevq(ot, mag=[3.0, 9.9], evw=[-86400.0, 0.0], src="all", nev=10, v=2)
  end
end

printstyled("    radius search (rad=)\n", color=:light_green)
(H,R) = FDSNevq("20190101000000", rad=rainier_rad, evw=[31536000.0, 31536000.0], mag=[0.0, 2.9], nev=100, src="IRIS", v=0)

printstyled("    partly-specified region search (reg=)\n", color=:light_green)
(H,R) = FDSNevq("20120601000000", reg=hood_reg, evw=[31536000.0, 31536000.0], mag=[0.0, 2.9], nev=100, src="IRIS", v=0)

# FDSNevt
printstyled("  FDSNevt\n", color=:light_green)
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?", v=0)
