using Requests.get

# =============================================================================
"""
irisws: CLI for single-channel IRIS time-series web requests

    S = irisws(net="NET", sta="STA", loc="LL", cha="CHA", s=StartTime, t=Duration, w=false)

Retrieves data from a single channel from an IRIS http server at station STA, channel CHA, network NET, location LL. Returns a SeisData struct.

## Arguments
* `net`, `sta`, `loc`, `cha`, `fmt`: ASCII strings. No wildcards!
* `s`: Start time. See below for options and behaviors.
* `t`: Duration in seconds or data end time. See below for options and behaviors.
* `to`: Timeout in seconds.
* `w`: Write to file in current directory
* See also IRISWS documentation at http://service.iris.edu/irisws/timeseries/1/

### Time Specification
`s` and `t` can be real numbers, DateTime objects, or ASCII strings. Strings must follow the format "yyyy-mm-ddTHH:MM:SS", e.g. `s="2016-03-23T11:17:00"`. Exact behavior depends on the data types of s and t: (R = Real, DT = DateTime, S = String, I = Integer)

| **s** | **t** | **Behavior**                         |
|:------|:------|:-------------------------------------|
| R     | DT    | Add `s` seconds to `t`, then sort    |
| R, DT | R     | Add `t` seconds to `s`, then sort    |
| S     | R, DT | Convert `s` → DateTime, then sort    |
| R, DT | S     | Convert `t` → DateTime, then sort    |
| R     | R     | `s` is seconds relative to `now()`   |
|       |       | `t` is seconds from `s`              |

### Examples
* `S = irisws(net="CC", sta="PALM", cha="EHN", t=120)`: Get two minutes of data from component EHN, station TIMB, network CC (Cascade Volcano Observatory, USGS), up to (roughly) the beginning of the current minute.
* `S = irisws(net="HV", sta="MOKD", cha="HHZ", s="2012-01-01T00:00:00", t=3600)`: get an hour of data ending at 2012-01-01, 00:00:00 UTC, from component HHZ,
station MOKD, network HV (Hawai'i Volcano Observatory).
* `S = irisws(net="CC", sta="TIMB", cha="EHZ", t=600, fmt="mseed")`: Get the last 10 minutes of data from CC.TIMB.EHZ (Cascade Volcano Observatory, Timberline Lodge, OR, US) in miniseed format.

### Notes
* Traces are de-meaned and stage zero gains are removed, but instrument responses are otherwise unchanged.

"""
function irisws(;net="UW"::String,
  sta="TDH"::String,
  loc="--"::String,
  cha="EHZ"::String,
  fmt="sacbl"::String,
  w=false::Bool,
  s=0::Union{Real,DateTime,String},
  t=(-3600)::Union{Real,DateTime,String},
  v=0::Int,
  to=10::Real)

  if fmt == "mseed"
    fmt = "miniseed"
  end

  d0, d1 = parsetimewin(s, t)
  URLbase = "http://service.iris.edu/irisws/timeseries/1/query?"
  URLtail =  @sprintf("net=%s&sta=%s&loc=%s&cha=%s&starttime=%s&endtime=%s&scale=AUTO&demean=true&output=%s", net, sta, loc, cha, d0, d1, fmt)
  url = string(URLbase,URLtail)
  v>0 && println(url)
  seis = SeisData()
  req = get(url, timeout=to, headers=webhdr())
  if req.status == 200
    w && savereq(req.data, fmt, net, sta, loc, cha, d0, d1, "R", c=true)
    if fmt == "sacbl"
      seis += read_sac_stream(IOBuffer(req.data))
      seis.src[1] = url
      note!(seis, "+src: irisws "*url)
    elseif fmt == "miniseed"
      seis += parsemseed(IOBuffer(req.data), false, v)[1]
      seis.src[1] = url
      note!(seis, "+src: irisws "*url)
    else
      if v
        warn(@sprintf("Unusual format spec; returning unparsed data stream in format=%s",fmt))
      end
      seis = req.data
    end
  end
  return seis
end

# =============================================================================
""""
IRISget: CLI for arbitrary IRIS time-series web requests

    S = IRISget(chanlist)

Get (up to) the last hour of IRIS near-real-time data from every channel in chanlist.

    S = IRISget(chanlist, s=StartTime, t=EndTime)

Get synchronized trace data from the IRIS http server.

    S = IRISget(chanlist, s=StartTime, t=Duration, y=false, v=0, to=5, w=false)

Get desynchronized trace data from IRIS http server with a 5-second timeout on HTTP requests.

## Arguments
* `chanlist`: Array of channel identification strings, formated either [net].[sta].[chan] or [net]\_[sta]\_[chan]
* `s`: Either an end time (for backwards fill) or a start time (for range retrieval). See below for allowed types and specifications
* `t`: Either duration in seconds [default: 3600] (for backwards fill) or an end time (for range retrieval). See below for types and specifications
* `v`: Verbosity
* `w`: Write downloaded data to file in the current directory
* `to`: Timeout in seconds. [default: 10]

### Examples
1. `c = ["UW.TDH.EHZ"; "UW.VLL.EHZ"; "CC.TIMB.EHZ"]; seis = IRISget(c, t=3600)`: Retrieve the last hour of data from the three named short-period vertical channels (on and near Mt. Hood, OR).
2. `seis = IRISget(["HV.MOKD.HHN"; "HV.WILD.HNN"], s="2016-04-04T00:00:00", t="2016-04-04T00:10:00",v=3);` : Retrieve an hour of data beginning at 00:00:00 UTC, 2016-04-04, from the two named N-S channels of Mauna Loa broadbands.

### Notes
* Traces are de-meaned and stage zero gains are removed, but instrument responses are otherwise unchanged.
* The IRIS web server doesn't provide station coordinates.
* Wildcards in the channel list are not supported.

"""
function IRISget(chanlist::Array{String,1};
  s=0::Union{Real,DateTime,String},
  t=(-3600)::Union{Real,DateTime,String},
  y=true::Bool,
  v=0::Int,
  w=false::Bool,
  to=10::Real)

  K = length(chanlist)
  d0, d1 = parsetimewin(s, t)
  dt = (DateTime(d1)-DateTime(d0)).value
  if length(chanlist)*dt > 1.0e13
    error("Request too large! Please limit requests to K*t < 1.0e7 seconds")
  elseif v>0
    @printf("Requesting %i seconds of data from %i channels.\n", dt,            length(chanlist))
  end

  # was: global seis = SeisData() ... if there are errors, revert
  seis = SeisData()
  v>0 && println("IRIS web fetch begins...")
  killflag = falses(K)
  for k = 1:1:K
    c = split(chanlist[k],['.','_'])
    if length(c) == 4
      LL = String(c[3])
      CCC = String(c[4])
    else
      LL = "--"
      CCC = String(c[3])
    end
    try
      seis += irisws(net=String(c[1]), sta=String(c[2]), loc=LL, cha=CCC, fmt="mseed", s=d0, t=d1, v=v, to=to, w=w)
    catch
      warn(@sprintf("Couldn't retrieve %s in specified time window (%s -- %s)!\n", chanlist[k], d0, d1))
    end
  end
  if y == true
    v>0 && println("Synchronizing data now...")
    sync!(seis, s=d0, t=d1)
  end
  return seis
end

# Chanlist passed as a string
IRISget(chanlist::String; s=0::Union{Real,DateTime,String}, t=3600::Union{Real,DateTime,String}, y=true::Bool, v=0::Int, w=false::Bool, to=10::Real) = IRISget(split(chanlist,','), s=s, t=t, y=y, v=v, w=w, to=to)

# Chanlist passed as an array
IRISget(chanlist::Array{String,2}; s=0::Union{Real,DateTime,String}, t=(-3600)::Union{Real,DateTime,String},  y=true::Bool, v=false::Bool, w=false::Bool, to=10::Real) = IRISget([join(chanlist[i,:],'.') for i = 1:size(chanlist,1)], s=0::Union{Real,DateTime,String}, t=(-3600)::Union{Real,DateTime,String}, y=true::Bool,  v=0::Int, w=false::Bool, to=10::Real)


"""
    T = get_pha(Δ::Float64, z::Float64)

Command-line interface to IRIS online travel time calculator, which calls TauP (1-3). Returns a matrix of strings.

Specify `Δ` in decimal degrees, `z` in km.

### Keyword Arguments and Default Values
* `pha="ttall"`: comma-separated string of phases to return, e.g. "P,S,ScS"
* `model="iasp91"`: velocity model
* `to=10.0`: ste web request timeout, in seconds
* `v=0`: verbosity

### References
(1) IRIS travel time calculator: https://service.iris.edu/irisws/traveltime/1/
(2) TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf
(3) Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit:
Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.
"""
function get_pha(Δ::Float64, z::Float64;
  phases=""::String,
  model="iasp91"::String,
  to=10.0::Real,
  v=0::Int)

  # Generate URL and do web query
  if isempty(phases)
    #pq = ""
    #pq = "&phases=p,s,P,S,pS,PS,sP,SP,Pn,Sn,PcP,Pdiff,Sdiff,PKP,PKiKP,PKIKP"
    pq = "&phases=ttall"
  else
    pq = string("&phases=", phases)
  end

  url = string("http://service.iris.edu/irisws/traveltime/1/query?", "distdeg=", Δ, "&evdepth=", z, pq, "&model=", model, "&mintimeonly=true&noheader=true")
  v > 0 && println(STDOUT, "url = ", url)
  R = get(url, timeout=to, headers=webhdr())
  if R.status == 200
    req = readall(R)
    v > 0 && println(STDOUT, "Request result:\n", req)

    # Parse results
    phase_data = split(req, '\n')
    sa_prune!(phase_data)
    Nf = length(split(phase_data[1]))
    Np = length(phase_data)
    Pha = Array{String,2}(Np, Nf)
    for p = 1:Np
      Pha[p,1:Nf] = split(phase_data[p])
    end
  else
    Pha = Array{String,2}(0, 0)
  end
  return Pha
end
