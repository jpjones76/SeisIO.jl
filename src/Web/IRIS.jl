"""
irisws: CLI for single-channel IRIS time-series web requests

    S = irisws(CHAN_ID, s=t1, t=t2)

Retrieve data at times `t1 < t < t2` from the IRIS http server from channel `CHAN_ID`, formatted NET.STA.LOC.CHA (e.g. "PB.B004.01.BS1"); leave `LOC` field blank to set to "--" (e.g. "UW.ELK..EHZ").

## Allowed Keywords
* `s`, `t`: Time window specifiers. See `?parsetimewin` for details.
* `to`: Timeout in seconds.
* `w`: Write to file in current directory

### Examples
* `S = irisws("CC.PALM..ENH", t=(-120))`: Get two minutes of data from component EHN, station TIMB, network CC (Cascade Volcano Observatory, USGS), up to (roughly) the beginning of the current minute.
* `S = irisws("HV.MOKD..HHZ", s="2012-01-01T00:00:00", t=(-3600))`: get an hour of data ending at 2012-01-01, 00:00:00 UTC, from component HHZ, station MOKD, network HV (Hawai'i Volcano Observatory).
* `S = irisws("CC.TIB..EHZ", t=(-600), fmt="mseed")`: Get the last 10 minutes of data from Cascade Volcano Observatory, Timberline Lodge, OR, US, in miniseed format.

### Notes
* Stage zero gains are removed from traces, but instrument responses are otherwise unchanged.
* See IRISWS documentation at http://service.iris.edu/irisws/timeseries/1/

"""
function irisws(cha::String;
  fmt="sacbl"::String,
  w=false::Bool,
  s=0::Union{Real,DateTime,String},
  t=(-3600)::Union{Real,DateTime,String},
  v=0::Int,
  to=30::Real)

  if fmt == "mseed"
    fmt = "miniseed"
  end

  d0, d1 = parsetimewin(s, t)
  c = (parse_chstr(cha)[1,:])[1:min(end,4)]
  if isempty(c[3])
    c[3] = "--"
  end


  URLbase = "http://service.iris.edu/irisws/timeseries/1/query?"
  URLtail = build_stream_query(c,d0,d1)*"&scale=AUTO&output="*fmt
  url = string(URLbase,URLtail)
  v>0 && println(url)
  seis = SeisData()
  req = get(url, timeout=to, headers=webhdr())
  if req.status == 200
    if w
      savereq(req.data, fmt, c[1], c[2], c[3], c[4], d0, d1, "R")
    end
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
  else
    warn("Request could not be completed! Text dump follows:")
    println(STDOUT, String(req.data))
    seis = SeisChannel()
    c[3] = strip(c[3],'-')
    setfield!(seis, :id, join(c, '.'))
  end
  return seis
end

"""
IRISget: CLI for IRIS time-series web requests

    S = IRISget(C)

Get (up to) the last hour of IRIS near-real-time data from every channel in C.

    S = IRISget(C, s=StartTime, t=EndTime)

Get synchronized trace data from the IRIS http server.

    S = IRISget(C, s=StartTime, t=Duration, y=false, v=0, to=5, w=false)

Get desynchronized trace data from IRIS http server with a 5-second timeout on HTTP requests.

## Arguments
* `C`: Type `?chanspec` for details.
* `s`, `t`: Time window bounds. See `?parsetimewin` for details.
* `v`: Verbosity
* `w`: Write downloaded data directly to file in the current directory
* `to`: Timeout in seconds. [default: 10]

### Examples
1. `c = ["UW.TDH..EHZ", "UW.VLL..EHZ", "CC.TIMB..EHZ"]; seis = IRISget(c, t=(-3600))`: Retrieve the last hour of data from the three named short-period vertical channels (on and near Mt. Hood, OR).
2. `seis = IRISget(["HV.MOKD..HHN", "HV.WILD..HNN"], s="2016-04-04T00:00:00", t="2016-04-04T00:10:00",v=2);` : Retrieve an hour of data beginning at 00:00:00 UTC, 2016-04-04, from two N-S channels of Mauna Loa broadband seismometers.

### Notes
* Traces are de-meaned and stage zero gains are removed, but instrument responses are otherwise unchanged.
* The IRIS web server doesn't provide station coordinates.
* Wildcards in channel IDs are not supported.

"""
function IRISget(C::Array{String,1};
  s=0::Union{Real,DateTime,String},
  t=(-3600)::Union{Real,DateTime,String},
  y=false::Bool,
  v=0::Int,
  w=false::Bool,
  to=30::Real)

  K = length(C)
  d0, d1 = parsetimewin(s, t)
  dt = (DateTime(d1)-DateTime(d0)).value
  if length(C)*dt > 1.0e10
    error("Request too large! Please limit requests to #_channels*t_seconds < 1.0e10")
  elseif v>0
    @printf("Requesting %i seconds of data from %i channels.\n", dt, length(C))
  end

  seis = SeisData()
  v>0 && println("IRIS web fetch begins...")
  for k = 1:1:K
    seis += irisws(C[k], fmt="mseed", s=d0, t=d1, v=v, to=to, w=w)
  end
  if y == true
    v>0 && println("Synchronizing data now...")
    sync!(seis, s=d0, t=d1)
  end
  return seis
end

# C passed as a string
IRISget(C::String; s=0::Union{Real,DateTime,String}, t=3600::Union{Real,DateTime,String}, y=false::Bool, v=0::Int, w=false::Bool, to=10::Real) = IRISget(map(String, split(C, ',')), s=s, t=t, y=y, v=v, w=w, to=to)

# C passed as a 2d array
IRISget(C::Array{String,2}; s=0::Union{Real,DateTime,String}, t=(-3600)::Union{Real,DateTime,String}, y=false::Bool, v=false::Bool, w=false::Bool, to=10::Real) = IRISget([join(C[i,:],'.') for i = 1:size(C,1)], s=0::Union{Real,DateTime,String}, t=(-3600)::Union{Real,DateTime,String}, y=false::Bool,  v=0::Int, w=false::Bool, to=10::Real)


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
