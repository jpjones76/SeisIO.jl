export read_sxml, write_sxml

function full_resp(xe::XMLElement)
  resp = MultiStageResp(12)
  ns = 0
  nmax = 0
  gain = one(Float64)
  f0 = one(Float64)
  xr = child_elements(xe)
  units = ""

  for r in xr
    if name(r) == "InstrumentSensitivity"
      for ii in child_elements(r)
        nii = name(ii)
        if nii == "Value"
          gain = parse(Float64, content(ii))
        elseif nii == "Frequency"
          f0 = parse(Float64, content(ii))
        elseif nii == "InputUnits"
          units = units2ucum(fix_units(content(get_elements_by_tagname(ii, "Name")[1])))
        end
      end

    # stages
    elseif name(r) == "Stage"
      ns = parse(Int64, attribute(r, "number"))
      nmax = max(ns, nmax)
      if ns > length(resp.fs)
        append!(resp, MultiStageResp(6))
      end
      resp_code = 0x00
      c = one(Float64)
      a0 = one(Float64)
      f0 = one(Float64)
      p = Array{Complex{Float64},1}(undef, 0)
      z = Array{Complex{Float64},1}(undef, 0)
      num = Array{Float64,1}(undef, 0)
      den = Array{Float64,1}(undef, 0)
      units_in = ""
      units_out = ""

      for ii in child_elements(r)
        nii = name(ii)
        if nii == "PolesZeros"
          resp_code = 0x02
          for iii in child_elements(ii)
            niii = name(iii)
            if niii == "PzTransferFunctionType"
              c = content(iii) == "LAPLACE (RADIANS/SECOND)" ? c : Float64(2pi)

            # Zero, Pole
            elseif niii in ["Zero", "Pole"]
              pzv = complex(
                parse(Float64, content(get_elements_by_tagname(iii, "Real")[1])),
                parse(Float64, content(get_elements_by_tagname(iii, "Imaginary")[1]))
              )
              if niii == "Zero"
                push!(z, pzv)
              else
                push!(p, pzv)
              end

            elseif niii == "InputUnits"
              resp.i[ns] = fix_units(content(get_elements_by_tagname(iii, "Name")[1]))

            elseif niii == "OutputUnits"
              resp.o[ns] = fix_units(content(get_elements_by_tagname(iii, "Name")[1]))

            elseif niii == "NormalizationFactor"
              a0 = parse(Float64, content(iii))

            elseif niii == "NormalizationFrequency"
              f0 = parse(Float64, content(iii))
            end

          end

        elseif nii == "StageGain"
          resp.gain[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Value")[1]))
          resp.fg[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Frequency")[1]))

        elseif nii == "Coefficients" || nii == "FIR"
          resp_code = 0x03
          for iii in child_elements(ii)
            niii = name(iii)
            if niii == "InputUnits"
              resp.i[ns] = fix_units(content(get_elements_by_tagname(iii, "Name")[1]))

            elseif niii == "OutputUnits"
              resp.o[ns] = fix_units(content(get_elements_by_tagname(iii, "Name")[1]))

            elseif niii == "NumeratorCoefficient" || niii == "Numerator"
              push!(num, parse(Float64, content(iii)))

            elseif niii == "DenominatorCoefficient" || niii == "Denominator"
              push!(den, parse(Float64, content(iii)))
            end
          end

        elseif nii == "Decimation"
          resp.fs[ns] = parse(Float64, content(get_elements_by_tagname(ii, "InputSampleRate")[1]))
          resp.fac[ns] = parse(Int64, content(get_elements_by_tagname(ii, "Factor")[1]))
          resp.os[ns] = parse(Int64, content(get_elements_by_tagname(ii, "Offset")[1]))
          resp.delay[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Delay")[1]))
          resp.corr[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Correction")[1]))
        end
      end

      # Post-process
      if resp_code == 0x02
        rmul!(z, c)
        rmul!(p ,c)
        resp.stage[ns] = PZResp64(z = z, p = p, a0 = a0, f0 = f0)
      elseif resp_code == 0x03
        resp.stage[ns] = CoeffResp(num, den)
      else
        resp.stage[ns] = nothing
      end
    end
    # end stages

  end
  L = length(resp.fs)
  for f in fieldnames(MultiStageResp)
    deleteat!(getfield(resp, f), (nmax+1):L)
  end
  return gain, units, resp
end

function FDSN_sta_xml(xmlf::String;
                       s::String="0001-01-01T00:00:00",
                       t::String="9999-12-31T23:59:59",
                       v::Int64=KW.v,
                       msr::Bool=false)

  xdoc = LightXML.parse_string(xmlf)
  xroot = LightXML.root(xdoc)
  xnet = child_elements(xroot)
  S = SeisData()
  s = string_time(s, BUF.date_buf)
  t = string_time(t, BUF.date_buf)

  for net in xnet
    # network level
    if name(net) == "Network"
      net_s = string_time(has_attribute(net, "startDate") ? attribute(net, "startDate") : "0001-01-01T00:00:00", BUF.date_buf)
      net_t = string_time(has_attribute(net, "endDate") ? attribute(net, "endDate") : "9999-12-31T11:59:59", BUF.date_buf)

      # do string comparisons work with <, > in Julia when dates are correctly formatted?
      if net_s ≤ t && net_t ≥ s
        nn = has_attribute(net, "code") ? attribute(net, "code") : ""
        xsta = child_elements(net)

        # station level
        for sta in xsta

          if name(sta) == "Station"
            sta_s = string_time(has_attribute(sta, "startDate") ? attribute(sta, "startDate") : "0001-01-01T00:00:00", BUF.date_buf)
            sta_t = string_time(has_attribute(sta, "endDate") ? attribute(sta, "endDate") : "9999-12-31T11:59:59", BUF.date_buf)

            if sta_s ≤ t && sta_t ≥ s
              ss = has_attribute(sta, "code") ? attribute(sta, "code") : ""

              # loop over child tags
              xcha = child_elements(sta)
              s_lat = 0.0
              s_lon = 0.0
              s_el  = 0.0
              s_name = ""

              for c in xcha
                # station lat
                if name(c) == "Latitude"
                  s_lat = parse(Float64, content(c))

                  # station lon
                elseif name(c) == "Longitude"
                  s_lat = parse(Float64, content(c))

                  # station el
                elseif name(c) == "Elevation"
                  s_el = parse(Float64, content(c))

                # site description -- we only care about the name
                elseif name(c) == "Site"
                  cx = child_elements(c)
                  for i in cx
                    if name(i) == "Name"
                      s_name = content(i)
                    end
                  end

                # channel element
                elseif name(c) == "Channel"
                  cha_s = string_time(has_attribute(c, "startDate") ? attribute(c, "startDate") : "0001-01-01T00:00:00", BUF.date_buf)
                  cha_t = string_time(has_attribute(c, "endDate") ? attribute(c, "endDate") : "9999-12-31T11:59:59", BUF.date_buf)
                  ll = has_attribute(c, "locationCode") ? attribute(c, "locationCode") : ""
                  cc = has_attribute(c, "code") ? attribute(c, "code") : ""

                  if cha_s ≤ t && cha_t ≥ s
                    # println(cha_s, " ≤ ", t, " && ", cha_t, " ≥ ", s)

                    c_id = "...."
                    c_name = identity(s_name)
                    c_units = ""
                    c_sensor = ""

                    # location defaults
                    c_lat = s_lat
                    c_lon = s_lon
                    c_el  = s_el
                    c_dep = 0.0
                    c_az  = 0.0
                    c_inc = 0.0

                    # sampling and response defaults
                    c_fs        = 0.0
                    c_gain      = 1.0
                    c_normfreq  = 1.0
                    c_drift     = 0.0
                    c_resp      = PZResp()

                    cx = child_elements(c)
                    for i in cx

                      # location params
                      if name(i) == "Latitude"
                        c_lat = parse(Float64, content(i))
                      elseif name(i) == "Longitude"
                        c_lon = parse(Float64, content(i))
                      elseif name(i) == "Elevation"
                        c_el = parse(Float64, content(i))
                      elseif name(i) == "Depth"
                        c_dep = parse(Float64, content(i))
                      elseif name(i) == "Azimuth"
                        c_az = parse(Float64, content(i))
                      elseif name(i) == "Dip"
                        c_inc = parse(Float64, content(i)) - 90.0

                      # sampling, drift
                      elseif name(i) == "SampleRate"
                        c_fs = parse(Float64, content(i))
                      elseif name(i) == "ClockDrift"
                        c_drift = parse(Float64, content(i))

                      # sensor type
                      elseif name(i) == "Sensor"
                        rx = child_elements(i)
                        for r in rx
                          if name(r) == "Description"
                            c_sensor = content(r)
                          end
                        end

                      # response
                      elseif name(i) == "Response"
                        if msr
                          c_gain, c_units, c_resp = full_resp(i)
                        else
                          rx = child_elements(i)
                          for r in rx
                            if name(r) == "InstrumentSensitivity"
                              for y in child_elements(r)
                                if name(y) == "Value"
                                  # gain
                                  c_gain = parse(Float64, content(y))
                                  # println("gain = ", c_gain)
                                elseif name(y) == "Frequency"
                                  # normfreq
                                  # c_normfreq = parse(Float64, content(y))
                                elseif name(y) == "InputUnits"
                                  # calibrationunits
                                  c_units = units2ucum(fix_units(content(get_elements_by_tagname(y, "Name")[1])))
                                end
                              end

                            # stages
                            elseif name(r) == "Stage"
                              for sx in child_elements(r)
                                if name(sx) == "PolesZeros"
                                  p = Array{Complex{Float32},1}(undef, 0)
                                  z = Array{Complex{Float32},1}(undef, 0)
                                  c = 1.0f0
                                  for pzx in child_elements(sx)
                                    npzx = name(pzx)
                                    if npzx == "PzTransferFunctionType"
                                      c = content(pzx) == "LAPLACE (RADIANS/SECOND)" ? c : Float32(2pi)
                                      #= ...this assumes that "DIGITAL (Z-TRANSFORM)"
                                      means what I think it does -- like all terms in
                                      FDSN, there is no documentation =#

                                    # Zero, Pole
                                    elseif npzx in ["Zero", "Pole"]
                                      pzv = complex(
                                        parse(Float32, content(get_elements_by_tagname(pzx, "Real")[1])),
                                        parse(Float32, content(get_elements_by_tagname(pzx, "Imaginary")[1]))
                                      )
                                      if npzx == "Zero"
                                        push!(z, pzv)
                                      else
                                        push!(p, pzv)
                                      end

                                    elseif npzx == "NormalizationFactor"
                                      c_resp.a0 = parse(Float64, content(pzx))

                                    elseif npzx == "NormalizationFrequency"
                                      c_resp.f0 = parse(Float64, content(pzx))

                                    end
                                  end
                                  if length(z) > 0
                                    rmul!(z, c)
                                    append!(c_resp.z, z)
                                  end
                                  if length(p) > 0
                                    rmul!(p, c)
                                    append!(c_resp.p, p)
                                  end
                                end
                              end
                            end
                            # end stages
                          end
                        end
                      end
                      # end response
                    end

                    # channel id
                    c_id = join([nn, ss, ll, cc], ".")
                    if findid(c_id, S) > 0 && (v > 0)
                      @warn(string("Channel ", c_id, " has multiple sets of parameters in time range ", s, " - ", t))
                    end

                    # channel location
                    c_loc = GeoLoc( lat = c_lat,
                                    lon = c_lon,
                                    el  = c_el,
                                    dep = c_dep,
                                    az  = c_az,
                                    inc = c_inc )

                    # build SeisChannel object
                    C = SeisChannel(id    = c_id,
                                    name  = c_name,
                                    gain  = c_gain,
                                    fs    = c_fs,
                                    loc   = c_loc,
                                    units = c_units,
                                    resp  = c_resp )
                    C.misc["ClockDrift"] = c_drift
                    C.misc["startDate"] = cha_s #Dates.DateTime(cha_s).instant.periods.value*1000 - dtconst
                    C.misc["endDate"] = cha_t #Dates.DateTime(cha_t).instant.periods.value*1000 - dtconst
                    if !isempty(c_sensor)
                      C.misc["SensorDescription"] = c_sensor
                    end
                    push!(S, C)

                  end
                  # done with channel
                end
                # end channel element
              end
            end
          end
        end
        # end station element
      end
    end
    # end network level
  end
  free(xdoc)
  return S
end

"""
    S = read_sxml(xml_file [, KWs ])

Read FDSN StationXML file `xml_file` into SeisData object S.

### Keywords
* `s`::String: start time. Format "YYYY-MM-DDThh:mm:ss", e.g., "0001-01-01T00:00:00".
* `t`::String: termination (end) time. Format "YYYY-MM-DDThh:mm:ss".
* `msr`::Bool: read instrument response info as MultiStageResp? (Default: false)
* `v`::Int64: verbosity.
"""
function read_sxml(fpat::String;
                   s::String="0001-01-01T00:00:00",
                   t::String="9999-12-31T23:59:59",
                   msr::Bool=false,
                   v::Int64=KW.v)

  if safe_isfile(fpat)
    io = open(fpat, "r")
    xsta = read(io, String)
    close(io)
    S = FDSN_sta_xml(xsta, s=s, t=t, msr=msr, v=v)
    fill!(S.src, fpat)
  else
    files = ls(fpat)
    if length(files) > 0
      io = open(files[1], "r")
      xsta = read(io, String)
      close(io)
      S = FDSN_sta_xml(xsta, s=s, t=t, msr=msr, v=v)
      if length(files) > 1
        for i = 2:length(files)
          io = open(files[i], "r")
          xsta = read(io, String)
          close(io)
          T = FDSN_sta_xml(xsta, s=s, t=t, msr=msr, v=v)
          fill!(T.src, fpat)
          append!(S, T)
        end
      end
    else
      error("file(s) not found!")
    end
  end
  return S
end

function sxml_mergehdr!(S::GphysData, T::GphysData;
                        nofs::Bool=false,
                        app::Bool=true,
                        v::Int64=KW.v)


  relevant_fields = nofs ? (:name, :loc, :gain, :resp, :units) : (:name, :loc, :fs, :gain, :resp, :units)
  k = Int64[]
  for i = 1:length(T)

    # Match on ID, si, ei
    si = isempty(T.t[i]) ? get(T.misc[i], "startDate", typemin(Int64)) : T.t[i][1,2]
    ei = isempty(T.t[i]) ? get(T.misc[i], "endDate", typemax(Int64)) : endtime(T.t[i], T.fs[i])
    id = T.id[i]
    c = 0
    for j = 1:length(S.id)
      if S.id[j] == id
        sj = isempty(S.t[j]) ? get(S.misc[j], "startDate", si) : S.t[j][1,2]
        ej = isempty(S.t[j]) ? get(S.misc[j], "endDate", ei) : endtime(S.t[j], S.fs[j])
        if min(si ≤ ej, ei ≥ sj) == true
          c = j
          break
        end
      end
    end

    # Overwrite S[j] headers on match
    if c != 0
      (v > 2) && println("id/time match! id = ", S.id[c], ". Overwriting S[", c, "] headers from T[", i, "]")
      for f in relevant_fields
        # S.(f)[c] = T.(f)[i]
        setindex!(getfield(S, f), getindex(getfield(T, f), i), c)
      end
      note!(S, c, string("sxml_mergehdr!, overwrote ", relevant_fields))
      note!(S, c, string("src: ", T.src[i]))
      S.misc[c] = merge(T.misc[i], S.misc[c])
      if i in k
        @warn(string("Already used ID = ", T.id[i], " to overwrite a channel header!"))
      end

      # Flag k for delete from T
      push!(k, i)
    end
  end

  # Delete channels that were already used to overwrite headers in S
  if isempty(k) == false
    deleteat!(T, k)
  end

  # Append remainder of T
  (v > 1) && println("remaining entries in T = ", T.n)
  if app && (isempty(T) == false)
    append!(S, T)
  end

  return nothing
end

function read_station_xml!(S::GphysData, file::String;
                           msr::Bool=false,
                           s::String="0001-01-01T00:00:00",
                           t::String="9999-12-31T23:59:59",
                           v::Int64=KW.v)

  if sizeof(file) < 256
    io = open(file, "r")
    xsta = read(io, String)
    close(io)
  else
    xsta = file
  end
  T = FDSN_sta_xml(xsta, msr=msr, s=s, t=t, v=v)
  fill!(T.src, file)
  sxml_mergehdr!(S, T, v=v)
  return nothing
end

function read_station_xml(file::String;
                 msr::Bool=false,
                 s::String="0001-01-01T00:00:00",
                 t::String="9999-12-31T23:59:59",
                 v::Int64=KW.v)

  S = SeisData()
  read_station_xml!(S, file, msr=msr, s=s, t=t, v=v)
  return S
end

function msr_to_xml(io::IO, r::MultiStageResp, gain::Float64, units::String)
  Nstg = length(r.stage)
  sens_f = 0.0
  if Nstg > 0
    sens_f = r.fg[1]
  end

  write(io, "          <InstrumentSensitivity>\n            <Value>")
  print(io, gain)
  write(io, "</Value>\n            <Frequency>")
  print(io, sens_f)
  write(io, "</Frequency>\n            <InputUnits>\n              <Name>")
  write(io, get(ucum_to_seed, units, units))
  write(io, "</Name>\n            </InputUnits>\n          </InstrumentSensitivity>\n")

  u1 = "              <InputUnits>\n                <Name>"
  u2 = "</Name>\n              </InputUnits>\n              <OutputUnits>\n                <Name>"
  u3 =   "</Name>\n              </OutputUnits>\n"

  @inbounds for i in 1:Nstg
    ui = get(ucum_to_seed, r.i[i], r.i[i])
    uo = get(ucum_to_seed, r.o[i], r.o[i])

    write(io, "          <Stage number=\"")
    print(io, i)
    write(io, "\">\n")

    if typeof(r.stage[i]) in (PZResp64, PZResp)
      write(io, "            <PolesZeros>\n")
      write(io, u1)
      write(io, ui)
      write(io, u2)
      write(io, uo)
      write(io, u3)
      write(io, "              <PzTransferFunctionType>LAPLACE (RADIANS/SECOND)</PzTransferFunctionType>\n              <NormalizationFactor>")
      print(io, r.stage[i].a0)
      write(io, "</NormalizationFactor>\n              <NormalizationFrequency>")
      print(io, r.stage[i].f0)
      write(io, "</NormalizationFrequency>\n")
      for j = 1:length(r.stage[i].z)
        write(io, "              <Zero number = \"")
        print(io, j)
        write(io, "\">\n                <Real minusError=\"0\" plusError=\"0\">")
        print(io, real(r.stage[i].z[j]))
        write(io, "</Real>\n                <Imaginary minusError=\"0\" plusError=\"0\">")
        print(io, imag(r.stage[i].z[j]))
        write(io, "</Imaginary>\n              </Zero>\n")
      end
      for j = 1:length(r.stage[i].p)
        write(io, "              <Pole number = \"")
        print(io, j)
        write(io, "\">\n                <Real minusError=\"0\" plusError=\"0\">")
        print(io, real(r.stage[i].p[j]))
        write(io, "</Real>\n                <Imaginary minusError=\"0\" plusError=\"0\">")
        print(io, imag(r.stage[i].p[j]))
        write(io, "</Imaginary>\n              </Pole>\n")
      end
      write(io, "            </PolesZeros>\n")
    else
      if typeof(r.stage[i]) == CoeffResp
        write(io, "            <Coefficients>\n")
        write(io, u1)
        write(io, ui)
        write(io, u2)
        write(io, uo)
        write(io, u3)
        write(io, "              <CfTransferFunctionType>DIGITAL</CfTransferFunctionType>\n")
        for j = 1:length(r.stage[i].b)
          write(io, "              <Numerator minusError=\"0\" plusError=\"0\">")
          print(io, r.stage[i].b[j])
          write(io, "</Numerator>\n")
        end
        for j = 1:length(r.stage[i].a)
          write(io, "              <Denominator minusError=\"0\" plusError=\"0\">")
          print(io, r.stage[i].a[j])
          write(io, "</Denominator>\n")
        end
        write(io, "            </Coefficients>\n")
      end

      if r.fac[i] > 0
        write(io, "            <Decimation>\n              <InputSampleRate>")
        print(io, r.fs[i])
        write(io, "</InputSampleRate>\n              <Factor>")
        print(io, r.fac[i])
        write(io, "</Factor>\n              <Offset>")
        print(io, r.os[i])
        write(io, "</Offset>\n              <Delay>")
        print(io, r.delay[i])
        write(io, "</Delay>\n              <Correction>")
        print(io, r.corr[i])
        write(io, "</Correction>\n            </Decimation>\n")
      end
    end
    write(io, "            <StageGain>\n              <Value>")
    print(io, r.gain[i])
    write(io, "</Value>\n              <Frequency>")
    print(io, r.fg[i])
    write(io, "</Frequency>\n            </StageGain>\n          </Stage>\n")
  end
  return nothing
end

function mk_xml!(io::IO, S::GphysData, chans::Array{Int64,1})
  blank_t0 = round(Int64, d2u(now())*μs)

  write(io, "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n\n<FDSNStationXML xmlns=\"http://www.fdsn.org/xml/station/1\" schemaVersion=\"1.0\" xsi:schemaLocation=\"http://www.fdsn.org/xml/station/1 http://www.fdsn.org/xml/station/fdsn-station-1.0.xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <Source>SeisIO</Source>\n\n  <Created>")
  print(io, now())
  write(io, "</Created>\n")

  nch = length(chans)
  nets = Array{String,1}(undef, nch)
  stas = Array{String,1}(undef, nch)
  locs = Array{String,1}(undef, nch)
  chas = Array{String,1}(undef, nch)
  t0 = zeros(Int64, nch)
  t1 = zeros(Int64, nch)

  done = falses(nch)

  # Fill in nets, stas, locs, chas
  fill!(t0, blank_t0)
  fill!(t1, xml_endtime)
  @inbounds for j = 1:nch
    i = chans[j]
    id = split_id(S.id[i])
    nets[j] = id[1]
    stas[j] = id[2]
    locs[j] = id[3]
    chas[j] = id[4]

    # precedence for start time: S.misc[i]["startDate"] > S.t[i][1,2] > blank_t0
    if haskey(S.misc[i], "startDate")
      c_start = get(S.misc[i], "startDate", blank_t0)
      if typeof(c_start) == Int64
        t0[j] = c_start
      end
    end

    # precedence for end time: S.misc[i]["startDate"] > endtime(S.t[i],S.fs[i]) > 19880899199000000
    if haskey(S.misc[i], "endDate")
      c_end = get(S.misc[i], "endDate", xml_endtime)
      if typeof(c_end) == Int64
        t1[j] = c_end
      end
    end

    if isempty(S.t[i]) == false
      if t0[j] == blank_t0
        t0[j] = S.t[i][1,2]
      end
      if t1[j] == xml_endtime
        t1[j] = endtime(S.t[i], S.fs[i])
      end
    end
  end

  # Loop over all channels in cha that are not done
  @inbounds for j = 1:nch
    (done[j]) && continue

    # Get all selected channels from same network
    nn = nets[j]
    ss = stas[j]
    net = findall(nets.==nn)
    ts = minimum(t0[net])*μs
    te = maximum(t1[net])*μs
    ds = u2d(ts)
    de = u2d(te)

    # Open net node
    write(io, "  <Network code=\"")
    write(io, nn)
    write(io, "\" startDate=\"")
    print(io, ds)
    write(io, "\" endDate=\"")
    print(io, de)
    write(io, "\">\n")

    # Loop over stations in network
    ci = Int64[]
    sta_name = ""
    sta_lat = 0.0
    sta_lon = 0.0
    sta_el = 0.0

    # Fill channel index array, ci; set station location and name
    for j = 1:nch
      if stas[j] == ss && nets[j] == nn
        i = chans[j]
        push!(ci, j)

        if isempty(sta_name)
          if !isempty(S.name[i])
            sta_name = S.name[i]
          end
        end

        if (sta_lat == 0.0) || (sta_lon == 0.0) || (sta_el == 0.0)
          if typeof(S.loc[i]) == GeoLoc
            loc = S.loc[i]
            if loc.lat != 0.0
              sta_lat = loc.lat
            end

            if loc.lon != 0.0
              sta_lon = loc.lon
            end

            if loc.el != 0.0
              sta_el = loc.el
            end
          end
        end
      end
    end
    ts = minimum(t0[ci])*μs
    te = maximum(t1[ci])*μs
    ds = u2d(ts)
    de = u2d(te)

    # Open sta node
    write(io, "    <Station code=\"")
    write(io, ss)
    write(io, "\" startDate=\"")
    print(io, ds)
    write(io, "\" endDate=\"")
    print(io, de)
    write(io, "\">\n      <Latitude>")
    print(io, sta_lat)
    write(io, "</Latitude>\n      <Longitude>")
    print(io, sta_lon)
    write(io, "</Longitude>\n      <Elevation>")
    print(io, sta_el)
    write(io, "</Elevation>\n      <Site>\n        <Name>")
    write(io, sta_name)
    write(io, "</Name>\n      </Site>\n")

    # Loop over cha nodes
    for j in ci
      i = chans[j]

      # Channel location
      if typeof(S.loc[i]) == GeoLoc
        loc = S.loc[i]
      else
        loc = GeoLoc()
      end

      # Instrument response
      if typeof(S.resp[i]) == MultiStageResp
        resp = S.resp[i]
      else
        if typeof(S.resp[i]) in (PZResp, PZResp64)
          resp = MultiStageResp(2)
          resp.fac[2] = 1
        else
          resp = MultiStageResp(1)
        end
        resp.stage[1] = S.resp[i]
      end

      # Open cha node
      write(io, "      <Channel code=\"")
      write(io, chas[j])
      write(io, "\" locationCode=\"")
      write(io, locs[j])
      write(io, "\" startDate=\"")
      print(io, u2d(t0[j]*μs))
      write(io, "\" endDate=\"")
      print(io, u2d(t1[j]*μs))
      write(io, "\">\n", "        <Latitude>")
      print(io, loc.lat)
      write(io, "</Latitude>\n        <Longitude>")
      print(io, loc.lon)
      write(io, "</Longitude>\n        <Elevation>")
      print(io, loc.el)
      write(io, "</Elevation>\n        <Depth>")
      print(io, loc.dep)
      write(io, "</Depth>\n        <Azimuth>")
      print(io, loc.az)
      write(io, "</Azimuth>\n        <Dip>")
      print(io, 90.0 + loc.inc)
      write(io, "</Dip>\n        <SampleRate>")
      print(io, S.fs[i])
      write(io, "</SampleRate>\n        <ClockDrift>")
      print(io, get(S.misc[i], "ClockDrift", 0.0))
      write(io, "</ClockDrift>\n        <Sensor>\n          <Description>")
      write(io, get(S.misc[i], "SensorDescription", "Unknown"))
      write(io, "</Description>\n        </Sensor>\n        <Response>\n")
      msr_to_xml(io, resp, S.gain[i], S.units[i])
      write(io, "        </Response>\n      </Channel>\n")

      done[j] = true
    end
    write(io, "    </Station>\n  </Network>\n")
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
  mk_xml!(fid, S, chans)
  close(fid)
  return nothing
end
