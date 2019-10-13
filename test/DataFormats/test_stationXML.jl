xml_stfile  = path*"/SampleFiles/XML/fdsnws-station_2017-01-12T03-17-42Z.xml"
xml_stpat   = path*"/SampleFiles/XML/fdsnws-station*"
f_out       = "test.xml"

id_err    = "error in Station ID creation!"
unit_err  = "units don't match instrument code!"
true_id   = String["3337497", "3279407", "2844986", "2559759", "2092067", "1916079", "2413"]
true_ot   = DateTime("2011-03-11T05:46:23.200")
true_loc  = Float64[2.2376 38.2963; 93.0144 142.498; 26.3 19.7]
true_mag  = Float32[8.6, 9.1, 8.8, 8.5, 8.6, 9.0, 8.5]
true_msc  = String["MW", "MW", "MW", "MW", "MW", "MW", ""]
r1 = PZResp(a0 = 2.45956f13, f0 = 0.02f0, p = ComplexF32[-981.0+1009.0im, -981.0-1009.0im, -3290.0+1263.0im, -3290.0-1263.0im])
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
r2.z  = r2.z[1:6]
r2.f0 = 0.02f0
r2.a0 = 3.53734f17

printstyled("  FDSN station XML\n", color=:light_green)
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

# xdoc = LightXML.parse_string(xsta); xroot = LightXML.root(xdoc); xnet = child_elements(xroot);
# xr = get_elements_by_tagname(get_elements_by_tagname(get_elements_by_tagname(get_elements_by_tagname(xroot, "Network")[1], "Station")[1], "Channel")[1], "Response")[1];
# stage = get_elements_by_tagname(xr, "Stage");
printstyled("    with MultiStageResp\n", color=:light_green)
S = FDSN_sta_xml(xsta, msr=true)
r = S.resp[1]
for f in fieldnames(MultiStageResp)
  @test length(getfield(r,f)) == 9
end
@test r.stage[3].b[1:3] == [0.000244141, 0.000976562, 0.00244141]
@test r.fs[6] == 8000.0
@test r.fac[6] == 2
@test r.delay[6] == 7.5E-4
@test r.corr[6] == 7.5E-4
@test r.stage[9].b[6:9] == [-0.0000000298023, -0.0000000298023, -0.0000000298023, 0.0]
@test r.stage[9].a == []

printstyled("    read_sxml\n", color=:light_green)
S = read_sxml(xml_stfile)
T = read_sxml(xml_stpat)
@assert T.n > S.n
@test findid(T.id[S.n+1], S.id) == 0

printstyled("    read_meta\n", color=:light_green)
S = read_meta("sxml", xml_stfile)
T = read_meta("sxml", xml_stpat)
@assert T.n > S.n
@test findid(T.id[S.n+1], S.id) == 0

printstyled("    overwrite channel headers on time match\n", color=:light_green)
redirect_stdout(out) do
  xml_stfile = path*"/SampleFiles/XML/fdsnws-station_2017-01-12T03-17-42Z.xml"
  S = SeisData()
  read_station_xml!(S, xml_stfile, v=3)
  n = S.n
  read_station_xml!(S, xml_stfile, v=3)
  @test S.n == n
end

# XML writer
printstyled("    write_sxml\n", color=:light_green)
S = randSeisData(12)
S.id[1] = "CC.VALT..BHZ"
S.id[2] = "CC.VALT..BHE"
S.id[3] = "YY.FAIL"
S.name[2] = S.name[1]
write_sxml(f_out, S)
Sr = read_sxml(f_out)
sort!(S)
sort!(Sr)
for i in 1:S.n
  for f in (:name, :fs, :gain, :units)
    @test getfield(S, f)[i] == getfield(Sr, f)[i]
  end
  @test S.id[i]*(S.id[i] == "YY.FAIL" ? ".." : "") == Sr.id[i]
  if typeof(S.resp[i]) in (PZResp, PZResp64, MultiStageResp)
    if typeof(S.resp[i]) == PZResp64
      R = S.resp[i]
      S.resp[i] = PZResp(a0 = Float32(R.a0), f0 = Float32(R.f0),
        p = ComplexF32.(R.p), z = ComplexF32.(R.z))
    end
    @test S.resp[i] == Sr.resp[i]
  end
  if typeof(S.loc[i]) == GeoLoc
    for f in (:lat, :lon, :el, :dep, :az, :inc)
      @test getfield(S.loc[i],f) ≈ getfield(Sr.loc[i],f)
    end
  end
end

printstyled("      check that output of write_sxml is re-read identically\n", color=:light_green)
files = ls(xml_stpat)
for file in files
  S = read_sxml(file, msr=true)
  write_sxml(f_out, S)
  Sr = read_sxml("test.xml", msr=true)
  sort!(S)
  sort!(Sr)

  for f in datafields
    (f == :src) && continue
    @test getfield(S,f) == getfield(Sr,f)
  end
end
try
  rm(f_out)
catch err
  @warn(string("Can't remove ", f_out, ": throws error ", err))
end
