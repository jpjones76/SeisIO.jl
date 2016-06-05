using LightXML: attribute, content, root, find_element, get_elements_by_tagname, parse_string, XMLDocument
using Requests: get

function parse_FDSN_xml(xsta::XMLDocument)
  badchars = ['\0', '\ ']
  N = get_elements_by_tagname(root(xsta), "Network")
  ids = Array{ASCIIString,1}()
  units = Array{ASCIIString,1}()
  locs = Array{Float64,2}(5,0)
  normfacs = Array{Float64,1}()
  resps = Array{Array{Complex128,2},1}()
  gains = Array{Float64,1}()

  for n in N
    net = attribute(n, "code")
    S = get_elements_by_tagname(n, "Station")
    for s in S
      # t = u2d(attribute(s, startDate))
      sta = attribute(s, "code")
      C = get_elements_by_tagname(s, "Channel")

      # lon = parse(content(find_element(s, "Longitude")))
      for c in C
        cha = strip(ascii(join(map(Char, attribute(c, "code")))),badchars)
        ll = strip(ascii(join(map(Char, attribute(c, "locationCode")))),badchars)
        id = join([net,sta,ll,cha],'.')
        loc = zeros(Float64,5,1)
        for (n,i) in enumerate(["Latitude", "Longitude", "Elevation", "Azmiuth", "Dip"])
          el = find_element(c, i)
          if el != nothing
            loc[n] = parse(content(el))
            if i == "Dip"
              loc[n] += 90.0
            end
          end
        end

        resp = find_element(c,"Response")
        gain = parse(content(find_element(find_element(resp,"InstrumentSensitivity"), "Value")))
        stages = get_elements_by_tagname(resp, "Stage")
        normfac = 1.0
        cz = Array{Complex128,1}()
        cp = Array{Complex128,1}()
        for stg in stages
          stgN = parse(attribute(stg, "number"))
          pz = find_element(stg, "PolesZeros")
          if pz != nothing
            if stgN == 1
              push!(units, lowercase(join(map(Char,
                content(find_element(find_element(pz, "InputUnits"),"Name"))))))
            end
            has_tf = find_element(pz,"PzTransferFunctionType")
            if has_tf != nothing
              if content(has_tf) == "LAPLACE (RADIANS/SECOND)"
                normfac *= parse(content(find_element(pz, "NormalizationFactor")))
                zz = get_elements_by_tagname(pz, "Zero")
                pp = get_elements_by_tagname(pz, "Pole")
                for z in zz
                  zr = parse(content(find_element(z, "Real")))
                  zi = parse(content(find_element(z, "Imaginary")))
                  push!(cz, complex(zr,zi))
                end
                for p in pp
                  pr = parse(content(find_element(p, "Real")))
                  pi = parse(content(find_element(p, "Imaginary")))
                  push!(cp, complex(pr,pi))
                end
              end
            end
          end
        end
        NZ = length(cz)
        NP = length(cp)
        if NZ < NP
          for z = NZ+1:NP
            push!(cz, complex(0.0,0.0))
          end
        end
        cresp = hcat(cz,cp)
        locs = cat(2, locs, loc)
        resps = cat(1, resps, Array{Complex128,2}[cresp])
        push!(normfacs, normfac)
        push!(ids, id)
        push!(gains, gain)
      end
    end
  end
  return (ids, units, gains, normfacs, locs, resps)
end

function FDSNprep!(S::SeisData,
  ids::Array{ASCIIString,1},
  units::Array{ASCIIString,1},
  gains::Array{Float64,1},
  normfacs::Array{Float64,1},
  locs::Array{Float64,2},
  resps::Array{Array{Complex128,2},1})

  for i = 1:S.n
    k = find(ids .== S.id[i])
    isempty(k) && continue
    k = k[1]
    S.units[i] = units[k]
    S.gain[i] = gains[k]
    S.loc[i] = vec(locs[:,k])
    S.resp[i] = resps[k]
    note(S, i, string("normfac = ", @sprintf("%.6e",normfacs[k])))
  end
  return S
end

"""
    S = FDSNget(net="NET", sta="STA", loc="LL", cha="CHA", s=StartTime,
                t=EndTime, to=TimeOut, y=true)

Retrieve time series data from an FDSN HTTP server. Returns data in a SeisData
structure.

## Arguments
* `net`, `sta`, `loc`, `cha`: ASCII strings. Wildcards are OK.
* `s`: Start time. See below.
* `t`: End time. See below.
* `to`: Timeout in seconds. [default: 10]
* `Q`: Quality. Uses standard FDSN/IRIS codes.
* `y`: Synchronize the start and end times of all channels and fill all
time gaps.
* See FDSN documentation at http://service.iris.edu/fdsnws/dataselect/1/

### Time Specification
s and t can be real numbers, DateTime objects, or ASCII strings. Strings must
follow the format "yyyy-mm-ddTHH:MM:SS", e.g. `s="2016-03-23T11:17:00"`.

### Time Specification for Backward Fill
Passing an Int or Float64 with keyword `t` sets the mode to backward fill.
Retrieved data begin `t` seconds before `s`. `t` is interpreted as a duration.

* `s=0`: End at start of current minute on your system.
* `s` ∈ {Int, Float64}: `s` is treated as Unix (Epoch) time in seconds.
* `s` ∈ {DateTime, ASCIIString}: Backfill ends at `s`.

### Time Specification for Range Retrieval
Passing a string or DateTime object with keyword `t` sets the mode to range
retrieval. Retrieved data begin at `s` and end at `t`. `s` can be a DateTime
object or ASCIIString.

### Example
* `S = FDSNget(net="CC,UW", sta="SEP,SHW,HSR,VALT", cha="*", t=600)`: Get the
last 10 minutes of data from short-period stations SEP, SHW, and HSR, Mt. St.
Helens, USA.

### Notes
*  `Q="R"` doesn't appear to work with IRIS' server on many near-real-time
requests.

### Some FDSN Servers
* Incorporated Research Institutions for Seismology: http://service.iris.edu/fdsnws/
* Réseau Sismologique et Géodesique Français: http://ws.resif.fr/fdsnws/
* Northern California Earthquake Data Center: http://service.ncedc.org/fdsnws/
* GFZ Potsdam: http://geofon.gfz-potsdam.de/fdsnws/
"""
function FDSNget(; src="IRIS"::ASCIIString,
                   net="UW,CC"::ASCIIString,
                   sta="PALM,TDH,VLL"::ASCIIString,
                   loc="--"::ASCIIString,
                   cha="???"::ASCIIString,
                   q="data"::ASCIIString,
                   Q="B"::ASCIIString,
                   s=0::Union{Real,DateTime,ASCIIString},
                   t=600::Union{Real,DateTime,ASCIIString},
                   v=false::Bool,
                   vv=false::Bool,
                   y=true::Bool,
                   to=10::Real)
  hdr = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.0.1")
  if isa(s, Union{DateTime,ASCIIString}) && isa(t, Union{DateTime,ASCIIString})
    d0 = s
    d1 = t
  else
    d0, d1 = parsetimewin(s, t)
  end
  if src == "IRIS"
    uhead = "http://service.iris.edu/fdsnws/"
  elseif src == "GFZ"
    uhead = "http://geofon.gfz-potsdam.de/fdsnws/"
  elseif src == "RESIF"
    uhead = "http://ws.resif.fr/fdsnws/"
  elseif src == "NCSN"
    uhead = "http://service.ncedc.org/fdsnws/"
  else
    uhead = src
  end
  utail = @sprintf("net=%s&sta=%s&loc=%s&cha=%s&start=%s&end=%s",
                   net, sta, loc, cha, d0, d1)
  station_url = string(uhead, "station/1/query?level=response&", utail)
  data_url = string(uhead, @sprintf("dataselect/1/query?quality=%s&",Q), utail)
  v && println(data_url)

  # Get data
  R = get(data_url, timeout=to, headers=hdr)
  tmp = IOBuffer(R.data)
  S = parsemseed(tmp)

  # Source logging
  usrc = split(uhead, '/', keep=false)
  usrc = "FDSN " * " " * ascii(usrc[startswith(usrc[1],"http") ? 2 : 1])
  for i = 1:S.n
    S.src[1] = usrc
    note(S, i, "Data retrieved in mseed format")
  end

  # Automatically incorporate station information from web XML retrieval
  R = get(station_url, timeout=to, headers=hdr)
  tmp = IOBuffer(R.data)
  ids, units, gains, normfacs, locs, resps = parse_FDSN_xml(parse_string(join(readlines(tmp))))
  FDSNprep!(S, ids, units, gains, normfacs, locs, resps)
  if y
    sync!(S, s=d0, t=d1)
  end
  return S
end
