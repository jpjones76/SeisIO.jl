export FDSNevq, FDSNevt

"""
    (H,R) = FDSNevq(ot)

Multi-server query for the events with the closest origin time to `ot`.
Returns an Array{SeisHdr,1} in H with event headers and an Array{SeisSrc,1}
in R in H with corresponding source process info.

### Keywords
| KW       | Default      | T [^1]    | Meaning                        |
|----------|:-----------  |:----------|:-------------------------------|
| evw      | [600., 600.] | Float64   | search window in seconds [^2]  |
| mag      | [6.0, 9.9]   | Float64   | search magitude range          |
| nev      | 0            | Integer   | events per query [^3]          |
| rad      | []           | Float64   | radius search                  |
| reg      | []           | Float64   | geographic search region       |
| src [^4] | "IRIS"       | String    | data source; `?seis_www` lists |
| to       | 30           | Int64     | timeout (s) for web requests   |
| v        | 0            | Integer   | verbosity                      |

[^1]: `Array{T, 1}` for `evw`, `mag`, `rad`, `reg`; `T` for others
[^2]: search range is always `ot-|evw[1]| ≤ t ≤ ot+|evw[2]|`
[^3]: if `nev=0`, all matches are returned.
[^4]: In an event query, keyword `src` can be a comma-delineated list, like `"IRIS, INGV, NCEDC"`.

See also: `SeisIO.KW`, `?seis_www`
"""
function FDSNevq(ot::String;
  evw::Array{Float64,1} = [600.0, 600.0],
  mag::Array{Float64,1} = [6.0, 9.9],
  nev::Integer = 0,
  rad::Array{Float64,1} = KW.rad,
  reg::Array{Float64,1} = KW.reg,
  src::String = KW.src,
  to::Int = KW.to,
  v::Integer = KW.v)

  if isempty(reg) && !isempty(rad)
    if length(rad) == 4
      append!(rad, [-30.0, 700.0])
    end
    search_coords = string( "&latitude=", rad[1], "&longitude=", rad[2],
                            "&minradius=", rad[3], "&maxradius=", rad[4],
                            "&mindepth=", rad[5], "&maxdepth=", rad[6] )
  else
    if isempty(reg)
      reg = Float64[-90.0, 90.0, -180.0, 180.0, -30.0, 700.0]
    elseif length(reg) == 4
      append!(reg, [-30.0, 700.0])
    end
    search_coords = string("&minlat=", reg[1], "&maxlat=", reg[2],
                           "&minlon=", reg[3], "&maxlon=", reg[4],
                           "&mindepth=", reg[5], "&maxdepth=", reg[6])
  end

  # Determine time window
  ot2::Float64 = try
    d2u(DateTime(ot))
  catch
    if length(ot) <= 14
      ot0 = string(ot[1:4],"-",ot[5:6],"-",ot[7:8],"T",ot[9:10],":",ot[11:12])
      if length(ot) > 12
        ot1 = string(ot0, ":", ot[13:14])
      else
        ot1 = string(ot0, ":00")
      end
    end
    d2u(DateTime(ot1))
  end
  d0 = string(u2d(ot2 - abs(evw[1])))
  d1 = string(u2d(ot2 + abs(evw[2])))
  oti = round(Int64, ot2*sμ)

  # multi-server query (most FDSN servers do NOT have an event service)
  sources = String.(strip.(split(lowercase(src) == "all" ? "EMSC, INGV, IRIS, LMU, NCEDC, NIEP, ORFEUS, SCEDC, USGS, USP" : src, ",")))
  sources = [strip(i) for i in sources]
  EvCat = Array{SeisHdr,1}(undef, 0)
  EvSrc = Array{SeisSrc,1}(undef, 0)
  origin_times = Array{Int64,1}(undef, 0)
  for k in sources
    v > 1 && println(stdout, "Querying ", k)
    url = string(fdsn_uhead(String(k)), "event/1/query?",
                                        "starttime=", d0, "&endtime=", d1,
                                        search_coords,
                                        "&minmag=", mag[1], "&maxmag=", mag[2],
                                        "&format=xml")
    v > 0 && println(stdout, "URL = ", url)
    req_info_str = "\nFDSN event query:"

    (R, parsable) = get_http_req(url, req_info_str, to)
    if parsable
      str_req = String(R)
      v > 1 && println(stdout, "REQUEST BODY:\n", str_req)
      xdoc = parse_string(str_req)
      event_xml!(EvCat, EvSrc, xdoc)
      v > 1 && println(stdout, "CATALOG:\n", EvCat)
    end
  end

  if nev > 0
    # Sort based on earliest origin time
    # sort!(EvCat, by = H -> abs(round(Int64, d2u(getfield(H, :ot))*sμ) - oti))
    for H in EvCat
      # push!(origin_times, round(Int64, d2u(getfield(H, :ot))*sμ))
      push!(origin_times, abs(round(Int64, d2u(getfield(H, :ot))*sμ) - oti))
    end
    # k = sortperm(abs.(origin_times.-oti))
    k = sortperm(origin_times)

    n0 = min(length(EvCat), nev)
    n0 < nev && @warn(string("Catalog only contains ", n0, " events (original request was ", nev,")"))
    return EvCat[k[1:n0]], EvSrc[k[1:n0]]
    # return EvCat[1:n0], EvSrc[1:n0]
  else
    return EvCat, EvSrc
  end
end

"""
    FDSNevt(ot::String, chans::String)

Get header and trace data for the event closest to origin time `ot` on channels
`chans`. Returns a SeisEvent structure.

### Keywords
| KW       | Default      | T [^1]    | Meaning                        |
|----------|:-----------  |:----------|:-------------------------------|
| evw      | [600., 600.] | Float64   | search window in seconds [^2]  |
| fmt      | "miniseed"   | String    | request data format            |
| len      | 120.0        | Float64   | desired trace length [s]       |
| mag      | [6.0, 9.9]   | Float64   | search magitude range          |
| model    | "iasp91"     | String    | velocity model for phases      |
| nd       | 1            | Real      | number of days per subrequest  |
| opts     | ""           | String    | user-specified options[^3]     |
| pha      | "P"          | String    | phases to get  [^4]            |
| rad      | []           | Float64   | radius search                  |
| reg      | []           | Float64   | geographic search region       |
| src      | "IRIS"       | String    | data source; `?seis_www` lists |
| to       | 30           | Int64     | timeout (s) for web requests   |
| v        | 0            | Integer   | verbosity                      |
| w        | false        | Bool      | write requests to disk?        |

[^1]: KW is `Array{T, 1}` for `evw`, `mag`, `rad`, `reg`, type `T` for others
[^2]: Search range is always `ot-|evw[1]| ≤ t ≤ ot+|evw[2]|`
[^3]: Format like an http request string, e.g. "szsrecs=true&repo=realtime" for FDSN. String shouldn't begin with an ampersand.
[^4]: Comma-separated String, like `"P, pP"`; use `"ttall"` for all phases

See also: `distaz!`, `FDSNevq`, `FDSNsta`
"""
function FDSNevt(ot::String, chans::ChanOpts;
  evw::Array{Float64,1} = [600.0, 600.0],
  fmt::String           = KW.fmt,
  len::Real             = 120.0,
  mag::Array{Float64,1} = [6.0, 9.9],
  model::String         = "iasp91",
  nd::Real              = KW.nd,
  opts::String          = KW.opts,
  pha::String           = "P",
  rad::Array{Float64,1} = KW.rad,
  reg::Array{Float64,1} = KW.reg,
  src::String           = KW.src,
  to::Int64             = KW.to,
  v::Integer            = KW.v,
  w::Bool               = KW.w
  )

  C = fdsn_chp(chans, v)

  # Create header
  v > 0 && println(stdout, now(), ": event query begins.")
  (H,R) = FDSNevq(ot, nev=1,
                  rad=rad,
                  reg=reg,
                  mag=mag,
                  src=src,
                  to=to,
                  evw=evw,
                  v=v
                  )
  H = H[1]
  R = R[1]

  # Create channel data
  v > 0 && println(stdout, now(), ": data query begins.")
  s = H.ot                                      # Start time for FDSNsta is event origin time
  t = u2d(d2u(s) + 60*len)                      # End time is len minutes later
  (d0, d1) = parsetimewin(s,t)
  S = SeisData()
  # FDSNget!(S, C, fmt=fmt, nd=nd, rad=rad, reg=reg, s=d0, si=true, src=src, t=d1, to=to, v=v, w=w)
  FDSNget!(S, C, d0, d1, false, fmt, false, nd, "", rad, reg, true, src, to, v, w, "FDSNsta.xml", false)

  v > 1 && println(stdout, now(), ": channels initialized.")
  v > 2 && println(stdout, S)

  # Initialize SeisEvent structure
  Ev = SeisEvent(hdr = H, source = R, data = S)
  v > 1 && println(stdout, now(), ": SeisEvent created.")
  v > 1 && println(stdout, S)

  # Update Ev with distance, azimuth
  distaz!(Ev)
  v > 1 && println(stdout, now(), ": Δ,Θ updated.")

  # Add phase arrivals to :data
  v > 0 && println(stdout, now(), ": phase query begins.")
  get_pha!(Ev, pha=pha, model=model, to=to, v=v)
  return Ev
end
