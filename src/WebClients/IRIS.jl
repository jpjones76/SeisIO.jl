using Requests.get

"""
    S = irisws(net="NET", sta="STA", loc="LL", cha="CHA", s=StartTime, t=Duration)

Single-channel data retrieval from IRIS http server: station STA, channel CHA,
network NET, location LOC. S is a SeisData structure.

## Arguments
* `net`, `sta`, `loc`, `cha`, `fmt`: ASCII strings.
  Defaults: `net="UW", sta="TDH", loc="--", cha="EHZ", fmt="sacbl"`.
* `s`: Either start time for backwards fill (correctly, specifies when time
  series ends) or IRIS-compliant datetime string for data start time. See below
  for options and behaviors.
* `t`: Duration in seconds [default: 3600] or IRIS-compliant datetime string
for data end time. See below for options and behaviors.
* `pr`: Prune SAC headers to non-empty values. [default: true]
* `to`: Timeout in seconds. [default: 10]
* See also IRISWS documentation at http://service.iris.edu/irisws/timeseries/1/

### Time Specification for Backwards Fill
If `t`::Union{Int,Float64}:

* `t` is duration in seconds. Extraction begins `t` seconds before `s`.
* `s=0`: End at start of current minute on your system.
* `s` Int or Float64: Treated as Unix (Epoch) time from 1-1-1970.
* `s` DateTime or String: End at `s`. Expected format is
"yyyy-mm-ddTHH:MM:SS", e.g. "2006-03-23T11:17:00".

### Time Specification for Range Retrieval
 If `t`::Union{DateTime,String}:

* `s` DateTime or String: Data are retrieved from `s` to `t`.
* String values for `s` and `t` should be formatted
Expected string format is "yyyy-mm-ddTHH:MM:SS", e.g. `s="2006-03-23T11:17:00"`,
`t="2006-03-24T01:00:00"`.
* String: Guess start time by converting s with DateTime. Expected
format is yyyy-mm-ddTHH:MM:SS, e.g. "2006-03-23T11:17:00".

### Examples
* `S = irisws(net="CC", sta="PALM", cha="EHN", t=120)`: Get two minutes of data
from component EHN, station TIMB, network CC (Cascade Volcano Observatory),
up to (roughly) the beginning of the current minute.
* `S = irisws(net="HV", sta="MOKD", cha="HHZ", s="2012-01-01T00:00:00", t=3600)`:
Get an hour of data ending at 2012-01-01, 00:00:00 UTC, from component HHZ,
station MOKD, network HV (Hawai'i Volcano Observatory).
* `S = irisws(net="CC", sta="TIMB", cha="EHZ", t=600, fmt="miniseed")`: Get
the last 10 minutes of data from CC.TIMB.EHZ (Cascade Volcano Observatory,
Timberline Lodge, OR, US) in miniseed format.

### Notes
* Traces are de-meaned and the stage zero gain is removed; however, instrument response is not translated.

"""
function irisws(;net="UW", sta="TDH", loc="--", cha="EHZ", fmt="sacbl",
                s=0, t=3600, v=false::Bool, to=10)
  hdr = Dict("UserAgent" => "Julia-IRISget/0.0.1")
  d0, d1 = parsetimewin(s, t)
  URLbase = "http://service.iris.edu/irisws/timeseries/1/query?"
  URLtail = @sprintf("net=%s&sta=%s&loc=%s&cha=%s&starttime=%s&endtime=%s&scale=AUTO&demean=true&output=%s",
                      net, sta, loc, cha, d0, d1, fmt)
  url = string(URLbase,URLtail)
  v && println(url)
  req = get(url, timeout=to, headers=hdr)
  if fmt == "sacbl"
    tmp = IOBuffer(req.data)
    D = prunesac(psac(tmp))
    D["src"] = "irisws/timeseries"
    return D
  elseif fmt == "miniseed"
    tmp = IOBuffer(req.data)
    S = parsemseed(tmp, v=v)
    S.src[1] = "irisws/timeseries"
    note(S, 1, "Data retrieved in mseed format")
    return S
  else
    if v
      warn(@sprintf("Unusual format spec; returning unparsed data stream in format=%s",fmt))
    end
    return req.data
  end
end

"""
    S = IRISget(chanlist)

Get (up to) the last hour of IRIS near-real-time data from every channel in
chanlist.

    S = IRISget(chanlist, s=StartTime, t=EndTime)

Get synchronized trace data from the IRIS http server, resampled to the lowest
rate of any channel in chanlist for which data exists.

    S = IRISget(chanlist, s=StartTime, t=Duration, sync=false, v=0, to=5)

Get desynchronized trace data (not resampled) from IRIS http server with a 5-
second timeout on HTTP requests.

## Arguments
* `chanlist`: Array of channel identification strings, formated either
  [net].[sta].[chan] or [net]\_[sta]\_[chan].
* `s`: Either an end time (for backwards fill) or a start time (for range
  retrieval). See below for allowed types and specifications.
* `t`: Either duration in seconds [default: 3600] (for backwards fill) or an
  end time (for range retrieval). See below for types and specifications.
* `v`: Verbosity.
* `to`: Timeout in seconds. [default: 10]

### Time Specification for Backwards Fill
If `t`::Union{Int,Float64}:

* `t` is duration in seconds. Extraction begins `t` seconds before `s`.
* `s=0`: End at start of current minute on your system.
* `s` Int or Float64: Treated as Unix (Epoch) time from 1-1-1970.
* `s` DateTime or String: End at `s`. Expected format is
"yyyy-mm-ddTHH:MM:SS", e.g. "2006-03-23T11:17:00".

### Time Specification for Range Retrieval
 If `t`::Union{DateTime,String}:

* `s` DateTime or String: Data are retrieved from `s` to `t`.
* String values for `s` and `t` should be formatted yyyy-mm-ddTHH:MM:SS,
e.g. `s="2006-03-23T11:17:00"`, `e="2006-03-24T01:00:00"`.

## Output
IRISget returns a SeisData structure.

### Examples
1. `c = ["UW.TDH.EHZ"; "UW.VLL.EHZ"; "CC.TIMB.EHZ"]; seis = IRISget(c, t=3600)`:
Retrieve the last hour of data from the three named short-period vertical
channels (on and near Mt. Hood, OR).
2. `seis = IRISget(["HV.MOKD.HHN"; "HV.WILD.HNN"], s="2016-04-04T00:00:00",
t="2016-04-04T00:10:00",v=3);` : Retrieve an hour of data beginning at
00:00:00 UTC, 2016-04-04, from the two named N-S channels of Mauna Loa broadbands.

### Notes
* Traces are de-meaned and the stage zero gain is removed; however, instrument response is not translated.
* The IRIS web server doesn't provide station coordinates.
* Wildcards in the channel list are not supported.

"""
function IRISget(chanlist; s=0, t=3600, sync=true::Bool, v=false::Bool, to=10::Real)
  d0, d1 = parsetimewin(s, t)
  dt = d2u(d1)-d2u(d0)
  if length(chanlist)*dt > 1.0e7
    error("Request too large! Please limit requests to K*t < 1.0e7 seconds")
  elseif v
    @printf("Requesting %i seconds of data from %i channels.\n", dt,
            length(chanlist))
  end
  cdim = size(chanlist)
  if length(cdim) > 1
    error("typeof(chanlist) != Array{String,1}!")
  else
    K = cdim[1]
  end
  global seis = SeisData()
  v && println("IRIS web fetch begins...")
  killflag = falses(K)
  for k = 1:1:K
    c = split(chanlist[k],['.','_'])
    try
      S = irisws(net=c[1], sta=c[2], loc="--", cha=c[3], fmt="miniseed", s=d0, t=d1, v=v, to=to)
      push!(seis, S[1])
    catch
      warn(@sprintf("Couldn't retrieve %s in specified time window (%s -- %s)!\n", chanlist[k], d0, d1))
    end
  end
  if sync
    v && println("Synchronizing data now...")
    sync!(seis, s=d0, t=d1)
  end
  return seis
end
