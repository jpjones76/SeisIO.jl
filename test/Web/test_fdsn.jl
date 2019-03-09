# using LightXML
printstyled("  FDSN web requests\n", color=:light_green)

# US Test
printstyled("    data from IRIS...\n", color=:light_green)
fname = path*"/SampleFiles/fdsn.conf"
S = SeisData()
get_data!(S, "FDSN", fname, src="IRIS", s=-600, t=0, v=0, w=true)

# Ensure station headers are set
j = findid(S, "UW.HOOD..ENE")
@test ≈(S.fs[j], 100.0)

# Ensure we got data
L = [length(x) for x in S.x]
@test (isempty(L) == false)
@test (maximum(L) > 0)

# Try a string array for input
S = SeisData()
get_data!(S, "FDSN", ["UW.HOOD..E??", "CC.VALT..???"], src="IRIS", s=-600, t=0)

# Try a single string
S = get_data("FDSN", "CC.JRO..BHZ", src="IRIS", s=-600, t=0)

# Test a bum data format
open("show.log", "w") do out
  redirect_stdout(out) do
    get_data!(S, "FDSN", "UW.LON.."; src="IRIS", s=-600, t=0, v=3, fmt="sac.zip")
  end
end

# FDSNevq
printstyled("    event header from IRIS...\n", color=:light_green)
S = FDSNevq("201103110547", mag=[3.0, 9.9], nev=10, src="IRIS", v=0)
@test length(S)==9

# FDSNsta
printstyled("    station data (seismometers + strainmeters) from IRIS...\n", color=:light_green)
S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??", v=0)
@test (findid(S, "PB.B001.T0.BS1")>0)
@test (findid(S, "PB.B001..EHZ")>0)
@test (findid(S, "CC.VALT..BHZ")>0)

# FDSNevt
printstyled("    event (header and data) from IRIS...\n", color=:light_green)
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?", v=0)

# Potsdam test
printstyled("    data from GFZ...\n", color=:light_green)
R = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s="2011-03-11T06:00:00", t="2011-03-11T06:05:00", v=0, y=false)
@test (isempty(R)==false)

printstyled("  FDSN XML\n", color=:light_green)
xml_evfile = path*"/SampleFiles/fdsnws-event_2017-01-12T03-18-55Z.xml"
xml_stfile = path*"/SampleFiles/fdsnws-station_2017-01-12T03-17-42Z.xml"
id_err = "error in Station ID creation!"
unit_err = "units don't match instrument code!"
true_id = Int[3337497, 3279407, 2844986, 2559759, 2092067, 1916079, 2413]
true_ot = DateTime("2011-03-11T05:46:23.200")
true_loc = Float64[2.2376 38.2963; 93.0144 142.498; 26.3 19.7]
true_mag = Float32[8.6, 9.1, 8.8, 8.5, 8.6, 9.0, 8.5]
true_msc = String["MW", "MW", "MW", "MW", "MW", "MW", "M?"]
r1 = [0.0+0.0im -981.0+1009.0im; 0.0+0.0im -981.0-1009.0im; 0.0+0.0im -3290.0+1263.0im; 0.0+0.0im -3290.0-1263.0im]
r2 = [  0.0+0.0im       -0.037-0.037im
        0.0+0.0im       -0.037+0.037im
        -15.15+0.0im    -15.64+0.0im
        -176.6+0.0im    -97.34-400.7im
        -463.1-430.5im  -97.34+400.7im
        -463.1+430.5im  -374.8+0.0im
        0.0+0.0im       -520.3+0.0im
        0.0+0.0im       -10530.0-10050.0im
        0.0+0.0im       -10530.0+10050.0im
        0.0+0.0im       -13300.0+0.0im
        0.0+0.0im       -255.097+0.0im ]

io = open(xml_evfile, "r")
xevt = read(io, String)
close(io)

io = open(xml_stfile, "r")
xsta = read(io, String)
close(io)

printstyled("    ...event XML...\n", color=:light_green)
(id, ot, loc, mag, msc) = SeisIO.FDSN_event_xml(xevt)

@test ≈(id, true_id)
@assert(ot[2]==true_ot, "OT parse error")
@test ≈(loc[:,1:2], true_loc)
@test ≈(mag, true_mag)
@assert(msc==true_msc, "Magnitude scale parse error")

printstyled("    ...station XML...\n", color=:light_green)
(ID, LOC, UNITS, GAIN, RESP, NAME, MISC) = SeisIO.FDSN_sta_xml(xsta)

@assert(ID[1]=="AK.ATKA..BNE", id_err)
@assert(ID[2]=="AK.ATKA..BNN", id_err)
@assert(ID[end-1]=="IU.MIDW.01.BHN", id_err)
@assert(ID[end]=="IU.MIDW.01.BHZ", id_err)
@test ≈(LOC[1], [52.2016, -174.1975, 0.055, 90.0, -90.0])
@test ≈(LOC[3][1:3], LOC[1][1:3])
for i = 1:length(UNITS)
    if UNITS[i] == "M/S**2"
        @assert(in(split(ID[i],'.')[4][2],['G', 'L', 'M', 'N'])==true, unit_err)
    elseif UNITS[i] in ["M/S", "M"]
        @assert(in(split(ID[i],'.')[4][2],['L', 'H'])==true, unit_err)
    elseif UNITS[i] == "V"
        @assert(split(ID[i],'.')[4][2]=='C', unit_err)
    end
end
@test ≈(GAIN[1], 283255.0)
@test ≈(GAIN[2], 284298.0)
@test ≈(GAIN[end-1], 8.38861E9)
@test ≈(GAIN[end], 8.38861E9)
@test ≈(RESP[1], r1)
@test ≈(RESP[2], r1)
@test ≈(RESP[end-1], r2)
@test ≈(RESP[end], r2)
