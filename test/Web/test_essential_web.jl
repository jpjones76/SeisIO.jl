xml_evfile1 = path*"/SampleFiles/fdsnws-event_2017-01-12T03-18-55Z.xml"
xml_evfile2 = path*"/SampleFiles/ISC_2011-tohoku-oki.xml"
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
@test parsable == false

url = "http://service.iris.edu/irisws/timeseries/1/query?net=DE&sta=NENA&loc=99&cha=LUFTBALLOONS&start="*d1*"&end="*d2*"&scale=AUTO&output=miniseed"
(req, parsable) = get_HTTP_req(url, req_info_str, to, status_exception=true)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

(req, parsable) = get_http_post(url, NOOF, to, status_exception=false)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

(req, parsable) = get_http_post(url, NOOF, to, status_exception=true)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

printstyled("  FDSN XML\n", color=:light_green)

id_err = "error in Station ID creation!"
unit_err = "units don't match instrument code!"
true_id = String["3337497", "3279407", "2844986", "2559759", "2092067", "1916079", "2413"]
true_ot = DateTime("2011-03-11T05:46:23.200")
true_loc = Float64[2.2376 38.2963; 93.0144 142.498; 26.3 19.7]
true_mag = Float32[8.6, 9.1, 8.8, 8.5, 8.6, 9.0, 8.5]
true_msc = String["MW", "MW", "MW", "MW", "MW", "MW", ""]
r1 = PZResp(f0 = 0.02f0, p = ComplexF32[-981.0+1009.0im, -981.0-1009.0im, -3290.0+1263.0im, -3290.0-1263.0im])
resp_a0!(r1)
r2 = PZResp(Complex{Float32}.([   0.0+0.0im       -0.037-0.037im
                                  0.0+0.0im       -0.037+0.037im
                                  -15.15+0.0im    -15.64+0.0im
                                  -176.6+0.0im    -97.34-400.7im
                                  -463.1-430.5im  -97.34+400.7im
                                  -463.1+430.5im  -374.8+0.0im
                                  0.0+0.0im       -520.3+0.0im
                                  0.0+0.0im       -10530.0-10050.0im
                                  0.0+0.0im       -10530.0+10050.0im
                                  0.0+0.0im       -13300.0+0.0im
                                  0.0+0.0im       -255.097+0.0im ]),rev=true)
r2.z = r2.z[1:6]
r2.f0 = 0.02f0
resp_a0!(r2)

printstyled("    QuakeML test 1\n", color=:light_green)
(EC,RR) = read_qml(xml_evfile1)
Nev = length(EC)
@test Nev == length(true_id)
for i = 1:Nev
  @test EC[i].id == true_id[i]
  @test EC[i].mag.val == true_mag[i]
  @test EC[i].mag.scale == true_msc[i]
end

@test EC[2].ot==true_ot
for i = 1:2
  @test ≈(EC[i].loc.lat, true_loc[1,i])
  @test ≈(EC[i].loc.lon, true_loc[2,i])
  @test ≈(EC[i].loc.dep, true_loc[3,i])
end

printstyled("    QuakeML test 2\n", color=:light_green)
H, R = read_qml(xml_evfile2)
H = H[1]
R = R[1]

# Check basic headers
@test H.typ == "earthquake"
@test H.id == "16461282"

# Check that the correct magnitude is retained
@test H.mag.val ≥ 9.0f0
@test H.mag.scale == "MW"

# Check H.loc
@test H.loc.lat == 38.2963
@test H.loc.lon == 142.498
@test H.loc.dep == 19.7152
@test H.loc.rms == 2.1567
@test H.loc.nst == 2643
@test H.loc.src == "ISC"

# Check source params
@test R.id == "600002952"
@test R.m0 == 5.312e22
@test R.mt == [1.73e22, -2.81e21, -1.45e22, 2.12e22, 4.55e22, -6.57e21]
@test R.dm == [6.0e19, 5.0e19, 5.0e19, 6.8e20, 6.5e20, 4.0e19]
@test R.pax == [295.0 115.0 205.0; 55.0 35.0 0.0; 5.305e22 -5.319e22 1.4e20]
@test R.planes == [25.0 203.0; 80.0 10.0; 90.0 88.0]
@test R.st.dur == 70.0
@test R.misc["methodID"] == "Best_double_couple"
@test R.misc["pax_desc"] == "azimuth, plunge, length"
@test R.misc["author"] == "GCMT"
@test R.misc["planes_desc"] == "strike, dip, rake"
@test R.misc["derivedOriginID"] == "600126955"

printstyled("    station XML\n", color=:light_green)
io = open(xml_stfile, "r")
xsta = read(io, String)
close(io)

# (ID, NAME, LOC, FS, GAIN, RESP, UNITS, MISC) = FDSN_sta_xml(xsta)
S = FDSN_sta_xml(xsta)
ID = S.id
NAME = S.name
LOC = S.loc
FS = S.fs
GAIN = S.gain
RESP = S.resp
UNITS = S.units
MISC = S.misc

@assert(ID[1]=="AK.ATKA..BNE", id_err)
@assert(ID[2]=="AK.ATKA..BNN", id_err)
@assert(ID[end-1]=="IU.MIDW.01.BHN", id_err)
@assert(ID[end]=="IU.MIDW.01.BHZ", id_err)
@test ==(LOC[1], GeoLoc(lat=52.2016, lon=-174.1975, el=55.0, az=90.0, inc=-90.0))
@test ≈(LOC[3].lat, LOC[1].lat)
@test ≈(LOC[3].lon, LOC[1].lon)
@test ≈(LOC[3].dep, LOC[1].dep)
for i = 1:length(UNITS)
    if UNITS[i] == "m/s2"
        @assert(in(split(ID[i],'.')[4][2],['G', 'L', 'M', 'N'])==true, unit_err)
    elseif UNITS[i] in ["m/s", "m"]
        @assert(in(split(ID[i],'.')[4][2],['L', 'H'])==true, unit_err)
    elseif UNITS[i] == "v"
        @assert(split(ID[i],'.')[4][2]=='C', unit_err)
    end
end
@test ≈(GAIN[1], 283255.0)
@test ≈(GAIN[2], 284298.0)
@test ≈(GAIN[end-1], 8.38861E9)
@test ≈(GAIN[end], 8.38861E9)
@test RESP[1] == RESP[2] == r1
@test RESP[end-1] == RESP[end] == r2

chanspec()
chanspec()
chanspec()

# Test tracking of changes in SeisData structure S ==========================
# Does S change? Let's see.
printstyled("  Tracking with track_on!, track_off!\n", color=:light_green)

S = SeisData()
track_on!(S)  # should do nothing but no error
@test track_off!(S) == nothing # should return nothing for empty struct

S = SeisData(3)
@test track_off!(S) == [true,true,true]
# @test_throws ErrorException("Tracking not enabled!") track_off!(S)

# Now replace S with randSeisData
S = randSeisData(3)
track_on!(S)
@test haskey(S.misc[1], "track")
push!(S, randSeisChannel())
u = track_off!(S)
@test (u == [false, false, false, true])
@test haskey(S.misc[1], "track") == false

# Now turn tracking on again and move things around
track_on!(S)
@test haskey(S.misc[1], "track")
Ch1 = deepcopy(S[1])
Ch3 = deepcopy(S[3])
S[3] = deepcopy(Ch1)
S[1] = deepcopy(Ch3)
@test haskey(S.misc[3], "track")
@test haskey(S.misc[1], "track") == false
@test haskey(S.misc[2], "track") == false
append!(S.x[1], rand(Float64, 1024))        # Should flag channel 1 as updated
S.id[2] = reverse(S.id[2])                  # Should flag channel 2 as updated
u = track_off!(S)
@test (u == [true, true, false, false])
@test haskey(S.misc[3], "track") == false
