using LightXML: attribute, content, root, find_element, get_elements_by_tagname, parse_string, XMLDocument
using Requests: get

#function parse_FDSN_xml(xsta::Union{HttpCommon.Response,LightXML.XMLDocument})
  #if typeof(xsta) == HttpCommon.Response
  #  xsta = LightXML.parse_string(join(readlines(IOBuffer(xsta.data))))
  #end
function parse_FDSN_xml(xsta::XMLDocument)
  N = get_elements_by_tagname(root(xsta), "Network")
  sinfo = Array{Union{ASCIIString,Float64},2}(0,5)
  for n in N
    net = attribute(n, "code")
    S = get_elements_by_tagname(n, "Station")
    for s in S
      sta = attribute(s, "code")
      C = get_elements_by_tagname(s, "Channel")
      lat = parse(content(find_element(s, "Latitude")))
      lon = parse(content(find_element(s, "Longitude")))
      ele = parse(content(find_element(s, "Elevation")))
      for c in C
        cha = attribute(c, "code")
        sk = ones(UInt8,12)*0x20
        L = length(sta)
        LL = length(cha)
        sk[1:L] = sta.data
        sk[8:8+LL-1] = cha.data
        sk[11:12] = net.data
        sk = join(map(Char,sk))
        gain = parse(content(find_element(find_element(find_element(c,
                     "Response"),"InstrumentSensitivity"), "Value"))) # really?
        sinfo = cat(1, sinfo, [sk gain lat lon ele])
       end
    end
  end
  return sinfo
end

function FDSNprep!(S::SeisData, sinfo::Array{Any,2})
  sn = sinfo[:,1]
  for i = 1:S.n
    k = find(sn .== S.name[i])
    isempty(k) && continue
    k = k[1]
    S.gain[i] = sinfo[k,2]
    S.loc[i] = vec([sinfo[k,3:5] 0 0])
  end
  return S
end

"""
    S = FDSNget(net="NET", sta="STA", loc="LL", cha="CHA", s=StartTime,
                t=EndTime, to=TimeOut, do_filt=true, do_sync=true)

Retrieve time series data from an FDSN HTTP server. Returns data in a SeisData
structure.

## Arguments
* `net`, `sta`, `loc`, `cha`: ASCII strings. Wildcards are OK.
* `s`: Start time. See below.
* `e`: End time. See below.
* `to`: Timeout in seconds. [default: 10]
* `s`: Start time. See below.
* `t`: End time. See below.
* `Q`: Quality. Uses standard FDSN/IRIS codes.
* `do_filt`: Demean, cosine taper, and highpass filter all data. Specify corner
frequency FC as a float by passing `f=FC`.
* `do_sync`: Synchronize the start and end times of all channels and fill all
time gaps.
* See FDSN documentation at http://service.iris.edu/fdsnws/station/1/

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
* Incorporated Research Institutions for Seismology: http://service.ncedc.org/fdsnws/
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
                   do_sync=true::Bool,
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
  #elseif src == "IPGP" # Meta-data only
  # uhead = "http://eida.ipgp.fr/fdsnws/"
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

  # Automatically incorporate station information from web XML retrieval
  R = get(station_url, timeout=to, headers=hdr)
  tmp = IOBuffer(R.data)
  sinfo = parse_FDSN_xml(parse_string(join(readlines(tmp))))
  FDSNprep!(S, sinfo)
  if do_sync
    sync!(S)
  end
  return S
end
