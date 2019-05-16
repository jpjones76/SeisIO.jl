export FDSNevq, FDSNevt, FDSNsta

# =============================================================================
# No export

function FDSN_chp(chans::Union{String,Array{String,1},Array{String,2}}; v::Int64 = KW.v)
  # Parse channel config
  if isa(chans, String)
    C = parse_chstr(chans, fdsn = true)
  elseif isa(chans, Array{String,1})
    C = parse_charr(chans, fdsn = true)
  else
    C = copy(chans)
  end
  minreq!(C)
  v > 1 && println(stdout, "Most compact request form = ", C)
  return C
end

"""
    S = FDSNsta(chans, KW)

Retrieve station/channel info for formatted parameter file (or string) `chans`
into an empty SeisData structure.

Standard keywords: rad, reg, src, to, v

Other keywords:
* s: Start time
* t: Termination (end) time
* xf: Name of XML file to save station metadata

See also: chanspec, parsetimewin, get_data!, SeisIO.KW
"""
function FDSNsta(chans="*"::Union{String,Array{String,1},Array{String,2}};
                  rad ::Array{Float64,1}  = KW.rad,         # Search radius
                  reg ::Array{Float64,1}  = KW.reg,         # Search region
                  s   ::TimeSpec          = 0,              # Start
                  src ::String            = KW.src,         # Source server
                  t   ::TimeSpec          = (-600),         # End or Length (s)
                  to  ::Int               = KW.to,          # Read timeout (s)
                  v   ::Int64             = KW.v,           # Verbosity
                  xf  ::String            = "FDSNsta.xml"   # XML filename
                 )

  d0, d1 = parsetimewin(s, t)
  v > 0 && @info(tnote("Querying FDSN stations"))
  URL = string(fdsn_uhead(src), "station/1/query")
  BODY = "level=response\nformat=xml\n"
  wc = "*"

  # Add geographic search to BODY
  if !isempty(rad)
    BODY *= string( "latitude=", rad[1], "\n",
                    "longitude=", rad[2], "\n",
                    "minradius=", rad[3], "\n",
                    "maxradius=", rad[4], "\n")
  end
  if !isempty(reg)
    BODY *= string( "minlatitude=", reg[1], "\n",
                    "maxlatitude=", reg[2], "\n",
                    "minlongitude=", reg[3], "\n",
                    "maxlongitude=", reg[4], "\n" )
  end

  # Add channel search to BODY
  if chans == wc
    (isempty(reg) && isempty(rad)) && error("No query! Please specify a search radius, a rectangular search region, or some channels.")
    BODY *= string("* * * * ", d0, " ", d1, "\n")
  else
    C = FDSN_chp(chans, v=v)
    Nc = size(C,1)
    for i = 1:Nc
      str = ""
      for j = 1:4
        str *= (" " * (isempty(C[i,j]) ? wc : C[i,j]))
      end
      BODY *= string(str, " ", d0, " ", d1, "\n")
    end
  end
  if v > 1
    printstyled("request url:", color=:light_green)
    println(URL)
    printstyled("request body: \n", color=:light_green)
    println(BODY)
  end
  open(xf, "w") do io
    request("POST", URL, webhdr, BODY, response_stream=io)
  end

  # Build channel list
  v > 0 && @info(tnote("Building list of channels"))
  io = open(xf, "r")
  xsta = read(io, String)
  close(io)
  (ID, NAME, LOC, FS, GAIN, RESP, UNITS, MISC) = FDSN_sta_xml(xsta)
  v > 2 && println(stdout, "IDs from XML = ", ID)
  # Transfer to a SeisData object
  S = SeisData(length(ID))
  for i = 1:S.n
    S.id[i]     = ID[i]
    S.name[i]   = NAME[i]
    S.loc[i]    = LOC[i]
    S.fs[i]     = FS[i]
    S.gain[i]   = GAIN[i]
    S.resp[i]   = RESP[i]
    S.units[i]  = UNITS[i]
    merge!(S.misc[i], MISC[i])
  end
  return S
end

function FDSNget!(U::SeisData, chans::Union{String,Array{String,1},Array{String,2}};
  fmt       ::String            = KW.fmt,         # Request format
  nd        ::Real              = KW.nd,          # Number of days per request
  opts      ::String            = KW.opts,        # User-defined options
  rad       ::Array{Float64,1}  = KW.rad,         # Search radius
  reg       ::Array{Float64,1}  = KW.reg,         # Search region
  s         ::TimeSpec          = 0,              # Start
  si        ::Bool              = KW.si,          # Station info?
  src       ::String            = KW.src,         # Source server
  t         ::TimeSpec          = (-600),         # End or Length (s)
  to        ::Int64             = KW.to,          # Read timeout (s)
  v         ::Int64             = KW.v,           # Verbosity
  w         ::Bool              = KW.w,           # Write to disk?
  xf        ::String            = "FDSNsta.xml",  # XML filename
  y         ::Bool              = KW.y            # Sync?
  )

  parse_err = false
  n_badreq = 0
  wc = "*"
  d0, d1 = parsetimewin(s, t)
  # dt_end = DateTime(d1)
  # dt1 = deepcopy(dt_end)
  # dt0 = DateTime(d0)

  # (1) Time-space query for station info
  if si
    S = FDSNsta(chans,
                rad   = rad,
                reg   = reg,
                s     = d0,
                src   = src,
                t     = d1,
                to    = to,
                v     = v,
                xf    = xf
                )
  end

  # (2) Build ID strings for data query
  ID_str = Array{String,1}(undef,S.n)
  for i = 1:S.n
    ID_mat = split(S.id[i], ".")
    ID_mat[isempty.(ID_mat)] .= wc
    ID_str[i] = join(ID_mat, " ")
  end
  if v > 1
    printstyled("data query strings:\n", color=:light_green)
    for i = 1:length(ID_str)
      println(stdout, ID_str[i])
    end
  end

  # (3) Data query
  v > 0 && @info(tnote("Data query begins"))
  URL = string(fdsn_uhead(src), "dataselect/1/query")
  BODY = "format=" * fmt * "\n"
  if !isempty(opts)
    OPTS = split(opts, "&")
    for opt in OPTS
      BODY *= string(opt, "\n")
    end
  end

  # Set the data source
  for i = 1:S.n
    S.src[i] = URL
  end

  # Create variables for query
  ts = tstr2int(d0)
  ti = round(Int64, nd*86400000000)
  te = tstr2int(d1)
  t1 = deepcopy(ts)
  rn = 0
  while t1 < te
    rn += 1
    os = rn > 1 ? 1 : 0
    t1 = min(ts + ti, te)
    s_str = int2tstr(ts + os)
    t_str = int2tstr(t1)
    qtail = string(" ", s_str, " ", t_str, "\n")
    QUERY = identity(BODY)
    for i = 1:S.n
      QUERY *= ID_str[i]*qtail
    end
    if v > 1
      printstyled(string("request url: ", URL, "\n"), color=:light_green)
      printstyled(string("request body: \n", QUERY), color=:light_green)
    end

    # Request via "POST"
    if w
      if fmt == "miniseed"
        ext = "mseed"
      else
        ext = fmt
      end
      ymd = split(string(s_str), r"[A-Z]")
      (y, m, d) = split(ymd[1], "-")
      j = md2j(y, m, d)
      fname = join([String(y),
                    string(j),
                    replace(split(s_str, 'T')[2], ':' => '.'),
                    "FDSNWS",
                    src,
                    ext],
                    '.')

      open(fname, "w") do io
        request("POST", URL, webhdr, QUERY, readtimeout=to, response_stream=io)
      end
      io = open(fname, "r")
      parsable = true
    else
      (R, parsable) = get_http_post(URL, QUERY, to)
      if parsable
        io = IOBuffer(R)
      end
    end

    # Parse data (if we can)
    if parsable && fmt in ["mseed", "miniseed", "geocsv"]
      if fmt == "mseed" || fmt == "miniseed"
        parsemseed!(S, io, v, KW.nx_add, KW.nx_add)
      elseif fmt == "geocsv" || fmt == "geocsv.tspair"
        read_geocsv_tspair!(S, io)
      elseif fmt == "geocsv.slist"
        read_geocsv_slist!(S, io)
      end
    else
      parse_err = true
      n_badreq += 1
      S += SeisChannel(id = string("XX..", n_badreq),
                       misc = Dict{String,Any}( "url" => URL,
                                                "body" => QUERY,
                                                "data" => readlines(IOBuffer(R)) ) )
    end

    ts += ti
  end

  append!(U,S)
  # Done!
  v > 0 && @info(tnote("Done FDSNget query."))
  return parse_err
end

"""
    H = FDSNevq(ot)

Multi-server query for the events with the closest origin time to `ot`.

Standard keywords: evw, rad, reg, mag, nev, src, to

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
  catalog = Array{SeisHdr,1}(undef, 0)
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

    # R = request("GET", url, webhdr(), readtimeout=to)
    (R, parsable) = get_HTTP_req(url, req_info_str, to)
    if parsable
      str_req = String(R)
      v > 1 && println(stdout, "REQUEST BODY:\n", str_req)
      (id, ot_tmp, loc, mm, msc) = FDSN_event_xml(str_req)
      for i = 1:length(id)
          eh = SeisHdr(id=id[i], ot=ot_tmp[i], loc=loc[i], mag=(mm[i], msc[i]), src=url)
          push!(catalog, eh)
          push!(origin_times, round(Int64, d2u(eh.ot)*sμ))
      end
      v > 1 && println(stdout, "CATALOG:\n", catalog)
    end
  end
  k = sortperm(abs.(origin_times.-oti))
  n0 = min(length(k), nev)
  n0 < nev && @warn(string("Catalog only contains ", n0, " events (original request was ", nev,")"))
  return catalog[k[1:n0]]
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

  C = FDSN_chp(chans, v=v)

  # Create header
  v > 0 && println(stdout, now(), ": event query begins.")
  H = FDSNevq(ot, nev=1,
                  rad=rad,
                  reg=reg,
                  mag=mag,
                  src=src,
                  to=to,
                  evw=evw,
                  v=v
              )[1]

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
  Ev = SeisEvent(hdr = H, data = S)
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
