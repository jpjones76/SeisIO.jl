using Base.Test, Compat
using LightXML

xml_evfile = path*"/SampleFiles/fdsnws-event_2017-01-12T03-18-55Z.xml"
xml_stfile = path*"/SampleFiles/fdsnws-station_2017-01-12T03-17-42Z.xml"
id_err = "error in Station ID creation!"
unit_err = "units don't match instrument code!"
true_id = Int[3337497, 3279407, 2844986, 2559759, 2092067, 1916079, 2413]
true_ot = DateTime("2011-03-11T05:46:23.200")
true_loc = Float64[2.2376 38.2963; 93.0144 142.498; 26.3 19.7]
true_mag = Float32[8.6, 9.1, 8.8, 8.5, 8.6, 9.0, 8.5]
true_msc = Char['W' 'W' 'W' 'W' 'W' 'W' '?';' ' ' ' ' ' ' ' ' ' ' ' ' ']
r1 = [0.0+0.0im -981.0+1009.0im; 0.0+0.0im -981.0-1009.0im; 0.0+0.0im -3290.0+1263.0im; 0.0+0.0im -3290.0-1263.0im]
r2 = [0.0+0.0im      -0.037-0.037im
    0.0+0.0im      -0.037+0.037im
 -15.15+0.0im      -15.64+0.0im
 -176.6+0.0im      -97.34-400.7im
 -463.1-430.5im    -97.34+400.7im
 -463.1+430.5im    -374.8+0.0im
    0.0+0.0im      -520.3+0.0im
    0.0+0.0im    -10530.0-10050.0im
    0.0+0.0im    -10530.0+10050.0im
    0.0+0.0im    -13300.0+0.0im
    0.0+0.0im    -255.097+0.0im]

io = open(xml_evfile, "r")
xevt = readstring(io)
close(io)

io = open(xml_stfile, "r")
xsta = readstring(io)
close(io)

println(STDOUT, "xml...")
println(STDOUT, "...event parsing accuracy...")
(id, ot, loc, mag, msc) = SeisIO.FDSN_event_xml(xevt)

@test_approx_eq(id, true_id)
@assert(ot[2]==true_ot, "OT parse error")
@test_approx_eq(loc[:,1:2], true_loc)
@test_approx_eq(mag, true_mag)
@assert(msc==true_msc, "Magnitude scale parse error")

println(STDOUT, "...station parsing accuracy...")
(ID, LOC, UNITS, GAIN, RESP, NAME, MISC) = SeisIO.FDSN_sta_xml(xsta)

@assert(ID[1]=="AK.ATKA..BNE", id_err)
@assert(ID[2]=="AK.ATKA..BNN", id_err)
@assert(ID[end-1]=="IU.MIDW.01.BHN", id_err)
@assert(ID[end]=="IU.MIDW.01.BHZ", id_err)
@test_approx_eq(LOC[1], [52.2016, -174.1975, 0.055, 90.0, -90.0])
@test_approx_eq(LOC[3][1:3], LOC[1][1:3])
for i = 1:length(UNITS)
  if UNITS[i] == "M/S**2"
    @assert(in(split(ID[i],'.')[4][2],['G', 'L', 'M', 'N'])==true, unit_err)
  elseif UNITS[i] in ["M/S", "M"]
    @assert(in(split(ID[i],'.')[4][2],['L', 'H'])==true, unit_err)
  elseif UNITS[i] == "V"
    @assert(split(ID[i],'.')[4][2]=='C', unit_err)
  end
end
@test_approx_eq(GAIN[1], 283255.0)
@test_approx_eq(GAIN[2], 284298.0)
@test_approx_eq(GAIN[end-1], 8.38861E9)
@test_approx_eq(GAIN[end], 8.38861E9)
@test_approx_eq(RESP[1], r1)
@test_approx_eq(RESP[2], r1)
@test_approx_eq(RESP[end-1], r2)
@test_approx_eq(RESP[end], r2)
println(STDOUT, "...done testing FDSN XML parsing.")
