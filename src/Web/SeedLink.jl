using LightXML: attribute, root, get_elements_by_tagname, parse_string, XMLDocument
using Requests: get
using SeisIO

#cmatch(xel, pat, tag) = prod([contains(attribute(xel,tag[i]),pat[i]) for i=1:length(pat)])

"""
    info_xml = SLinfo(level=LEVEL::String, addr=URL::String, port=PORT::Integer)

    Retrieve XML output of SeedLink command "INFO `LEVEL`" from server `URL:PORT`. Returns formatted XML.

    `LEVEL` must be one of "ID", "CAPABILITIES", "STATIONS", "STREAMS", "GAPS", "CONNECTIONS", "ALL".

"""
function SLinfo(;level="STATIONS"::String,                  # level
                addr="rtserve.iris.washington.edu"::String, # url
                port=18000::Integer                         # port
                )
  conn = connect(TCPSocket(),addr,port)
  write(conn, string("INFO ", level, "\r"))
  eof(conn)
  B = takebuf_array(conn.buffer)
  N = length(B)
  while (Char(B[end]) != '\0' || rem(N,520) > 0)
    eof(conn)
    append!(B, takebuf_array(conn.buffer))
    N = length(B)
  end
  close(conn)
  buf = IOBuffer(N)
  write(buf, B)
  seekstart(buf)
  xml_str = ""
  while !eof(buf)
    skip(buf, 64)
    xml_str *= join(map(x -> Char(x), read(buf, UInt8, 456)))
  end
  return parse_string(replace(xml_str,"\0",""))
end

function check_sta_exists(sta::Array{String,1}, xml_p::XMLDocument)
  N = length(sta)
  x = falses(N)
  sta_list = [join([attribute(x, "name"), attribute(x, "network")], " ") for x in get_elements_by_tagname(root(xml_p), "station")]
  for i = 1:1:N
    if findfirst(sta_list .== sta[i]) > 0
      x[i] = 1
    end
  end
  return x
end

"""
    X = has_sta(sta::Array{String,1}, url)

    Check that stations in `sta` are available via SeedLink from `url`.
"""
has_sta(sta::Array{String,1}, url::String; port=18000::Integer) = check_sta_exists(sta, SLinfo(level="STATIONS", addr=url, port=port))
has_sta(sta::String, url::String; port=18000::Integer) = has_sta([sta], url, port=port)

function has_stream(sta::Array{String,1}, patts::Array{String,1}, url::String;
  port=18000::Integer,
  to=1800::Real)

  tag = ["seedname","location","type"]

  xdoc = SLinfo(level="STREAMS", addr=url, port=port)
  xstreams = get_elements_by_tagname(root(xdoc), "station")
  L = length(xstreams)
  ids = Array{String,1}(L)
  for i = 1:1:L
    ids[i] = string(attribute(xstreams[i], "name")," ",attribute(xstreams[i], "network"))
  end
  N = length(sta)
  x = falses(N)
  for i = 1:1:N
    # Assumes the combination of network name and station name is unique
    K = findfirst(ids .== sta[i])
    if K > 0
      (lc,d) = split(patts[i],'.')

      # Syntax requires that contains(string, "") returns true for any string
      ll = replace(lc[1:2],"?","")
      cc = replace(lc[3:5],"?","")
      pat = [cc, ll, d]

      t = Inf
      streams = get_elements_by_tagname(xstreams[K], "stream")
      if !isempty(streams)
        S = length(streams)
        for j = 1:1:S
          xel = streams[j]
          if prod([contains(attribute(xel,tag[i]),pat[i]) for i=1:length(pat)])
            tstr = replace(string(attribute(xel,"end_time"))," ","T")
            t = min(t, time()-d2u(Dates.DateTime(tstr)))
          end
        end
      end

      # Treat station as "present" if there's a match
      if minimum(t) < to
        x[i] = true
        break
      end
    end
  end
  return x
end

function getSLver(vline::String)
  # Versioning will break if SeedLink switches to VV.PPP.NNN format
  ver = 0.0
  vinfo = split(vline)
  for i in vinfo
    if startswith(i, 'v')
      try
        ver = parse(i[2:end])
        return ver
      end
    end
  end
end

"""
    C = SeedLink!(S, sta)

Begin acquiring SeedLink data to SeisData structure `S` via connection `C`. New channels are added to `S` automatically based on `sta`.

    (C,S) = SeedLink(sta)

Create a new SeisData structure `S` to acquire SeedLink data via `C`.

### INPUTS
* `S`: SeisData object
* `sta`: Array{String, 1} formatted ["SSSSS NN"], e.g. ["GPW UW", "HIYU CC"].

### OUPUTS
* `C`: Connection (TCPSocket)

*Note*: When finished, close connection manually with `close(C)`. If `w=true`, the next attempted packet dump after closing `C` will close the output file.

### KEYWORD ARGUMENTS
Specify as `kw=value`, e.g., `SeedLink!(S, sta, mode="TIME", r=120)`.

| Name   | Default | Type            | Description                      |
|:-------|:--------|:----------------|:---------------------------------|
| addr   | (iris)  | String          | url, no "http://"                |
| port   | 18000   | Integer         | port number                      |
| patts  | ["*"]   | Array{String,1} | channel/loc/data strings (2)     |
| mode   | "DATA"  | String          | TIME, DATA, or FETCH             |
| a      | 600     | Real            | keepalive interval [s]           |
| f      | 2       | Int             | safety check level (3)           |
| g      | 3600    | Real            | max. gap since last packet [s]   |
| r      | 60      | Real            | base refresh interval [s]        |
| s      | 0       | (1)             | start time (TIME or FETCH only)  |
| t      | 300     | (1)             | end time (TIME only)             |
| strict | true    | Bool            | strict mode exits on any error   |
| v      | 0       | Int             | verbosity                        |
| w      | false   | Bool            | write raw packets to disk? (6)   |

(1) Type `?parsetimewin` for time window syntax help
(2) If `length(patt) < length(sta)`, `patt[end]` is repeated to `length(sta)`
(3) 1 = check if stations exist at `addr`; 2 = check for recent data at `addr`
(4) A stream with no data for `g` seconds is considered offline if `f=2`.
(5) File name is auto-generated. Each `SeedLink!` call uses a unique file.
"""
function SeedLink!(S::SeisData,
  sta::Array{String,1};                               # net/sta
  addr="rtserve.iris.washington.edu"::String,         # url
  port=18000::Integer,                                # port
  patts=["*"]::Array{String,1},                       # channel/loc/data
  mode="DATA"::String,                                # SeedLink mode
  a=600::Real,                                        # keepalive interval (s)
  f=2::UInt8,                                         # safety check level
  g=3600::Real,                                       # maximum gap
  r=60::Real,                                         # refresh interval (s)
  s=0::Union{Real,DateTime,String},                   # start (time/dialup mode)
  t=300::Union{Real,DateTime,String},                 # end (time mode only)
  strict=true::Bool,                                  # strict (exit on errors)
  v=0::UInt8,                                         # verbosity level
  w=false::Bool)


  # ==========================================================================
  # init, warnings, sanity checks

  # Refresh interval
  r = maximum([r, eps()])
  r < 10 && warn(string("r = ", r, " < 10 s; Julia may freeze if no packets arrive between consecutive read attempts."))

  # keepalive interval
  a < 240 && warn("KeepAlive interval increased to 240s as per IRIS netiquette guidelines.")
  a = maximum([a, 240])

  # misc init
  Ns = length(sta)
  Np = length(patts)
  if patts[1] == "*"
    patts = fill("?????.D", Ns)
  elseif Np < Ns
    patts[Np+1:end] = patts[Np]
  end

  if f==2
    v>0 && println("Checking for recent matching streams (may take 60 s)...")
    h = has_stream(sta, patts, addr, port=port, g=g)
  elseif f==1
    v>0 && println("Checking that request exists (may take 60 s)...")
    h = has_sta(sta, addr, port=port)
  else
    h = trues(Ns)
  end

  for i = Ns:-1:1
    if !h[i]
      warn(string(addr, " doesn't currently have ", sta[i], "; deleted from req."))
      deleteat!(sta, i)
      deleteat!(patts,i)
    end
  end

  Ns = length(sta)
  if Ns == 0
    warn("No channels in the current request were found. Exiting SeedLink!...")
    return 0
  end

  # Source for logging
  src = join(["SeedLink!", timestamp(), join([addr,port],':')],',')

  # ==========================================================================
  # connection and server info retrieval
  conn = connect(TCPSocket(),addr,port)

  # version, server info
  write(conn,"HELLO\r")
  vline = readline(conn)
  sline = readline(conn)
  ver = getSLver(vline)

  # version-based compatibility checks (unlikely that such a server exists)
  if ver < 2.5 && length(sta) > 1
    error(@sprintf("Multi-station mode unsupported in SeedLink v%.1f", ver))
  elseif ver < 2.92 && mode == "TIME"
    error(@sprintf("Mode \"TIME\" not available in SeedLink v%.1f", ver))
  end
  (v > 1) && println("Version = ", ver)
  (v > 1) && println("Server = ", strip(sline,['\r','\n']))
  # ==========================================================================

  # ==========================================================================
  # handshaking

  # create mode string and filename for -w
  (d0,d1) = parsetimewin(s,t)
  s = join(split(d0,r"[\-T\:\.]")[1:6],',')
  t = join(split(d1,r"[\-T\:\.]")[1:6],',')
  if mode in ["TIME", "FETCH"]
    if mode == "TIME"
      if (DateTime(d1)-u2d(time())).value < 0
        warn("End time < time() in TIME mode; SeedLink will receive no data!")
      end
      m_str = string("TIME ", s, " ", t, "\r")
    else
      m_str = string("FETCH ", s, "\r")
    end
  else
    m_str = string("DATA\r")
  end
  fname = hashfname([join(sta,','), join(patts,','), s, t, m_str], "mseed")

  if w
    (v > 0) && println(string("Raw packets will be written to file ", fname, " in dir ", realpath(pwd())))
    fid = open(fname, "w")
  end

  # pass strings to server; check responses carefully
  for i = 1:Ns
    # pattern selector
    sel_str = string("SELECT ", patts[i], "\r")
    (v > 1) && println("Sending: ", sel_str)
    write(conn, sel_str)
    sel_resp = readline(conn)
    if contains(sel_resp,"ERROR")
      warn(string("Error in select string ", patts[i], " (", sta[i], "previous selector, ", i==1?"*":patts[i-1], " used)."))
      if strict
        close(conn)
        error("Strict mode specified; exit w/error.")
      end
    end
    (v > 1) && @printf(STDOUT, "Response: %s", sel_resp)

    # station selector
    sta_str = string("STATION ", sta[i], "\r")
    (v > 1) && println("Sending: ", sta_str)
    write(conn, sta_str)
    sta_resp = readline(conn)
    if contains(sel_resp,"ERROR")
      warn(string("Error in station string ", sta[i], " (station excluded)."))
      if strict
        close(conn)
        error("Strict mode specified; exit w/error.")
      end
    end
    (v > 1) && @printf(STDOUT, "Response: %s", sta_resp)

    # mode
    (v > 1) && println("Sending: ", m_str)
    write(conn, m_str)
    m_resp = readline(conn)
    (v > 1) && @printf(STDOUT, "Response: %s", m_resp)
  end
  write(conn,"END\r")
  # ==========================================================================

  # ==========================================================================
  # data transfer
  k = @task begin
    j = 0
    while true
      if !isopen(conn)
        println("Connection closed, exiting SeedLink!...")
        w && close(fid)
        break
      else

        #= use of rand() makes it almost impossible for multiple SeedLink
        connections to result in one sleeping indefinitely. =#
        u = ceil(Int, r*(1+rand()))
        sleep(u)
        eof(conn)
        N = floor(Int, nb_available(conn)/520)
        if N > 0
          buf = IOBuffer(read(conn, UInt8, 520*N))
          if w
            write(fid, copy(buf))
          end
          (v > 1) && @printf(STDOUT, "%s: Processing packets ", string(now()))
          while !eof(buf)
            pkt_id = String(read(buf,UInt8,8))
            parserec(S, buf, src=src)
            (v > 1) && @printf(STDOUT, "%s, ", pkt_id)
          end
          (v > 1) && @printf(STDOUT, "\b\b...done current packet dump.\n")
        end

        # SeedLink (non-standard) keep-alive gets sent every a seconds
        j += u
        if j ≥ a
          j -= a
          write(conn,"INFO ID\r")
        end

      end
    end
  end
  Base.sync_add(k)
  Base.enq_work(k)
  # ========================================================================

  return conn
end

# If no SeisData object supplied, create/return one
SeedLink(sta::Array{String,1};
  addr="rtserve.iris.washington.edu"::String,         # url
  port=18000::Integer,                                # port
  patts=["*"]::Array{String,1},                       # channel/loc/data
  mode="DATA"::String,                                # SeedLink mode
  a=600::Real,                                        # keepalive interval (s)
  f=true::Bool,                                       # safe (checks existence)
  r=60::Real,                                         # refresh interval (s)
  s=0::Union{Real,DateTime,String},                   # start (time/dialup mode)
  t=300::Union{Real,DateTime,String},                 # end (time mode only)
  strict=true::Bool,                                  # strict (exit on errors)
  v=0::Int,                                           # verbosity
  w=false::Bool) = begin
  S = SeisData()
  C = SeedLink!(S, sta, addr=addr, port=port, patts=patts, mode=mode,
                r=r, a=a, s=s, t=t, f=f, strict=strict, v=v, w=w)
  return (C,S)
end

# Methods when supplying a config file or string
function SeedLink!(S::SeisData,
  cfg::String;
  addr="rtserve.iris.washington.edu"::String,         # url
  port=18000::Integer,                                # port
  patts=["*"]::Array{String,1},                       # channel/loc/data
  mode="DATA"::String,                                # SeedLink mode
  a=600::Real,                                        # keepalive interval (s)
  f=true::Bool,                                       # safe (checks existence)
  r=60::Real,                                         # refresh interval (s)
  s=0::Union{Real,DateTime,String},                   # start (time/dialup mode)
  t=300::Union{Real,DateTime,String},                 # end (time mode only)
  strict=true::Bool,                                  # strict (exit on errors)
  v=0::Int,                                           # verbosity
  w=false::Bool)

  Q = SL_parse(cfg)
  C = SeedLink!(S, Q[:,1], addr=addr, port=port, patts=Q[:,2], mode=mode,
                r=r, a=a, s=s, t=t, f=f, strict=strict, v=v, w=w)
  return C
end

function SeedLink(cfg::String;
  addr="rtserve.iris.washington.edu"::String,         # url
  port=18000::Integer,                                # port
  patts=["*"]::Array{String,1},                       # channel/loc/data
  mode="DATA"::String,                                # SeedLink mode
  a=600::Real,                                        # keepalive interval (s)
  f=true::Bool,                                       # safe (checks existence)
  r=60::Real,                                         # refresh interval (s)
  s=0::Union{Real,DateTime,String},                   # start (time/dialup mode)
  t=300::Union{Real,DateTime,String},                 # end (time mode only)
  strict=true::Bool,                                  # strict (exit on errors)
  v=0::Int,                                           # verbosity
  w=false::Bool)
  S = SeisData()
  Q = SL_parse(cfg)
  C = SeedLink!(S, Q[:,1], addr=addr, port=port, patts=Q[:,2], mode=mode,
                r=r, a=a, s=s, t=t, f=f, strict=strict, v=v, w=w)
  return (C,S)
end
