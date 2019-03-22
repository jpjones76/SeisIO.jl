export FDSNevq, FDSNevt, FDSNsta, FDSNsearch

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

function LightXML_plunge(xtmp::Array{LightXML.XMLElement,1}, str::AbstractString)
  xtmp2 = Array{LightXML.XMLElement,1}()
  for i=1:length(xtmp)
    append!(xtmp2, get_elements_by_tagname(xtmp[i], str))
  end
  return xtmp2
end

function LightXML_findall(xtmp::Array{LightXML.XMLElement,1}, str::String)
  S = split(str, "/")
  for i=1:length(S)
    xtmp = LightXML_plunge(xtmp, S[i])
  end
  return xtmp
end
LightXML_findall(xdoc::LightXML.XMLDocument, str::String) = LightXML_findall([LightXML.root(xdoc)], str)
LightXML_findall(xtmp::LightXML.XMLElement, str::String) = LightXML_findall([xtmp], str)

function LightXML_str!(v::String, x::LightXML.XMLElement, s::String)
  Q = LightXML_findall(x, s)
  if isempty(Q) == false
    v = content(Q[1])
  end
  return v
end
LightXML_float!(v::Float64, x::LightXML.XMLElement, s::String) = Float64(Meta.parse(LightXML_str!(string(v), x, s)))

# FDSN event XML handler
function FDSN_event_xml(string_data::String)
  xevt = LightXML.parse_string(string_data)
  events = LightXML_findall(xevt, "eventParameters/event")
  N = length(events)
  id = Array{Int64,1}(undef, N)
  ot = Array{DateTime,1}(undef, N)
  loc = Array{Float64,2}(undef, 3, N)
  mag = Array{Float32,1}(undef, N)
  msc = Array{String,1}(undef, N)
  for (i,evt) in enumerate(events)
    id[i] = ( try
                Int64(Meta.parse(String(split(attribute(evt, "publicID"),'=')[2])))
              catch
                0
              end )
    ot[i] = DateTime(LightXML_str!("1970-01-01T00:00:00", evt, "origin/time/value"))
    loc[1,i] = LightXML_float!(0.0, evt, "origin/latitude/value")
    loc[2,i] = LightXML_float!(0.0, evt, "origin/longitude/value")
    loc[3,i] = LightXML_float!(0.0, evt, "origin/depth/value")/1.0e3
    mag[i] = Float32(LightXML_float!(-5.0, evt, "magnitude/mag/value"))

    tmp = LightXML_str!("--", evt, "magnitude/type")
    if isempty(tmp)
        msc[i] = "M?"
    else
        msc[i] = tmp
    end
  end
  return (id, ot, loc, mag, msc)
end

function FDSN_sta_xml(string_data::String)
    xroot = LightXML.parse_string(string_data)
    N = length(LightXML_findall(xroot, "Network/Station/Channel"))

    ID    = Array{String,1}(undef, N)
    NAME  = Array{String,1}(undef, N)
    FS    = Array{Float64,1}(undef, N)
    LOC   = Array{Array{Float64,1}}(undef, N)
    UNITS = Array{String,1}(undef, N)
    GAIN  = Array{Float64,1}(undef, N)
    RESP  = Array{Array{Complex{Float64},2}}(undef, N)
    MISC  = Array{Dict{String,Any}}(undef, N)
    for j = 1:N
        MISC[j] = Dict{String,Any}()
    end
    y = 0

    xnet = LightXML_findall(xroot, "Network")
    for net in xnet
        nn = attribute(net, "code")

        xsta = LightXML_findall(net, "Station")
        for sta in xsta
            ss = attribute(sta, "code")
            loc_tmp = zeros(Float64, 3)
            loc_tmp[1] = LightXML_float!(0.0, sta, "Latitude")
            loc_tmp[2] = LightXML_float!(0.0, sta, "Longitude")
            loc_tmp[3] = LightXML_float!(0.0, sta, "Elevation")/1.0e3
            name = LightXML_str!("0.0", sta, "Site/Name")

            xcha = LightXML_findall(sta, "Channel")
            for cha in xcha
                y += 1
                czs = Array{Complex{Float64},1}()
                cps = Array{Complex{Float64},1}()
                ID[y]               = join([nn, ss, attribute(cha,"locationCode"), attribute(cha,"code")],'.')
                NAME[y]             = identity(name)
                FS[y]               = LightXML_float!(0.0, cha, "SampleRate")
                LOC[y]              = zeros(Float64,5)
                LOC[y][1:3]         = copy(loc_tmp)
                LOC[y][4]           = LightXML_float!(0.0, cha, "Azimuth")
                LOC[y][5]           = LightXML_float!(0.0, cha, "Dip") - 90.0
                GAIN[y]             = 1.0
                MISC[y]["normfreq"] = 1.0
                MISC[y]["ClockDrift"] = LightXML_float!(0.0, cha, "ClockDrift")

                xresp = LightXML_findall(cha, "Response")
                if !isempty(xresp)
                    MISC[y]["normfreq"] = LightXML_float!(0.0, xresp[1], "InstrumentSensitivity/Frequency")
                    GAIN[y]             = LightXML_float!(1.0, xresp[1], "InstrumentSensitivity/Value")
                    UNITS[y]            = replace(LightXML_str!("unknown", xresp[1], "InstrumentSensitivity/InputUnits/Name"), "**" => "")

                    xstages = LightXML_findall(xresp[1], "Stage")
                    for stage in xstages
                        pz = LightXML_findall(stage, "PolesZeros")
                        for j = 1:length(pz)
                            append!(czs, [complex(LightXML_float!(0.0, z, "Real"), LightXML_float!(0.0, z, "Imaginary")) for z in LightXML_findall(pz[j], "Zero")])
                            append!(cps, [complex(LightXML_float!(0.0, p, "Real"), LightXML_float!(0.0, p, "Imaginary")) for p in LightXML_findall(pz[j], "Pole")])
                        end
                    end
                end
                NZ = length(czs)
                NP = length(cps)
                if NZ < NP
                    for z = NZ+1:NP
                        push!(czs, complex(0.0,0.0))
                    end
                end
                RESP[y] = hcat(czs,cps)
            end
        end
    end
    return ID, NAME, LOC, FS, GAIN, RESP, UNITS, MISC
end
# =============================================================================
"""

    FDSNsta!(S::SeisData, chans::Union{String,Array{String,1},Array{String,2}}, KWs)

Fill channels `chans` in `S` with parsed station XML data.

Standard keywords: src, to, v

Other keywords:
* s: Start time
* t: Termination (end) time

See also: chanspec, parsetimewin, get_data!, SeisIO.KW
"""
function FDSNsta!(S::SeisIO.SeisData, chans::Union{String,Array{String,1},Array{String,2}};
  s = 0::Union{Real,DateTime,String},       # Start
  src::String = KW.src,                     # FDSN source
  t = (-600)::Union{Real,DateTime,String},  # End or Length (s)
  to::Int = KW.to,                          # Read timeout (s)
  v::Int64 = KW.v                           # Verbosity
  )

  d0, d1 = parsetimewin(s, t)
  C = FDSN_chp(chans, v=v)

  for j = 1:size(C,1)
    new_id = join(C[j,1:4], '.')
    utail = build_stream_query(C[j,:], d0, d1)
    station_url = string(fdsn_uhead(src), "station/1/query?level=response&", utail)
    v > 1 && println(stdout, "station url = ", station_url)
    req_info_str = datareq_summ("FDSN station", new_id, d0, d1)

    (R, parsable) = get_HTTP_req(station_url, req_info_str, to)
    if parsable
      (ID, NAME, LOC, FS, GAIN, RESP, UNITS, MISC) = FDSN_sta_xml(String(R))
      for i = 1:S.n
        k = findid(S.id[i], ID)
        k == 0 && continue
        S.loc[i]    = LOC[k]
        S.units[i]  = UNITS[k]
        S.gain[i]   = GAIN[k]
        S.resp[i]   = RESP[k]
        S.name[i]   = NAME[k]
        merge!(S.misc[i], MISC[k])
      end
    end
  end
  return nothing
end
"""
    S = FDSNsta(chans, KW)

Retrieve station/channel info for formatted parameter file (or string) `chans`
into an empty SeisData structure.

Standard keywords: rad, reg, src, to, v

Other keywords:
* s: Start time
* t: Termination (end) time
* xml_file: Name of XML file to save station metadata

See also: chanspec, parsetimewin, get_data!, SeisIO.KW
"""
function FDSNsta(chans::Union{String,Array{String,1},Array{String,2}};
                  rad = Float64[]::Array{Float64,1},        # Search radius
                  reg = Float64[]::Array{Float64,1},        # Search region
                  s = 0::Union{Real,DateTime,String},       # Start
                  src::String = KW.src,                     # Source server
                  t = (-600)::Union{Real,DateTime,String},  # End or Length (s)
                  to::Int = KW.to,                          # Read timeout (s)
                  v::Int64 = KW.v,                          # Verbosity
                  xml_file = "FDSNsta.xml"                  # XML filename
                 )

  d0, d1 = parsetimewin(s, t)
  v > 0 && @info(tnote("Querying FDSN stations"))
  URL = string(fdsn_uhead(src), "station/1/query")
  BODY = "level=response\nformat=xml\n"
  wc = "*"
  if chans == wc
    (isempty(reg) && isempty(rad)) && error("No query! Please specify a search radius, a rectangular search region, or some channels.")
    if isempty(reg)
      BODY *= string( "latitude=", reg[1], "\n",
                      "longitude=", reg[2], "\n",
                      "minradius=", reg[3], "\n",
                      "maxradius=", reg[4], "\n")
    else
      BODY *= string( "minlatitude=", reg[1], "\n",
                      "maxlatitude=", reg[2], "\n",
                      "minlongitude=", reg[3], "\n",
                      "maxlongitude=", reg[4], "\n" )
    end
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
  if v > 2
    printstyled(string("request url: ", URL), color=:light_green)
    printstyled(string("request body: \n", BODY), color=:light_green)
  end
  open(xml_file, "w") do io
    request("POST", URL, webhdr, BODY, response_stream=io)
  end

  # Build channel list
  v > 0 && @info(tnote("Building list of channels"))
  io = open(xml_file, "r")
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
  fmt::String = KW.fmt,                     # Request format
  nd::Int64 = KW.nd,                        # Number of days per request
  opts::String = KW.opts,                   # User-defined options
  rad = Float64[]::Array{Float64,1},        # Search radius
  reg = Float64[]::Array{Float64,1},        # Search region
  s = 0::Union{Real,DateTime,String},       # Start
  si::Bool = KW.si,                         # Station info?
  src::String = KW.src,                     # Source server
  t = (-600)::Union{Real,DateTime,String},  # End or Length (s)
  to::Int = KW.to,                          # Read timeout (s)
  v::Int64 = KW.v,                          # Verbosity
  w::Bool = KW.w,                           # Write to disk?
  xml_file::String = "FDSNsta.xml",         # XML filename
  y::Bool = KW.y                            # Sync?
  )

  parse_err = false
  n_badreq = 0
  wc = "*"
  d0, d1 = parsetimewin(s, t)
  dt_end = DateTime(d1)
  dt1 = deepcopy(dt_end)
  dt0 = DateTime(d0)

  # (1) Time-space query for station info
  if si
    S = FDSNsta(chans,
                rad = rad,
                reg = reg,
                s = d0,
                src = src,
                t = d1,
                to = to,
                v = v,
                xml_file = xml_file)
  end

  # (2) Build ID strings for data query
  ID_str = Array{String,1}(undef,S.n)
  for i = 1:S.n
    ID_mat = split(S.id[i], ".")
    ID_mat[isempty.(ID_mat)] .= wc
    ID_str[i] = join(ID_mat, " ")
  end
  v > 1 && println(stdout, "data query strings:\n", ID_str)

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

  # Loop to grab data increments days counter dt0 by nd
  while Float64((dt_end - dt0).value) > 0.0
    if (dt1 - dt0).value > 86400000
      dt1 = dt0 + Day(nd)
    end
    qtail = string(" ", dt0, " ", dt1, "\n")
    QUERY = identity(BODY)
    for i = 1:S.n
      QUERY *= ID_str[i]*qtail
    end
    if v > 2
      printstyled(string("request url: ", URL, "\n"), color=:light_green)
      printstyled(string("request body: \n", QUERY), color=:light_green)
    end

    # Request via "POST"
    (R, parsable) = get_http_post(URL, QUERY, to)

    # Parse data (if we can)
    if parsable && (fmt == "mseed" || fmt == "miniseed")
      parsemseed!(S, IOBuffer(R), v)
    else
      parse_err = true
      n_badreq += 1
      S += SeisChannel(id = string("XX..", n_badreq),
                       misc = Dict{String,Any}( "url" => URL,
                                                "body" => QUERY,
                                                "data" => String(R) ) )
    end

    dt0 += Day(nd)
  end

  # (4) Write to disk
  # a. remove empty channels if there were no parse errors
  if !parse_err
    v > 0 && @info(tnote("Removing empty channels."))
    merge!(S)
  end

  # b. write to SAC
  if w
    v > 0 && @info(tnote("Writing data to disk."))
    writesac(S)
  end
  append!(U,S)
  # Done!
  v > 0 && @info(tnote("Done."))
  return U
end

"""
    H = FDSNevq(ot)

Multi-server query for the events with the closest origin time to `ot`.

Standard keywords: evw, rad, reg, mag, nev, src, to

See also: SeisIO.KW
"""
function FDSNevq(ot::String;
  evw::Array{Float64,1} =  KW.evw,
  rad::Array{Float64,1} = KW.rad,
  reg::Array{Float64,1} = KW.reg,
  mag::Array{Float64,1} = KW.mag,
  nev::Int64 = KW.nev,
  src::String = KW.src,
  to::Int = KW.to,
  v::Int64 = KW.v)

  if isempty(reg) && !isempty(rad)
    search_coords = string("&latitude=", rad[1], "&longitude=", rad[2].
                    "&minradius=", rad[3], "&maxradius=", rad[4],
                    "&mindepth=", rad[5], "&maxdepth=", rad[6])
  else
    if isempty(reg)
        reg = Float64[-90.0, 90.0, -180.0,180.0, -30.0, 700.0]
    end
    search_coords = string("&minlat=", reg[1], "&maxlat=", reg[2],
                           "&minlon=", reg[3], "&maxlon=", reg[4],
                           "&mindepth=", reg[5], "&maxdepth=", reg[6])
  end

  # Determine time window
  if length(ot) <= 14
    ot0 = string(ot[1:4],"-",ot[5:6],"-",ot[7:8],"T",ot[9:10],":",ot[11:12])
    if length(ot) > 12
      ot = string(ot0, ":", ot[13:14])
    else
      ot = string(ot0, ":00")
    end
  end
  ot = d2u(DateTime(ot))
  d0 = string(u2d(ot - abs(evw[1])))
  d1 = string(u2d(ot + evw[2]))
  oti = round(Int64, ot*sμ)

  # Do multi-server query (not tested)
  if lowercase(src) == "all"
    sources = collect(keys(seis_www))
  else
    sources = split(src,",")
  end
  sources = [strip(i) for i in sources]
  catalog = Array{SeisHdr,1}(undef, 0)
  ot = Array{Int64,1}(undef, 0)
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
          v > 1 && println(stdout, "REQUEST BODY:\n", String(R))
          (id, ot_tmp, loc, mm, msc) = FDSN_event_xml(String(R))
          for i = 1:length(id)
              eh = SeisHdr(id=id[i], ot=ot_tmp[i], loc=loc[:,i], mag=(mm[i], msc[i]), src=url)
              push!(catalog, eh)
              push!(ot, round(Int64, d2u(eh.ot)*sμ))
          end
          v > 1 && println(stdout, "CATALOG:\n", catalog)
      end
  end
  k = sortperm(abs.(ot.-oti))
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

See also: distaz!, FDSNevq, FDSNsta, SeisKW
"""
function FDSNevt(ot::String, chans::Union{String,Array{String,1},Array{String,2}};
  len::Real = 120.0,
  evw::Array{Float64,1} =  KW.evw,
  fmt::String = KW.fmt,
  mag::Array{Float64,1} = KW.mag,
  nd::Int64 = KW.nd,
  opts::String = KW.opts,
  pha::String = KW.pha,
  rad::Array{Float64,1} = KW.rad,
  reg::Array{Float64,1} = KW.reg,
  src::String = KW.src,
  to::Int64 = KW.to,
  v::Int64 = KW.v,
  w::Bool = KW.w)

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

  v > 0 && println(stdout, now(), ": channels initialized.")
  v > 2 && println(stdout, S)

  # Initialize SeisEvent structure
  Ev = SeisEvent(hdr = H, data = S)
  v > 0 && println(stdout, now(), ": SeisEvent created.")
  v > 1 && println(stdout, S)

  # Update Ev with distance, azimuth
  distaz!(Ev)
  v > 0 && println(stdout, now(), ": Δ,Θ updated.")

  # Add phase arrival times to S
  for i = 1:S.n
    Ev.data.misc[i]["phase_data"] = get_pha(Ev.data.misc[i]["dist"], Ev.hdr.loc[3], to=to, v=v)
    v > 2 && println(stdout, Ev.data.misc[i]["phase_data"])
  end
  return Ev
end
