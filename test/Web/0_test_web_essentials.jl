import SeisIO: get_HTTP_req, webhdr, datareq_summ
xml_evfile = path*"/SampleFiles/fdsnws-event_2017-01-12T03-18-55Z.xml"
xml_stfile = path*"/SampleFiles/fdsnws-station_2017-01-12T03-17-42Z.xml"
d1 = "2019-03-14T02:18:00"
d2 = "2019-03-14T02:28:00"
to = 30

# From FDSN the response code is 200
url = "http://service.iris.edu/fdsnws/dataselect/1/query?format=miniseed&net=UW&sta=XNXNX&loc=99&cha=QQQ&start="*d1*"&end="*d2*"&szsrecs=true"
req_info_str = datareq_summ("FDSNWS data", "UW.XNXNX.99.QQQ", d1, d2)
(req, parsable) = get_HTTP_req(url, req_info_str, to, status_exception=false)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

(req,parsable) = get_HTTP_req(url, req_info_str, to, status_exception=true)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

# From IRIS the response code is 400 and we can get an error
url = "http://service.iris.edu/irisws/timeseries/1/query?net=DE&sta=NENA&loc=99&cha=LUFTBALLOONS&start="*d1*"&end="*d2*"&scale=AUTO&output=miniseed"
req_info_str = datareq_summ("IRISWS data", "DE.NENA.99.LUFTBALLOONS", d1, d2)
(req,parsable) = get_HTTP_req(url, req_info_str, to, status_exception=false)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")

(req,parsable) = get_HTTP_req(url, req_info_str, to, status_exception=true)
@test typeof(req) == Array{UInt8,1}
@test occursin("HTTP/1.1 400 Bad Request", String(req))

printstyled("  FDSN XML\n", color=:light_green)

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

printstyled("    event XML\n", color=:light_green)
(id, ot, loc, mag, msc) = FDSN_event_xml(xevt)

@test ≈(id, true_id)
@assert(ot[2]==true_ot, "OT parse error")
@test ≈(loc[:,1:2], true_loc)
@test ≈(mag, true_mag)
@assert(msc==true_msc, "Magnitude scale parse error")

printstyled("    station XML\n", color=:light_green)
(ID, NAME, LOC, FS, GAIN, RESP, UNITS, MISC) = FDSN_sta_xml(xsta)

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
