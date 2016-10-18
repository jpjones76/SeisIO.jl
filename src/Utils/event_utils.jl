using Requests: get
sa_prune!(S::Union{Array{String,1},Array{SubString{String},1}}) = (deleteat!(S, find(isempty, S)); return S)

"""
    S = evq(t)

Multi-server query for the events with the closest origin time to **t**. **t**
should be an ASCII string, formatted YYYY-MM-DDThh:mm:ss with times given in UTC
(e.g. "2001-02-08T18:54:32"). Returns a SeisHdr object.

Incomplete string queries are read to the nearest fully specified time
constraint, e.g., evq("2001-02-08") returns the nearest event to 2001-02-08T00:00:00
UTC. If no event is found on any server within one day of the specified search
time, evq exits with an error.

Additional arguments can be passed at the command line for more specific queries:

    S = evq(t, w=TIME_LENGTH)

Specify time length (in seconds) to search around **t**. Default is 86400.

    S = evq(t, x=true)

Treat **t** as exact (within one second). Overrides **w**.

    S = evq(t, mag=[MIN_MAG MAX_MAG])

Restrict queries to **MIN_MAG** ≤ m ≤ **MAX_MAG**.

    S = evq(s, n=N)

Return **N** events, rather than 1. S will be an array of SeisEvts.

    S = evq(s, lat=[LAT_MIN LAT_MAX], lon=[LON_MIN LON_MAX], dep=[DEP_MIN DEP_MAX])

Only search within the specified region. Specify lat and lon in decimal degrees;
treat North and East as positive, respectively. Specify dep in km.

    S = evq(s, src=SRC)

Only query server **SRC**. Specify as a string. See list of sources in SeisIO
documentation.
"""
function evq(ts::String;
  dep=[-100.0 6370.0]::Array{Float64,2},
  lat=[-90.0 90.0]::Array{Float64,2},
  lon=[-180.0 180.0]::Array{Float64,2},
  mag=[6.0 9.9]::Array{Float64,2},
  n=1::Int,
  src="IRIS"::String,
  to=10::Real,
  w=600.0::Real,
  x=false::Bool,
  v=false::Bool,
  vv=false::Bool)
  if x
    w = 1.0
  end

  # Determine time window
  if length(ts) <= 14
    ts0 = string(ts[1:4],"-",ts[5:6],"-",ts[7:8],"T",ts[9:10],":",ts[11:12])
    if length(ts) > 12
      ts = string(ts0, ":", ts[13:14])
    else
      ts = string(ts0, ":00")
    end
  end
  ts = d2u(DateTime(ts))
  s = string(u2d(ts-w))
  t = string(u2d(ts+w))

  # Do server queries
  # Template: service.iris.edu/fdsnws/event/1/query?starttime=2011-01-08T00:00:00&endtime=2011-01-09T00:00:00&catalog=NEIC PDE&format=text
  if src == "All"
    sources = ["IRIS", "RESIF", "NCEDC", "GFZ"]
  else
    sources = split(src,",")
  end
  evt_data = Array{String,1}()
  for k in sources
    url = string(get_uhead(k), "event/1/query?",
    "starttime=", s, "&endtime=", t,
    "&minlat=", lat[1], "&maxlat=", lat[2],
    "&minlon=", lon[1], "&maxlon=", lon[2],
    "&mindepth=", dep[1], "&maxdepth=", dep[2],
    "&minmag=", mag[1], "&maxmag=", mag[2],
    "&format=text")
    evt_data = [evt_data; split(readall(get(url, timeout=to, headers=webhdr())), '\n')[2:end]]
    vv && println("evt_data = ", evt_data)
  end
  sa_prune!(evt_data)
  ot = Array{Float64,1}(length(evt_data))
  for i = 1:1:length(evt_data)
    ot[i] = d2u(DateTime(split(evt_data[i],"|")[2]))
  end
  k = sortperm(abs(ot.-ts))
  evt_cat = evt_data[k[1:n]]
  if n == 1
    return mkevthdr(evt_cat[1])
  else
    evt_list = Array{SeisHdr,1}(n)
    for i = 1:1:n
      evt_list[n] = mkevthdr(evt_cat[i])
    end
    return evt_list
  end
end

# Purpose: Given DELTA, OT, and source depth, compute expected phase arrival times
# Template: https://service.iris.edu/irisws/traveltime/1/query?distdeg=10.1&evdepth=20.5&phases=P,S&noheader=true
# """
#     (T, ϕ, R) = getOnset(ot::DateTime, Δ::Float64, z::Float64; pha="P,S"::String)
#
# Get expected arrival times in UTC for the given phases. Specify phases as a
# comma-separated list with no spaces, e.g. "P,pP,ScS"; getOnset uses the TauP
# phase naming convention (see reference). Defaults to "P,S".
#
# Values returned:
#     T   Arrival times as a DateTime vector
#     ϕ   Incidence angles of each phase
#     R   Phase names corresponding to each entry in T, ϕ
#
# Reference: Crotwell, H.P., Owens, T.J., \& Ritsema, J. (1999). The TauP
# Toolkit: flexible seismic travel-time and ray-path utilities, SRL 70, 154–-160.
#
# """
# function getOnset(ot::DateTime, Δ::Float64, z::Float64;
#   pha="P,S"::String,
#   to=10::Real,
#   v=false::Bool,
#   vv=false::Bool)
#
#   # Initialize
#   os = d2u(ot)
#   N = length(split(pha,','))
#   S = Array{String,1}(N)
#   ϕ = zeros(Float64,N)
#   t = zeros(Float64,N)
#   url = string("https://service.iris.edu/irisws/traveltime/1/query?distdeg=",
#     Δ, "&evdepth=", z, "&phases=", pha, "&noheader=true&mintimeonly=true")
#   (v | vv) && println("url = ", url)
#
#   # Get URL
#   req = readall(get(url, timeout=to, headers=webhdr()))
#   vv && println("req = ", req)
#
#   # Parse result
#   ptab = split(req, '\n')[1:end-1]
#   for i = 1:length(ptab)
#     L = split(ptab[i])
#     S[i] = L[3]
#     t[i] = parse(Float64, L[4])
#     ϕ[i] = parse(Float64, L[7])
#     vv && println("t[", i, "] =", t[i])
#   end
#
#   # Convert to absolute times
#   T = Dates.unix2datetime(t.+os)
#   return (T, ϕ, S)
# end

"""
(dist, az, baz) = gcdist([lat_src, lon_src], rec)

  Compute great circle distance, azimuth, and backazimuth from source
coordinates [lat_src, lon_src] to receiver coordinates [lat_rec, lon_rec].
*rec* should be a matix with latitudes in column 1, longitudes in column 2.

"""
function gcdist(src::Array{Float64,1}, rec::Array{Float64,2})
  #lat_rec::Array{Float64,1}, lon_rec::Array{Float64,1})
  N = size(rec, 1)
  lat_src = repmat([src[1]], N)
  lon_src = repmat([src[2]], N)
  lat_rec = rec[:,1]
  lon_rec = rec[:,2]

  ϕ1, λ1 = gc_ctr(lat_src, lon_src)
  ϕ2, λ2 = gc_ctr(lat_rec, lon_rec)
  Δϕ = ϕ2 - ϕ1
  Δλ = λ2 - λ1

  a = sin(Δϕ/2.0) .* sin(Δϕ/2.0) + cos(ϕ1) .* cos(ϕ2) .* sin(Δλ/2.0) .* sin(Δλ/2.0)
  Δ = 2.0 .* atan2(sqrt(a), sqrt(1.0 - a))
  A = atan2(sin(Δλ).*cos(ϕ2), cos(ϕ1).*sin(ϕ2) - sin(ϕ1).*cos(ϕ2).*cos(Δλ))
  B = atan2(-1.0.*sin(Δλ).*cos(ϕ1), cos(ϕ2).*sin(ϕ1) - sin(ϕ2).*cos(ϕ1).*cos(Δλ))

  # convert to degrees
  return (Δ.*180.0/π, gc_unwrap!(A).*180.0/π, gc_unwrap!(B).*180.0/π )
end
gcdist(lat0::Float64, lon0::Float64, lat1::Float64, lon1::Float64) = (gcdist([lat0, lon0], [lat1 lon1]))
gcdist(src::Array{Float64,2}, rec::Array{Float64,2}) = (gcdist([src[1], src[2]], rec))
gcdist(src::Array{Float64,2}, rec::Array{Float64,1}) = (
  warn("Multiple sources or source coords passed as a matrix; only using first coordinate pair!");
  gcdist([src[1,1], src[1,2]], [rec[1] rec[2]]);
  )

gc_ctr(lat, lon) = (atan(tan(lat*π/180.0)*0.9933056), lon*π/180.0)
gc_unwrap!(t::Array{Float64,1}) = (t[t .< 0] .+= 2.0*π; return t)

function mkevthdr(evt_line::String)
  evt = split(evt_line,'|')
  return SeisHdr( id = parse(Int64, evt[1]),
                  time = Dates.DateTime(evt[2]),
                  lat = parse(Float64, evt[3]),
                  lon = parse(Float64, evt[4]),
                  dep = parse(Float64, evt[5]),
                  auth = evt[6],
                  cat = evt[7],
                  contrib = evt[8],
                  contrib_id = parse(Int64, evt[9]),
                  mag_typ = evt[10],
                  mag = parse(Float32, evt[11]),
                  mag_auth = evt[12],
                  loc_name = evt[13])
end

"""
    distaz!(S::SeisEvt)

Compute Δ, Θ by the Haversine formula. Updates SeisEvt structure **S** with
distance, azimuth, and backazimuth for each channel. Values are stored as
S.data.misc["dist"], S.data.misc["az"],and S.data.misc["baz"], respectively.

"""
function distaz!(S::SeisEvt)
  rec = Array{Float64,2}(S.data.n,2)
  for i = 1:S.data.n
    rec[i,:] = S.data.loc[i][1:2]
  end
  (dist, az, baz) = gcdist([S.hdr.lat, S.hdr.lon], rec)
  for i = 1:S.data.n
    S.data.misc[i]["dist"] = dist[i]
    S.data.misc[i]["az"] = az[i]
    S.data.misc[i]["baz"] = baz[i]
  end
end

"""
    getevt(evt::String, cc::String)

Get data for event **evt** on channels **cc**. Event and channel data are
auto-filled using auxiliary functions.
"""
function getevt(evt::String, cc::String;
  mag=[6.0 9.9]::Array{Float64,2},
  to=10.0::Real,
  pha="P"::String,
  spad=1.0::Real,
  epad=0.0::Real,
  v=false::Bool,
  vv=false::Bool)

  if (v|vv)
    println(now(), ": request begins.")
  end

  # Parse channel config
  (Sta, Cha) = chparse(cc)

  # Create header
  h = evq(evt, mag=mag, to=to, v=v, vv=vv)      # Get event of interest with evq
  if (v|vv)
    println(now(), ": header query complete.")
  end

  # Create channel data
  s = h.time                                    # Start time for getsta is event origin time
  t = u2d(d2u(s) + 1.0)                         # End time is one second later
  d = getsta(Sta, Cha, st=s, et=t, to=to, v=v, vv=vv)
  if (v|vv)
    println(now(), ": channels initialized.")
  end

  # Initialize SeisEvt structure
  S = SeisEvt(hdr = h, data = d)
  if (v|vv)
    println(now(), ": SeisEvt created.")
  end
  vv && println(S)

  # Update S with distance, azimuth
  distaz!(S)
  if (v|vv)
    println(now(), ": Δ,Θ updated.")
  end

  # Desired behavior:
  # If the phase string supplied is "all", request window is spad s before P to twice the last phase arrival
  # If a phase name is supplied, request window is spad s before that phase to epad s after next phase
  pstr = Array{String,1}(S.data.n)
  for i = 1:1:S.data.n
    pdat = getpha(S.data.misc[i]["dist"], S.hdr.dep, to=to, v=v, vv=vv)
    if pha == "all"
      j = getPhaSt(pdat)
      s = parse(Float64,pdat[j,4]) - spad
      t = 2.0*parse(Float64,pdat[getPhaEn(pdat),4])
      S.data.misc[i]["PhaseWindow"] = string(pdat[j,3], " : Coda")
    else
      s = parse(Float64,pdat[find(pdat[:,3].==pha)[1],4]) - spad
      (p2,t) = getNextPhase(pha, pdat)
      t += epad
      S.data.misc[i]["PhaseWindow"] = string(pha, " : ", p2)
    end
    s = string(u2d(d2u(S.hdr.time) + s))
    t = string(u2d(d2u(S.hdr.time) + t))
    (NET, STA, LOC, CHA) = split(S.data.id[i],".")
    if isempty(LOC)
      LOC = "--"
    end
    C = FDSNget(net = NET, sta = STA, loc = LOC, cha = CHA,
                s = s, t = t, si = false, y = false, v=v, vv=vv)
    vv && println("FDSNget output:\n", C)
    S.data.t[i] = C.t[1]
    S.data.x[i] = C.x[1]
    S.data.notes[i] = C.notes[1]
    S.data.src[i] = C.src[1]
    if (v | vv)
         println(now(), ": data acquired for ", S.data.id[i])
    end
  end
  return S
end

"""
    getpha(pha::String, Δ::Float64, z::Float64)

Get phase onsets **pha** relative to origin time for an eventat distance **Δ**
(degrees), depth **z** (km).

Detail: getpha is a command-line interface to the IRIS travel time calculator,
which calls TauP (1,2,3). Specify **pha** as a comma-separated string, e.g.
"P,S,PKiKP". **pha** also accepts special keywords (e.g. \"ttall\") as described
on the IRIS web pages.

References:
(1) IRIS travel time calculator: https://service.iris.edu/irisws/traveltime/1/
(2) TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf
(3) Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit:
Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.
"""
function getpha(Δ::Float64, z::Float64;
  phases=""::String,
  model="iasp91"::String,
  to=10.0::Real, v=false::Bool, vv=false::Bool)

  # Generate URL and do web query
  if isempty(phases)
    pq = ""
  else
    pq = string("&phases=", phases)
  end

  url = string("http://service.iris.edu/irisws/traveltime/1/query?",
  "distdeg=", Δ, "&evdepth=", z, pq, "&model=", model,
  "&mintimeonly=true&noheader=true")
  (v | vv) && println("url = ", url)
  req = readall(get(url, timeout=to, headers=webhdr()))
  (v | vv) && println("Request result:\n", req)

  # Parse results
  phase_data = split(req, '\n')
  sa_prune!(phase_data)
  Nf = length(split(phase_data[1]))
  Np = length(phase_data)
  Pha = Array{String,2}(Np, Nf)
  for p = 1:Np
    Pha[p,1:Nf] = split(phase_data[p])
  end
  return Pha
end

getphaseTime(pha::String, Pha::Array{String,2}) = parse(Float64, Pha[find(Pha[:,3].==pha)[1],4])
getPhaSt(pha::String, Pha::Array{String,2}) = findmin([parse(Float64,i) for i in Pha[:,4]])
getPhaEn(pha::String, Pha::Array{String,2}) = findmax([parse(Float64,i) for i in Pha[:,4]])
function getNextPhase(pha::String, Pha::Array{String,2})
  s = Pha[:,3]
  t = [parse(Float64,i) for i in Pha[:,4]]
  j = find(s.==pha)[1]
  i = t.-t[j].>0
  tt = t[i]
  ss = s[i]
  k = sortperm(tt.-t[j])[1]
  return(ss[k],tt[k])
end
