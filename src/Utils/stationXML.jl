function FDSN_sta_xml(xmlf::String;
                       s::String="0001-01-01T00:00:00",
                       t::String="9999-12-31T23:59:59")

  # if length(xmlf) < 256
  #   if isfile(xmlf)
  #     xdoc = LightXML.parse_file(xmlf)
  #   else
  #     xdoc = LightXML.parse_string(xmlf)
  #   end
  # else
  #   xdoc = LightXML.parse_string(xmlf)
  # end
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

                      # response
                      elseif name(i) == "Response"
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
                                c_units = replace(content(get_elements_by_tagname(y, "Name")[1]), "**" => "")
                              end
                            end

                          # stages
                          elseif name(r) == "Stage"
                            for sx in child_elements(r)
                              if name(sx) == "PolesZeros"
                                for pzx in child_elements(sx)
                                  npzx = name(pzx)

                                  # Zero
                                  # Pole
                                  if npzx in ["Zero", "Pole"]
                                    pzv = complex(
                                      parse(Float32, content(get_elements_by_tagname(pzx, "Real")[1])),
                                      parse(Float32, content(get_elements_by_tagname(pzx, "Imaginary")[1]))
                                    )
                                    if npzx == "Zero"
                                      push!(c_resp.z, pzv)
                                    else
                                      push!(c_resp.p, pzv)
                                    end

                                    #= TO DO
                                    (at some later date)
                                    gains, normalizations, poles, and zeros for each stage
                                    requires a much more complicated InstrumentResponse subtype
                                    =#

                                    # StageGain
                                    # elseif npzx == "StageGain"
                                    #   stage_gain = Float32(value(get_elements_by_tagname(pzx, "Value")[1]))
                                    #   stage_freq = Float32(value(get_elements_by_tagname(pzx, "Frequency")[1]))
                                    #
                                    # # NormalizationFactor
                                    # elseif npzx == "NormalizationFactor"
                                    #   stage_normfac = value(get_elements_by_tagname(pzx, "NormalizationFactor")[1])
                                    #
                                    # # NormalizationFrequency
                                    # elseif npzx == "NormalizationFrequency"
                                    #   stage_normfreq = value(get_elements_by_tagname(pzx, "NormalizationFrequency")[1])
                                    # end
                                  end
                                end
                              end
                            end
                          end
                          # end stages

                        end
                      end
                      # end response

                      # channel id
                      c_id = join([nn, ss, ll, cc], ".")
                      if findid(c_id, S) > 0
                        @warn(string("Redundant channel ", c_id, ": overwriting with latest channel info."))
                      end
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
                    C.misc["normfreq"] = c_normfreq
                    C.misc["ClockDrift"] = c_drift
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
