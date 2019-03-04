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
    try
      id[i] = Int64(Meta.parse(String(split(attribute(evt, "publicID"),'=')[2])))
    catch
      id[i] = 0
    end

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
    LOC   = Array{Array{Float64,1}}(undef, N)
    UNITS = collect(Main.Base.Iterators.repeated("unknown",N))
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
                LOC[y]              = zeros(Float64,5)
                LOC[y][1:3]         = copy(loc_tmp)
                LOC[y][4]           = LightXML_float!(0.0, cha, "Azimuth")
                LOC[y][5]           = LightXML_float!(0.0, cha, "Dip") - 90.0
                GAIN[y]             = 1.0
                MISC[y]["normfreq"] = 1.0

                xresp = LightXML_findall(cha, "Response")
                if !isempty(xresp)
                    MISC[y]["normfreq"] = LightXML_float!(0.0, xresp[1], "InstrumentSensitivity/Frequency")
                    GAIN[y]             = LightXML_float!(1.0, xresp[1], "InstrumentSensitivity/Value")
                    UNITS[y]            = LightXML_str!("unknown", xresp[1], "InstrumentSensitivity/InputUnits/Name")

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
    return ID, LOC, UNITS, GAIN, RESP, NAME, MISC
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
  t = (-600)::Union{Real,DateTime,String},  # End or Length (s)
  src::String = KW.src,
  to::Int = KW.to,
  v::Int64 = KW.v)

  d0, d1 = parsetimewin(s, t)
  C = FDSN_chp(chans, v=v)

  for j = 1:size(C,1)
    new_id = join(C[j,1:4], '.')
    utail = build_stream_query(C[j,:], d0, d1)
    station_url = string(fdsn_uhead(src), "station/1/query?level=response&", utail)
    v > 1 && println(stdout, "station url = ", station_url)
    R = request("GET", station_url, webhdr(), readtimeout=to)
    if R.status == 200
      (ID, LOC, UNITS, GAIN, RESP, NAME, MISC) = FDSN_sta_xml(String(take!(copy(IOBuffer(R.body)))))
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
    else
      @warn(string("FDSNsta! web request failed, ID=", new_id, ". Nothing done."))
    end
  end
  return nothing
end

function FDSNget!(seis::SeisIO.SeisData, C::Array{String,2}, d0::String, d1::String;
  fmt::String = KW.fmt,
  opts::String = KW.opts,
  q::Char = KW.char,
  si::Bool = KW.si,
  src::String = KW.src,
  to::Int = KW.to,
  v::Int64 = KW.v,
  w::Bool = KW.w)

  uhead = fdsn_uhead(src)
  # Trying to avoid scoping problems
  S = SeisData()
  for j = 1:size(C,1)
    parsed = false
    new_id = join(C[j,1:4], '.')

    # build URL
    utail = build_stream_query(C[j,:], d0, d1)
    data_url = string(uhead, "dataselect/1/query?quality=", q, "&format=", fmt, "&", utail)
    if !isempty(opts)
      data_url *= string("&", opts)
    end
    if v > 1
      println(stdout, "data url = ", data_url)
    end

    # Get data
    track_on!(S)
    R = request("GET", data_url, webhdr(), readtimeout=to)
    if R.status == 200
      if w == true
        savereq(R.body, fmt, C[j,1], C[j,2], C[j,3], C[j,4], d0, d1, string(q))
      end

      # Parse data
      if fmt == "mseed" || fmt == "miniseed"
        parsemseed!(S, IOBuffer(R.body), v)
        parsed = true
      end
    else
      @warn(string("FDSNWS request failed: returning as a channel with ID= ", new_id,
      " and request data in [channel].misc[\"data\"]"))
    end

    # When there is no parser
    if parsed
      # Which channels are new?
      u = track_off!(S)
      S.src[u] .= data_url
    else
      @info(string("Not parsed: ID = ", new_id,
            ". Returned as a new channel with request body in [channel].misc[\"data\"]"))
      Ch = SeisChannel()
      setfield!(Ch, :id, new_id)
      Ch.misc["data"] = R.body
      push!(S, Ch)
    end
  end

  # Are we auto-filling station data?
  if si == true
    FDSNsta!(S, C, s = d0, t = d1, src = src, to = to, v = v)
  end

  # Merge into seis
  merge!(seis, S)

  return nothing
end

"""
    H = FDSNevq(ot)

Multi-server query for the events with the closest origin time to `ot`.

Standard keywords: evw, reg, mag, nev, src, to

See also: SeisIO.KW
"""
function FDSNevq(ot::String;
  reg::Array{Float64,1} = KW.reg,
  mag::Array{Float64,1} = KW.mag,
  nev::Int64 = KW.nev,
  src::String = KW.src,
  to::Int = KW.to,
  evw::Array{Float64,1} =  KW.evw,
  v::Int64 = KW.v)

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
  s = string(u2d(ot - evw[1]*(evw[1] > 0.0 ? 1.0 : -1.0)))
  t = string(u2d(ot + evw[2]))
  oti = round(Int64, ot*sμ)

  # Do multi-server query (not tested)
  if lowercase(src) == "all"
    sources = collect(keys(seis_www))
  else
    sources = split(src,",")
  end
  catalog = Array{SeisHdr,1}()
  ot = Array{Int64,1}()
  for k in sources
      v > 1 && println(stdout, "Querying ", k)
      url = string(fdsn_uhead(String(k)), "event/1/query?",
                                          "starttime=", s, "&endtime=", t,
                                          "&minlat=", reg[1], "&maxlat=", reg[2],
                                          "&minlon=", reg[3], "&maxlon=", reg[4],
                                          "&mindepth=", reg[5], "&maxdepth=", reg[6],
                                          "&minmag=", mag[1], "&maxmag=", mag[2],
                                          "&format=xml")
      v > 0 && println(stdout, "URL = ", url)
      R = request("GET", url, webhdr(), readtimeout=to)
      if R.status == 200
          v > 1 && println(stdout, "REQUEST BODY:\n", String(take!(copy(IOBuffer(R.body)))))
          (id, ot_tmp, loc, mm, msc) = FDSN_event_xml(String(take!(copy(IOBuffer(R.body)))))
          for i = 1:length(id)
              eh = SeisHdr(id=id[i], ot=ot_tmp[i], loc=loc[:,i], mag=(mm[i], msc[i]), src=url)
              push!(catalog, eh)
              push!(ot, round(Int64, d2u(eh.ot)*sμ))
          end
          v > 1 && println(stdout, "CATALOG:\n", catalog)
      end
  end
  if isempty(ot)
      return catalog
  else
    k = sortperm(abs.(ot.-oti))
    n0 = min(length(k), nev)
    n0 < nev && @warn(string("Catalog only contains ", n0, " events (original request was ", nev,")"))
    return catalog[k[1:n0]]
  end
end

"""
    S = FDSNsta(chans, KW)

Retrieve station/channel info for formatted parameter file (or string) `chans`
into an empty SeisData structure.

Standard keywords: src, to, v

Other keywords:
* s: Start time
* t: Termination (end) time

See also: chanspec, parsetimewin, get_data!, SeisIO.KW
"""
function FDSNsta( chans::Union{String,Array{String,1},Array{String,2}};
                  src::String = KW.src,
                  s::Union{Real,DateTime,String} = 0,
                  t::Union{Real,DateTime,String} = (-600),
                  to::Int = KW.to,
                  v::Int64 = KW.v)

  d0, d1 = parsetimewin(s, t)
  CC = FDSN_chp(chans, v=v)
  uhead = string(fdsn_uhead(src), "station/1/query?")
  seis = SeisData()

  for j = 1:size(CC,1)
    utail = build_stream_query(CC[j,:], d0, d1) * "&format=text&level=channel"
    sta_url = string(uhead, utail)
    v > 0 && println(stdout, "Retrieving station data from URL = ", sta_url)
    R = request("GET", sta_url, webhdr(), readtimeout=to)
    if R.status == 200
      ch_data = String(R.body) #read(R, String)
      v > 0 && println(stdout, ch_data)
      ch_data = split(ch_data,"\n")
      for n = 2:size(ch_data,1)-1
        C = split(ch_data[n],"|")
        try
          #Network | Station | Location | Channel
          ID = @sprintf("%s.%s.%s.%s",C[1],C[2],C[3],C[4])
          NAME = ID
          LOC = Float64[Meta.parse(C[5]), Meta.parse(C[6]), Meta.parse(C[7])+Meta.parse(C[8]), Meta.parse(C[9]), 90.0-Meta.parse(C[10])]

          # fctopz to create a sensor response is only accurate for passive velocity sensors
          RESP = fctopz(Float64(Meta.parse(C[13])))
          MISC = Dict{String,Any}(
                                    "SensorDescription" => String(C[11]),
                                    "SensorStart" => String(C[16]),
                                    "SensorEnd" => String(C[17])
                                  )
          Ch = SeisChannel(name = NAME,
                          id = ID,
                          fs = Float64(Meta.parse(C[15])),
                          gain = Float64(Meta.parse(C[12])),
                          loc = LOC,
                          misc = MISC,
                          resp = RESP,
                          src = sta_url,
                          units = String(C[14])
                          )
          note!(Ch, string("Channel info from FDSNsta: ", src))
          seis += Ch
        catch err
          ID = @sprintf("%s.%s.%s.%s",C[1],C[2],C[3],C[4])
          @warn("Failed to parse ", ID,"; caught $err. Maybe bad or missing parameter(s) returned by server.")
          if v > 0
            println(stdout, "Text dump of bad record line follows:")
            println(stdout, ch_data[n])
          end
        end
      end
    end
  end
  return seis
end

"""
    FDSNevt(ot::String, chans::String)

Get trace data for the event closest to origin time `ot` on channels `chans`.

Standard keywords: fmt, mag, opts, pha, q, src, to, v, w

Other keywords:
* len::Real (120.0): desired record length in minutes

See also: distaz!, FDSNevq, FDSNsta, SeisKW
"""
function FDSNevt(ot::String, chans::Union{String,Array{String,1},Array{String,2}};
  len::Real = 120.0,
  fmt::String = KW.fmt,
  mag::Array{Float64,1} = KW.mag,
  opts::String = KW.opts,
  pha::String = KW.pha,
  q::Char = KW.q,
  src::String = KW.src,
  to::Int64 = KW.to,
  v::Int64 = KW.v,
  w::Bool = KW.w)

  C = FDSN_chp(chans, v=v)

  # Create header
  H = FDSNevq(ot, nev=1, mag=mag, to=to, v=v)[1]  # Get event of interest with FDSNevq
  v > 0 && println(stdout, now(), ": header query complete.")

  # Create channel data
  s = H.ot                                      # Start time for FDSNsta is event origin time
  t = u2d(d2u(s) + 60*len)                      # End time is len minutes later
  (d0, d1) = parsetimewin(s,t)
  S = SeisData()
  FDSNget!(S, C, d0, d1, fmt=fmt, opts=opts, q=q, si=true, src=src, to=to, v=v, w=w)
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
