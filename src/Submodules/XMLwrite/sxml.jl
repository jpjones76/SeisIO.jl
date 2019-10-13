struct XCha
  code::String
  locationCode::String
  startTime::Int64
  endTime::Int64
  lat::Float64
  lon::Float64
  el::Float64
  dep::Float64
  az::Float64
  dip::Float64
  fs::Float64
  gain::Float64
  drift::Float64
  units::String
  desc::String
  resp::MultiStageResp
end

mutable struct XSta
  startTime::Int64
  endTime::Int64
  lat::Float64
  lon::Float64
  el::Float64
  name::String
  cha::Array{XCha,1}
end

mutable struct XNet
  startTime::Int64
  endTime::Int64
  sta::Dict{String, XSta}
end

function msr_to_xml(io::IO, cha::XCha)
  r = cha.resp
  Nstg = length(r.stage)
  sens_f = 0.0
  if Nstg > 0
    sens_f = r.fg[1]
  end

  write(io, " "^10, "<InstrumentSensitivity>\n")
  write(io, " "^12, "<Value>", string(cha.gain), "</Value>\n")
  write(io, " "^12, "<Frequency>", string(sens_f), "</Frequency>\n")
  write(io, " "^12, "<InputUnits>\n")
  write(io, " "^14, "<Name>", get(ucum_to_seed, cha.units, cha.units), "</Name>\n")
  write(io, " "^12, "</InputUnits>\n")
  write(io, " "^10, "</InstrumentSensitivity>\n")

  for i in 1:Nstg
    write(io, " "^10, "<Stage number=\"", string(i), "\">\n")

    units_stanza = " "^14 * "<InputUnits>\n" *
     " "^16 * "<Name>" * get(ucum_to_seed, r.i[i], r.i[i]) * "</Name>\n" *
     " "^14 * "</InputUnits>\n" *
     " "^14 * "<OutputUnits>\n" *
     " "^16 * "<Name>" * get(ucum_to_seed, r.o[i], r.o[i]) * "</Name>\n" *
     " "^14 * "</OutputUnits>\n"

    gain_stanza = " "^12 * "<StageGain>\n" *
     " "^14 * "<Value>" * string(r.gain[i]) * "</Value>\n" *
     " "^14 * "<Frequency>" * string(r.fg[i]) * "</Frequency>\n" *
     " "^12 * "</StageGain>\n"

    if typeof(r.stage[i]) in (PZResp64, PZResp)
      write(io, " "^12, "<PolesZeros>\n")
      write(io, units_stanza)
      write(io, " "^14, "<PzTransferFunctionType>LAPLACE (RADIANS/SECOND)</PzTransferFunctionType>\n")
      write(io, " "^14, "<NormalizationFactor>", string(r.stage[i].a0), "</NormalizationFactor>\n")
      write(io, " "^14, "<NormalizationFrequency>", string(r.stage[i].f0), "</NormalizationFrequency>\n")
      for j = 1:length(r.stage[i].z)
        write(io, " "^14, "<Zero number = \"", string(j) , "\">\n")
        write(io, " "^16, "<Real minusError=\"0\" plusError=\"0\">", string(real(r.stage[i].z[j])), "</Real>\n")
        write(io, " "^16, "<Imaginary minusError=\"0\" plusError=\"0\">", string(imag(r.stage[i].z[j])), "</Imaginary>\n")
        write(io, " "^14, "</Zero>\n")
      end
      for j = 1:length(r.stage[i].p)
        write(io, " "^14, "<Pole number = \"", string(j) , "\">\n")
        write(io, " "^16, "<Real minusError=\"0\" plusError=\"0\">", string(real(r.stage[i].p[j])), "</Real>\n")
        write(io, " "^16, "<Imaginary minusError=\"0\" plusError=\"0\">", string(imag(r.stage[i].p[j])), "</Imaginary>\n")
        write(io, " "^14, "</Pole>\n")
      end
      write(io, " "^12, "</PolesZeros>\n")
    else
      if typeof(r.stage[i]) == CoeffResp
        write(io, " "^12, "<Coefficients>\n")
        write(io, units_stanza)
        write(io, " "^14, "<CfTransferFunctionType>DIGITAL</CfTransferFunctionType>\n")
        for j = 1:length(r.stage[i].b)
          write(io, " "^14, "<Numerator minusError=\"0\" plusError=\"0\">", string(r.stage[i].b[j]), "</Numerator>\n")
        end
        for j = 1:length(r.stage[i].a)
          write(io, " "^14, "<Denominator minusError=\"0\" plusError=\"0\">", string(r.stage[i].a[j]), "</Denominator>\n")
        end
        write(io, " "^12, "</Coefficients>\n")
      end

      if r.fac[i] > 0
        write(io, " "^12, "<Decimation>\n")
        write(io, " "^14, "<InputSampleRate>", string(r.fs[i]),"</InputSampleRate>\n")
        write(io, " "^14, "<Factor>", string(r.fac[i]),"</Factor>\n")
        write(io, " "^14, "<Offset>", string(r.os[i]),"</Offset>\n")
        write(io, " "^14, "<Delay>", string(r.delay[i]),"</Delay>\n")
        write(io, " "^14, "<Correction>", string(r.corr[i]),"</Correction>\n")
        write(io, " "^12, "</Decimation>\n")
      end
    end
    write(io, gain_stanza)
    write(io, " "^10, "</Stage>\n")
  end
  return nothing
end

function mk_xml!(io::IO, S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[])

  chans = mkchans(chans, S.n)

  blank_t0 = round(Int64, d2u(now())*1.0e6)
  SXML = Dict{String, XNet}()
  for i in chans
    id = String.(split(S.id[i], ".", limit=4, keepempty=true))
    L = length(id)
    if L < 4
      id2 = deepcopy(id)
      id = Array{String, 1}(undef, 4)
      fill!(id, "")
      for j = 1:L
        id[j] = identity(id2[j])
      end
    end

    # Channel identifiers
    nn = id[1]
    ss = id[2]
    ll = id[3]
    cc = id[4]

    # Start time
    t0 = get(S.misc[i], "startDate", isempty(S.t[i]) ? blank_t0 : S.t[i][1,2])
    t1 = get(S.misc[i], "endDate", 19880899199000000)
    ClockDrift = get(S.misc[i], "ClockDrift", 0.0)
    SensorDescription = get(S.misc[i], "SensorDescription", "Unknown")

    # Channel location
    lat = 0.0
    lon = 0.0
    el  = 0.0
    dep = 0.0
    az  = 0.0
    dip = 0.0
    fs = S.fs[i]
    if typeof(S.loc[i]) == GeoLoc
      loc = S.loc[i]
      lat = loc.lat
      lon = loc.lon
      el  = loc.el
      dep = loc.dep
      az  = loc.az
      dip = 90.0 + loc.inc
    end

    # Instrument response
    if typeof(S.resp[i]) == MultiStageResp
      resp = S.resp[i]
    else
      resp = MultiStageResp(1)
      resp.stage[1] = S.resp[i]
    end

    cha = XCha(cc, ll, t0, t1, lat, lon, el, dep, az, dip, S.fs[i], S.gain[i], ClockDrift, S.units[i], SensorDescription, resp)
    if haskey(SXML, nn) == false
      SXML[nn] = XNet(t0, t1, Dict{String, XSta}(ss => XSta(t0, t1, lat, lon, el, S.name[i], XCha[cha])))
    else
      net = SXML[nn]
      if t0 < net.startTime
        net.startTime = t0
      end
      if t1 > net.endTime
        net.endTime = t1
      end
      if haskey(net.sta, ss) == false
        net.sta[ss] = XSta(t0, t1, lat, lon, el, S.name[i], XCha[cha])
      else
        sta = net.sta[ss]
        if t0 < sta.startTime
          sta.startTime = t0
        end
        if t1 > sta.endTime
          sta.endTime = t1
        end
        push!(sta.cha, cha)
      end
    end
  end

  # io = IOBuffer()
  write(io, "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n\n<FDSNStationXML xmlns=\"http://www.fdsn.org/xml/station/1\" schemaVersion=\"1.0\" xsi:schemaLocation=\"http://www.fdsn.org/xml/station/1 http://www.fdsn.org/xml/station/fdsn-station-1.0.xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <Source>SeisIO</Source>\n\n  <Created>")
  write(io, string(now()))
  write(io, "</Created>\n")
  for nn in sort(collect(keys(SXML)))
    net = SXML[nn]
    tn = string(u2d(net.startTime*1.0e-6))
    tne = string(u2d(net.endTime*1.0e-6))
    write(io, "  <Network code=\"", nn,
              "\" startDate=\"", tn,
              "\" endDate=\"", tne, "\">\n")
    for ss in sort(collect(keys(net.sta)))
      sta = net.sta[ss]
      ts = string(u2d(sta.startTime*1.0e-6))
      tse = string(u2d(sta.endTime*1.0e-6))
      write(io, "    <Station code=\"", ss,
                "\" startDate=\"", ts,
                "\" endDate=\"", tse, "\">\n")
      write(io, "      <Latitude>", string(sta.lat), "</Latitude>\n")
      write(io, "      <Longitude>", string(sta.lon), "</Longitude>\n")
      write(io, "      <Elevation>", string(sta.el), "</Elevation>\n")
      write(io, "      <Site>\n        <Name>", sta.name, "</Name>\n      </Site>\n")
      for i = 1:length(sta.cha)
        cha = sta.cha[i]
        tc = string(u2d(cha.startTime*1.0e-6))
        tce = string(u2d(cha.endTime*1.0e-6))
        write(io, "      <Channel code=\"", cha.code,
                  "\" locationCode=\"", cha.locationCode,
                  "\" startDate=\"", tc,
                  "\" endDate=\"", tce, "\">\n")
        write(io, "        <Latitude>", string(cha.lat), "</Latitude>\n")
        write(io, "        <Longitude>", string(cha.lon), "</Longitude>\n")
        write(io, "        <Elevation>", string(cha.el), "</Elevation>\n")
        write(io, "        <Depth>", string(cha.dep), "</Depth>\n")
        write(io, "        <Azimuth>", string(cha.az), "</Azimuth>\n")
        write(io, "        <Dip>", string(cha.dip), "</Dip>\n")
        write(io, "        <SampleRate>", string(cha.fs), "</SampleRate>\n")
        write(io, "        <ClockDrift>", string(cha.drift), "</ClockDrift>\n")
        write(io, "        <Sensor>\n")
        write(io, "          <Description>", cha.desc, "</Description>\n")
        write(io, "        </Sensor>\n")
        write(io, "        <Response>\n")
        msr_to_xml(io, cha)
        write(io, "        </Response>\n")
        write(io, "      </Channel>\n")
      end
      write(io, "    </Station>\n")
    end
    write(io, "  </Network>\n")
  end
  write(io, "</FDSNStationXML>\n")

  return nothing
end

"""
    write_sxml(fname::String, S::GphysData[, chans=Cha])

Write station XML from the fields of `S` to file `fname`.

Use keyword `chans=Cha` to restrict station XML write to `Cha`. This keyword
can accept an Integer, UnitRange, or Array{Int64,1} as its argument.
"""
function write_sxml(str::String, S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[])

  chans = mkchans(chans, S.n)
  fid = open(str, "w")
  mk_xml!(fid, S, chans=chans)
  close(fid)
  return nothing
end
