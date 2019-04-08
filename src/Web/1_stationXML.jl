function LightXML_plunge(xtmp::Array{LightXML.XMLElement,1}, str::AbstractString)
  xtmp2 = Array{LightXML.XMLElement,1}()
  for i=1:length(xtmp)
    append!(xtmp2, get_elements_by_tagname(xtmp[i], str))
  end
  return xtmp2
end

function LightXML_findall(xtmp::Array{LightXML.XMLElement,1}, str::String)
  S = split(str, "/")
  for i=1:length(S)
    xtmp = LightXML_plunge(xtmp, S[i])
  end
  return xtmp
end
LightXML_findall(xdoc::LightXML.XMLDocument, str::String) = LightXML_findall([LightXML.root(xdoc)], str)
LightXML_findall(xtmp::LightXML.XMLElement, str::String) = LightXML_findall([xtmp], str)

function LightXML_str!(v::String, x::LightXML.XMLElement, s::String)
  Q = LightXML_findall(x, s)
  if isempty(Q) == false
    v = content(Q[1])
  end
  return v
end
LightXML_float!(v::Float64, x::LightXML.XMLElement, s::String) = Float64(Meta.parse(LightXML_str!(string(v), x, s)))

# FDSN event XML handler
function FDSN_event_xml(string_data::String)
  xevt = LightXML.parse_string(string_data)
  events = LightXML_findall(xevt, "eventParameters/event")
  N = length(events)
  id = Array{Int64,1}(undef, N)
  ot = Array{DateTime,1}(undef, N)
  loc = Array{Float64,2}(undef, 3, N)
  mag = Array{Float32,1}(undef, N)
  msc = Array{String,1}(undef, N)
  for (i,evt) in enumerate(events)
    id[i] = ( try
                Int64(Meta.parse(String(split(attribute(evt, "publicID"),'=')[2])))
              catch
                0
              end )
    ot[i] = DateTime(LightXML_str!("1970-01-01T00:00:00", evt, "origin/time/value"))
    loc[1,i] = LightXML_float!(0.0, evt, "origin/latitude/value")
    loc[2,i] = LightXML_float!(0.0, evt, "origin/longitude/value")
    loc[3,i] = LightXML_float!(0.0, evt, "origin/depth/value")/1.0e3
    mag[i] = Float32(LightXML_float!(-5.0, evt, "magnitude/mag/value"))

    tmp = LightXML_str!("--", evt, "magnitude/type")
    if isempty(tmp)
        msc[i] = "M?"
    else
        msc[i] = tmp
    end
  end
  return (id, ot, loc, mag, msc)
end

function FDSN_sta_xml(string_data::String)
    xroot = LightXML.parse_string(string_data)
    N = length(LightXML_findall(xroot, "Network/Station/Channel"))

    ID    = Array{String,1}(undef, N)
    NAME  = Array{String,1}(undef, N)
    FS    = Array{Float64,1}(undef, N)
    LOC   = Array{Array{Float64,1}}(undef, N)
    UNITS = Array{String,1}(undef, N)
    GAIN  = Array{Float64,1}(undef, N)
    RESP  = Array{Array{Complex{Float64},2}}(undef, N)
    MISC  = Array{Dict{String,Any}}(undef, N)
    for j = 1:N
        MISC[j] = Dict{String,Any}()
    end
    y = 0

    xnet = LightXML_findall(xroot, "Network")
    for net in xnet
        nn = attribute(net, "code")

        xsta = LightXML_findall(net, "Station")
        for sta in xsta
            ss = attribute(sta, "code")
            loc_tmp = zeros(Float64, 3)
            loc_tmp[1] = LightXML_float!(0.0, sta, "Latitude")
            loc_tmp[2] = LightXML_float!(0.0, sta, "Longitude")
            loc_tmp[3] = LightXML_float!(0.0, sta, "Elevation")/1.0e3
            name = LightXML_str!("0.0", sta, "Site/Name")

            xcha = LightXML_findall(sta, "Channel")
            for cha in xcha
                y += 1
                czs = Array{Complex{Float64},1}()
                cps = Array{Complex{Float64},1}()
                ID[y]               = join([nn, ss, attribute(cha,"locationCode"), attribute(cha,"code")],'.')
                NAME[y]             = identity(name)
                FS[y]               = LightXML_float!(0.0, cha, "SampleRate")
                LOC[y]              = zeros(Float64,5)
                LOC[y][1:3]         = copy(loc_tmp)
                LOC[y][4]           = LightXML_float!(0.0, cha, "Azimuth")
                LOC[y][5]           = LightXML_float!(0.0, cha, "Dip") - 90.0
                GAIN[y]             = 1.0
                MISC[y]["normfreq"] = 1.0
                MISC[y]["ClockDrift"] = LightXML_float!(0.0, cha, "ClockDrift")

                xresp = LightXML_findall(cha, "Response")
                if !isempty(xresp)
                    MISC[y]["normfreq"] = LightXML_float!(0.0, xresp[1], "InstrumentSensitivity/Frequency")
                    GAIN[y]             = LightXML_float!(1.0, xresp[1], "InstrumentSensitivity/Value")
                    UNITS[y]            = replace(LightXML_str!("unknown", xresp[1], "InstrumentSensitivity/InputUnits/Name"), "**" => "")

                    xstages = LightXML_findall(xresp[1], "Stage")
                    for stage in xstages
                        pz = LightXML_findall(stage, "PolesZeros")
                        for j = 1:length(pz)
                            append!(czs, [complex(LightXML_float!(0.0, z, "Real"), LightXML_float!(0.0, z, "Imaginary")) for z in LightXML_findall(pz[j], "Zero")])
                            append!(cps, [complex(LightXML_float!(0.0, p, "Real"), LightXML_float!(0.0, p, "Imaginary")) for p in LightXML_findall(pz[j], "Pole")])
                        end
                    end
                end
                NZ = length(czs)
                NP = length(cps)
                if NZ < NP
                    for z = NZ+1:NP
                        push!(czs, complex(0.0,0.0))
                    end
                end
                RESP[y] = hcat(czs,cps)
            end
        end
    end
    return ID, NAME, LOC, FS, GAIN, RESP, UNITS, MISC
end
