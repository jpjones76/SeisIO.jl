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

Return **N** events, rather than 1. S will be an array of SeisEvents.

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
  deleteat!(evt_data, find(isempty, evt_data))
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
"""
    (T, ϕ, R) = getPha(ot::DateTime, Δ::Float64, z::Float64; pha="P,S"::String)

Get expected arrival times in UTC for the given phases. Specify phases as a
comma-separated list with no spaces, e.g. "P,pP,ScS"; getPha uses the TauP
phase naming convention (see reference). Defaults to "P,S".

Values returned:
    T   Arrival times as a DateTime vector
    ϕ   Incidence angles of each phase
    R   Phase names corresponding to each entry in T, ϕ

Reference: Crotwell, H.P., Owens, T.J., \& Ritsema, J. (1999). The TauP
Toolkit: flexible seismic travel-time and ray-path utilities, SRL 70, 154–-160.

"""
function getPha(ot::DateTime, Δ::Float64, z::Float64;
  pha="P,S"::String,
  to=10::Real,
  v=false::Bool,
  vv=false::Bool)

  # Initialize
  os = d2u(ot)
  N = length(split(pha,','))
  S = Array{String,1}(N)
  ϕ = zeros(Float64,N)
  t = zeros(Float64,N)
  url = string("https://service.iris.edu/irisws/traveltime/1/query?distdeg=",
    Δ, "&evdepth=", z, "&phases=", pha, "&noheader=true&mintimeonly=true")
  (v | vv) && println("url = ", url)

  # Get URL
  req = readall(get(url, timeout=to, headers=webhdr()))
  vv && println("req = ", req)

  # Parse result
  ptab = split(req, '\n')[1:end-1]
  for i = 1:length(ptab)
    L = split(ptab[i])
    S[i] = L[3]
    t[i] = parse(Float64, L[4])
    ϕ[i] = parse(Float64, L[7])
    vv && println("t[", i, "] =", t[i])
  end

  # Convert to absolute times
  T = Dates.unix2datetime(t.+os)
  return (T, ϕ, S)
end

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
    distaz!(S::SeisEvent)

Compute Δ, Θ by the Haversine formula. Updates SeisEvent structure **S** with
distance, azimuth, and backazimuth for each channel. Values are stored as
S.data.misc["dist"], S.data.misc["az"],and S.data.misc["baz"], respectively.

"""

function distaz!(S)
  rec = Array{Float64,2}(S.data.n,2)
  for i = 1:S.data.n
    rec[i,:] = S.data.loc[i][1:2]
  end
  println(rec)
  (dist, az, baz) = gcdist([S.hdr.lat, S.hdr.lon], rec)
  println("dist = ", dist)
  println("az = ", az)
  println("baz = ", baz)
  for i = 1:S.data.n
    S.data.misc[i]["dist"] = dist[i]
    S.data.misc[i]["az"] = az[i]
    S.data.misc[i]["baz"] = baz[i]
  end
end

"""
    getP(evt::String, cc::String)

Get P-wave data for event **evt** on channels **cc**. Event and channel data are
auto-filled using auxiliary functions.
"""
function getP(evt::String, cc::String;
  mag=[6.0 9.9]::Array{Float64,2},
  to=10::Real,
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
  s = h.time                                    # Start time for GetSta is event origin time
  t = u2d(d2u(s) + 1.0)                         # End time is one second later
  d = GetSta(Sta, Cha, st=s, et=t, to=to, v=v, vv=vv)
  if (v|vv)
    println(now(), ": channels initialized.")
  end

  # Initialize SeisEvent structure
  S = SeisEvent(hdr = h, data = d)
  if (v|vv)
    println(now(), ": SeisEvent created.")
  end
  vv && println(S)

  # Update S with distance, azimuth
  distaz!(S)
  if (v|vv)
    println(now(), ": Δ,Θ updated.")
  end

  # Phase arrivals to get: (Somewhat simplified to condense code)
  # Δ < 40° "P,S", Δ ≥ 40° "P,PP"; might expand later
  I = [Array{Int64,1}(), Array{Int64,1}()]
  D = [Array{Float64,1}(), Array{Float64,1}()]
  pstr = ["P,S", "P,PP"]
  for i = 1:1:S.data.n
    if S.data.misc[i]["dist"] <= 40.0
      j = 1
    else
      j = 2
    end
    push!(I[j], i)
    push!(D[j], S.data.misc[i]["dist"])
  end
  for j = 1:length(I)
    if !isempty(I[j])
      ind = I[j]
      delta = D[j]
      for k = 1:length(ind)
        vv && println("Calling getPha(",
                      S.hdr.time, ", ",
                      delta[k], ", ",
                      S.hdr.dep, "; ",
                      "pha=", pstr[j], ", ",
                      "v=", v, ", ",
                      "vv=", vv, ")")
        (T1, ~, ~) = getPha(S.hdr.time, delta[k], S.hdr.dep; pha=pstr[j], v=v, vv=vv)
        vv && println("T1 =", T1)
        S.data.misc[ind[k]]["t1"] = T1[1]
        S.data.misc[ind[k]]["t2"] = T1[2]
      end
    end
  end
  if (v|vv)
    println(now(), ": time request windows done.")
  end

  # Unsynched data query by channel, to minimize length of each request
  for i = 1:1:S.data.n
    (NET, STA, LOC, CHA) = split(S.data.id[i],".")
    if isempty(LOC)
      LOC = "--"
    end
    s = FDSNget(net = NET, sta = STA, loc = LOC, cha = CHA,
                s = S.data.misc[i]["t1"], t = S.data.misc[i]["t2"],
                si = false, y = false, v=v, vv=vv)
    vv && println(s)
    S.data.x[i] = copy(s.x[1])
    if (v | vv)
      println(now(), ": data acquired for ", S.data.id[i])
    end
  end
  return S
end


# Them https://service.iris.edu/fdsnws/dataselect/1/query?net=IU&sta=ANMO&loc=00&cha=BHZ&start=2010-02-27T06:30:00.000&end=2010-02-27T10:30:00.000
# Me   https://service.iris.edu/fdsnws/dataselect/1/query?net=PB&sta=B004&loc=--&cha=EH1&start=2006-11-15T11:23:31.000&end=2006-11-15T11:25:31.000
