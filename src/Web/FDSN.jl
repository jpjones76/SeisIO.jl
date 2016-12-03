using LightXML: attribute, content, root, find_element, get_elements_by_tagname, parse_string, XMLDocument
using Requests: get

# =============================================================================
# FDSN station XML parser
# Could use cleaning
function parse_FDSN_xml(xsta::XMLDocument)
  badchars = ['\0', '\ ']
  N = get_elements_by_tagname(root(xsta), "Network")
  ids = Array{String,1}()
  units = Array{String,1}()
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
            loc[n] = parse(Float64, content(el))
            if i == "Dip"
              loc[n] = 90.0-loc[n]
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

# =============================================================================
# FDSNprep!: update a SeisData struct with various pieces of station info
function FDSNprep!(S::SeisData,
  ids::Array{String,1},
  units::Array{String,1},
  gains::Array{Float64,1},
  normfacs::Array{Float64,1},
  locs::Array{Float64,2},
  resps::Array{Array{Complex128,2},1})

  for i = 1:S.n
    k = find(ids .== S.id[i])
    isempty(k) && continue
    k = k[1]
    S.units[i] = units[k]
    S.x[i] .*= (1/gains[k])     # Remove stage 0 gain
    note(S, i, string("Removed stage 0 gain = ", @sprintf("%.5e",gains[k])))
    S.gain[i] = 1.0
    S.loc[i] = vec(locs[:,k])
    S.resp[i] = resps[k]
    #note(S, i, string("normfac = ", @sprintf("%.5e",normfacs[k])))
    S.misc[i]["normfac"] = normfacs[k]
  end
  return S
end

# =============================================================================
"""
FDSNget: CLI for FDSN time-series requests.

    S = FDSNget(net="NN", sta="SSSSS", loc="LL", cha="CCC", s=TS,
                t=TE, to=TO, w=false, y=true)

Retrieve data from an FDSN HTTP server. Returns a SeisData struct. See FDSN documentation at http://service.iris.edu/fdsnws/dataselect/1/

## Possible Keywords
* `net`, `sta`, `loc`, `cha`: Strings. Wildcards OK.
* `s`: Start time (see below)
* `t`: End time (see below)
* `to`: Timeout in seconds
* `Q`: Quality code (FDSN/IRIS). Caution: `Q="R"` fails with many queries
* `w`: Write raw download to file
* `y`: Synchronize start and end times of channels and fill time gaps

### Time Specification
`s` and `t` can be real numbers, DateTime objects, or ASCII strings. Strings must follow the format "yyyy-mm-ddTHH:MM:SS", e.g. `s="2016-03-23T11:17:00"`. Exact behavior depends on the data types of s and t:

``\ \begin{tabular}{ c c l }
\bf{s} & \bf{t} &  \bf{Behavior}
Real     & DateTime & Add `s` seconds to `t` and sort\\
DateTime & Real     & Add `t` seconds to `s` and sort\\
String   &          & Convert `s` \rightarrow DateTime, sort\\
& String   & Convert `t` \rightarrow DateTime, sort\\
Int      & Real     & Read `t`seconds relative to current time\\
\end{tabular}
``

* **Relative fill**: Pass a numeric value to keyword `t` to set end time relative to start time in seconds.
* **Backwards fill**: Specify a negative number for `t` for backwards fill from `s`.

### Example
* `S = FDSNget(net="CC,UW", sta="SEP,SHW,HSR,VALT", cha="*", t=600)`: Get the last 10 minutes of data from short-period stations SEP, SHW, and HSR, Mt. St. Helens, USA.

### Some FDSN Servers
* Incorporated Research Institutions for Seismology, US: http://service.iris.edu/fdsnws/
* Réseau Sismologique et Géodesique Français, FR: http://ws.resif.fr/fdsnws/
* Northern California Earthquake Data Center, US: http://service.ncedc.org/fdsnws/
* GFZ Potsdam, DE: http://geofon.gfz-potsdam.de/fdsnws/
"""
function FDSNget(C::Array{String,1};
  d=','::Char,
  src="IRIS"::String,
  q="data"::String,
  Q="B"::String,
  s=0::Union{Real,DateTime,String},
  t=(-600)::Union{Real,DateTime,String},
  v=false::Bool,
  vv=false::Bool,
  w=false::Bool,
  y=true::Bool,
  si=true::Bool,
  to=10::Real)

  seis = SeisData()
  d0, d1 = parsetimewin(s, t)
  uhead = get_uhead(src)
  for j = 1:1:length(C)
    utail = string(C[j], "&start=", d0, "&end=", d1)
    station_url = string(uhead, "station/1/query?level=response&", utail)
    vv && println("station url = ", station_url)
    data_url = string(uhead, "dataselect/1/query?quality=", Q, "&", utail)
    (v || vv) && println("data url = ", data_url)

    # Get data
    R = get(data_url, timeout=to, headers=webhdr())
    w && savereq(R.data, "mseed", Q[j,:], d0, d1, Q)
    tmp = IOBuffer(R.data)
    S = parsemseed(tmp, v=v, vv=vv)

    # Detailed source logging
    usrc = split(uhead, '/', keep=false)
    usrc = "FDSN " * " " * ascii(usrc[startswith(usrc[1],"http") ? 2 : 1])
    for i = 1:S.n
      note(S, i, usrc)
    end

    # Automatically incorporate station information from web XML retrieval
    if si
      R = get(station_url, timeout=to, headers=webhdr())
      tmp = IOBuffer(R.data)
      ids, units, gains, normfacs, locs, resps = parse_FDSN_xml(parse_string(join(readlines(tmp))))
      FDSNprep!(S, ids, units, gains, normfacs, locs, resps)
    end
    if y
      sync!(S, s=d0, t=d1)
    end
    seis += S
  end
  return seis
end

FDSNget(;
    src="IRIS"::String,
    net="UW,CC"::String,
    sta="PALM,TDH,VLL"::String,
    loc="*"::String,
    cha="*"::String,
    d=','::Char,
    q="data"::String,
    Q="B"::String,
    s=0::Union{Real,DateTime,String},
    t=600::Union{Real,DateTime,String},
    v=false::Bool,
    vv=false::Bool,
    w=false::Bool,
    y=true::Bool,
    si=true::Bool,
    to=10::Real) = FDSNget([string("net=",net,"&sta=",sta,"&loc=",loc,"&cha=",cha)], d=d, src=src, q=q, Q=Q, s=s, t=t, v=v, vv=vv, w=w, y=y, si=si, to=to)

FDSNget(S::String;
  src="IRIS"::String,
  d=','::Char,
  q="data"::String,
  Q="B"::String,
  s=0::Union{Real,DateTime,String},
  t=600::Union{Real,DateTime,String},
  v=false::Bool,
  vv=false::Bool,
  w=false::Bool,
  y=true::Bool,
  si=true::Bool,
  to=10::Real) = FDSNget(SL_parse(S, fdsn=true, delim=d), d=d, src=src, q=q, Q=Q, s=s, t=t, v=v, vv=vv, w=w, y=y, si=si, to=to)
