export read_sxml

function full_resp(xe::XMLElement)
  resp = MultiStageResp()
  ns = 0
  gain = one(Float64)
  f0 = zero(Float64)
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
          units = units2ucum(
            fix_units(
              lowercase(
                content(get_elements_by_tagname(ii, "Name")[1])
                )
              )
            )
        end
      end

    # stages
    elseif name(r) == "Stage"
      ns += 1
      resp_code = 0x00
      for f in (:fs, :gain, :fg, :delay, :corr)
        push!(getfield(resp, f), zero(Float64))
      end
      push!(resp.factor, zero(Int64))
      push!(resp.offset, zero(Int64))
      c = 1.0
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
            end

            # These are redundant to "stage 0" values
            # elseif niii == "NormalizationFactor"
            #   resp.nfac[ns] = parse(Float64, content(iii))
            #
            # elseif niii == "NormalizationFrequency"
            #   resp.fn[ns] = parse(Float64, content(iii))
            # end
          end

        elseif nii == "StageGain"
          resp.gain[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Value")[1]))
          resp.fg[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Frequency")[1]))

        elseif nii == "Coefficients" || nii == "FIR"
          resp_code = 0x03
          for iii in child_elements(ii)
            niii = name(iii)
            if niii == "InputUnits"
              units_in = fix_units(
                lowercase(
                  content(get_elements_by_tagname(iii, "Name")[1])
                  )
                )

            elseif niii == "OutputUnits"
              units_out = fix_units(
                lowercase(
                  content(get_elements_by_tagname(iii, "Name")[1])
                  )
                )

            elseif niii == "NumeratorCoefficient" || niii == "Numerator"
              push!(num, parse(Float64, content(iii)))

            elseif niii == "DenominatorCoefficient" || niii == "Denominator"
              push!(den, parse(Float64, content(iii)))
            end
          end

        elseif nii == "Decimation"
          resp.fs[ns] = parse(Float64, content(get_elements_by_tagname(ii, "InputSampleRate")[1]))
          resp.factor[ns] = parse(Int64, content(get_elements_by_tagname(ii, "Factor")[1]))
          resp.offset[ns] = parse(Int64, content(get_elements_by_tagname(ii, "Offset")[1]))
          resp.delay[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Delay")[1]))
          resp.corr[ns] = parse(Float64, content(get_elements_by_tagname(ii, "Correction")[1]))
        end
      end

      # Post-process
      if resp_code == 0x02
        rmul!(z, c)
        rmul!(p ,c)
        push!(resp.stage, PZResp64(z = z, p = p))
        if ns == 1
          resp.stage[ns].f0 = f0
          resp_a0!(resp.stage[ns])
        end
      elseif resp_code == 0x03
        push!(resp.stage, CoeffResp(units_in, units_out, num, den))
      else
        push!(resp.stage, GenResp())
      end
    end
    # end stages

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
  for net in xnet
    # network level
    if name(net) == "Network"
      net_s = has_attribute(net, "startDate") ? attribute(net, "startDate") : "0001-01-01T00:00:00"
      net_t = has_attribute(net, "endDate") ? attribute(net, "endDate") : "9999-12-31T11:59:59"

      # do string comparisons work with <, > in Julia when dates are correctly formatted?
      if net_s ≤ t && net_t ≥ s
        nn = has_attribute(net, "code") ? attribute(net, "code") : ""
        xsta = child_elements(net)

        # station level
        for sta in xsta

          if name(sta) == "Station"
            sta_s = has_attribute(sta, "startDate") ? attribute(sta, "startDate") : "0001-01-01T00:00:00"
            sta_t = has_attribute(sta, "endDate") ? attribute(sta, "endDate") : "9999-12-31T11:59:59"

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
                  cha_s = has_attribute(c, "startDate") ? attribute(c, "startDate") : "0001-01-01T00:00:00"
                  cha_t = has_attribute(c, "endDate") ? attribute(c, "endDate") : "9999-12-31T11:59:59"
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
                                  c_normfreq = parse(Float64, content(y))
                                elseif name(y) == "InputUnits"
                                  # calibrationunits
                                  c_units = units2ucum(
                                    fix_units(
                                      lowercase(content(get_elements_by_tagname(y, "Name")[1])))
                                      )
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

                    # instrument response
                    if msr == false
                      c_resp.f0 = c_normfreq
                      resp_a0!(c_resp)
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
                    C.misc["startDate"] = Dates.DateTime(cha_s).instant.periods.value*1000 - dtconst
                    C.misc["endDate"] = Dates.DateTime(cha_t).instant.periods.value*1000 - dtconst
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
          append!(S, FDSN_sta_xml(xsta, s=s, t=t, msr=msr, v=v))
        end
      end
    end
  end
  return S
end


function read_station_xml!(S::GphysData, file::String;
                           v::Int64=KW.v)

  io = open(file, "r")
  xsta = read(io, String)
  close(io)
  T = FDSN_sta_xml(xsta, msr=false, v=v)
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
          c = i
          break
        end
      end
    end

    # Overwrite S[j] headers on match
    if c != 0
      (v > 2) && println("id/time match! id = ", S.id[c], ". Overwriting S[", c, "] headers from T[", i, "]")
      for f in (:name, :loc, :fs, :gain, :resp, :units)
        setindex!(getfield(S, f), getindex(getfield(T, f), i), c)
      end
      note!(S, c, string("read_station_xml!,", file, ", overwrote (:name, :loc, :fs, :gain, :resp, :units)"))
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
  if isempty(T) == false
    append!(S, T)
  end

  return nothing
end
