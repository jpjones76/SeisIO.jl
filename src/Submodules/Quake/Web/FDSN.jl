export FDSNevq, FDSNevt

"""
    (H,R) = FDSNevq(ot)

Multi-server query for the events with the closest origin time to `ot`.
Returns an Array{SeisHdr,1} in H with event headers and an Array{SeisSrc,1}
in R in H with corresponding source process info.

Keywords: evw, rad, reg, mag, nev, src, to

See also: SeisIO.KW
"""
function FDSNevq(ot::String;
  evw::Union{Array{Real,1},Array{Float64,1},Array{Int64,1}} = KW.evw,
  rad::Array{Float64,1} = KW.rad,
  reg::Array{Float64,1} = KW.reg,
  mag::Array{Float64,1} = KW.mag,
  nev::Int64 = KW.nev,
  src::String = KW.src,
  to::Int = KW.to,
  v::Int64 = KW.v)

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
  if lowercase(src) == "all"
    sources = String["EMSC", "INGV", "IRIS", "LMU", "NCEDC", "NIEP", "ORFEUS", "SCEDC", "USGS", "USP"]
  else
    sources = split(src,",")
  end
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

Get trace data for the event closest to origin time `ot` on channels `chans`.

Standard keywords: fmt, mag, nd, opts, pha, rad, reg, src, to, v, w

Other keywords:
* len::Real (120.0): desired record length in minutes
* model::String ("iasp91"): Earth velocity model for phase calculations

See also: distaz!, FDSNevq, FDSNsta, SeisKW
"""
function FDSNevt(ot::String, chans::Union{String,Array{String,1},Array{String,2}};
  len::Real             = 120.0,
  evw::Union{Array{Real,1},Array{Float64,1},Array{Int64,1}} = KW.evw,
  fmt::String           = KW.fmt,
  mag::Array{Float64,1} = KW.mag,
  model::String         = "iasp91",
  nd::Real              = KW.nd,
  opts::String          = KW.opts,
  pha::String           = KW.pha,
  rad::Array{Float64,1} = KW.rad,
  reg::Array{Float64,1} = KW.reg,
  src::String           = KW.src,
  to::Int64             = KW.to,
  v::Int64              = KW.v,
  w::Bool               = KW.w
  )

  C = fdsn_chp(chans, v=v)

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
  FDSNget!(S, C, fmt=fmt, nd=nd, rad=rad, reg=reg, s=d0, si=true, src=src, t=d1, to=to, v=v, w=w)

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
