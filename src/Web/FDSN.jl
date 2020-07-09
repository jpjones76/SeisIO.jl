# export FDSNevq, FDSNevt, FDSNsta
export FDSNsta

# =============================================================================
# No export

function fdsn_chp(chans::ChanOpts, v::Integer)
  # Parse channel config
  if isa(chans, String)
    C = parse_chstr(chans, ',', true, false)
  elseif isa(chans, Array{String, 1})
    C = parse_charr(chans, '.', true)
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
* msr: get MultiStage (full) responses?
* s: Start time
* t: Termination (end) time
* xf: Name of XML file to save station metadata

See also: `web_chanspec`, `parsetimewin`, `get_data!`, `SeisIO.KW`
"""
function FDSNsta( chans::ChanOpts="*";
                    msr::Bool              = false,          # MultiStageResp
                    rad::Array{Float64,1}  = KW.rad,         # Search radius
                    reg::Array{Float64,1}  = KW.reg,         # Search region
                      s::TimeSpec          = 0,              # Start
                    src::String            = KW.src,         # Source server
                      t::TimeSpec          = (-600),         # End or Length (s)
                     to::Int64             = KW.to,          # Read timeout (s)
                      v::Integer           = KW.v,           # Verbosity
                     xf::String            = "FDSNsta.xml"   # XML filename
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
    C = fdsn_chp(chans, v)
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
  S = FDSN_sta_xml(xsta, msr, d0, d1, v)

  # ===================================================================
  # Logging
  note!(S, string( "+meta ¦ ", URL ))
  for i in 1:S.n
    id = split_id(S.id[i])
    if isempty(id[3])
      id[3] = "--"
    end
    note!(S, i, string("POST ¦ ", join(id, " "), " ", d0, " ", d1))
  end
  # ===================================================================

  return S
end

function FDSNget!(U::SeisData,
              chans::ChanOpts,
                 d0::String,
                 d1::String,
           autoname::Bool,
                fmt::String,
                msr::Bool,
                 nd::Real,
               opts::String,
                rad::Array{Float64,1},
                reg::Array{Float64,1},
                 si::Bool,
                src::String,
                 to::Int64,
                  v::Integer,
                  w::Bool,
                 xf::String,
                  y::Bool)

  parse_err = false
  n_badreq = 0
  wc = "*"
  fname = ""

  # (1) Time-space query for station info
  S = (if si
    FDSNsta(chans,
             msr = msr,
             rad = rad,
             reg = reg,
               s = d0,
             src = src,
               t = d1,
              to = to,
               v = v,
              xf = xf
            )
  else
    SeisData()
  end)

  # (1a) Can we autoname the file? True iff S.n == 1
  (S.n == 1) || (autoname = false)

  # (2) Build ID strings for data query
  ID_str = Array{String,1}(undef, S.n)
  if S.n > 0
    N_ch = S.n
    for i in 1:N_ch
      ID_mat = split(S.id[i], ".")
      ID_mat[isempty.(ID_mat)] .= wc
      ID_str[i] = join(ID_mat, " ")
    end
  else
    C = fdsn_chp(chans, v)[:,1:4]
    C[isempty.(C)] .= "*"
    N_ch = size(C,1)
    ID_str = [join(C[i, :], " ") for i in 1:N_ch]
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
  if occursin("ncedc", URL) || occursin("scedc", URL)
    BODY = ""
    if fmt != "miniseed"
      @warn(string("format ", fmt, " ignored; server only allows miniseed."))
    end
  elseif occursin("ph5ws",URL)
    BODY = "reqtype=FDSN\n"
    if fmt ∉ ["mseed","miniseed","sac","segy1","segy2","geocsv","geocsv.tspair","geocsv.slist"]
      @warn(string("format ", fmt, " ignored; server only allows:\n" *
        "mseed\n" *
        "sac\n" *
        "segy1\n" *
        "geocsv\n" *
        "geocsv.tspair\n" *
        "geocsv.slist")
      )
    end
    fmt = fmt == "miniseed" ? "mseed" : fmt
    BODY *= "format=" * fmt * "\n"
    if !isempty(opts)
      OPTS = split(opts, "&")
      for opt in OPTS
        BODY *= string(opt, "\n")
      end
    end
  else
    BODY = "format=" * fmt * "\n"
    if !isempty(opts)
      OPTS = split(opts, "&")
      for opt in OPTS
        BODY *= string(opt, "\n")
      end
    end
  end

  # Set the data source
  fill!(S.src, URL)

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
    for i = 1:N_ch
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

      # Generate filename
      yy = s_str[1:4]
      mm = s_str[6:7]
      dd = s_str[9:10]
      HH = s_str[12:13]
      MM = s_str[15:16]
      SS = s_str[18:19]
      nn = lpad(div(parse(Int64, s_str[21:26]), 1000), 3, '0')
      jj = lpad(md2j(yy, mm, dd), 3, '0')
      if autoname
        fname = join([yy, jj, HH, MM, SS, nn, S.id[1], "R", ext], '.')
      else
        fname = join([yy, jj, HH, MM, SS, nn, "FDSNWS", src, ext], '.')
      end
      safe_isfile(fname) && @warn(string("File ", fname, " contains an identical request; overwriting."))
      open(fname, "w") do io
        request("POST", URL, webhdr, QUERY, readtimeout=to, response_stream=io)
      end
      io = open(fname, "r")
      parsable = true
    else
      (R, parsable) = get_http_post(URL, QUERY, to)
      io = IOBuffer(R)
    end
    (v > 1) && println("parsable = ", parsable)

    # Parse data (if we can)
    if parsable
      if fmt == "mseed" || fmt == "miniseed"
        parsemseed!(S, io, KW.nx_add, KW.nx_add, true, v)
      elseif fmt == "geocsv" || fmt == "geocsv.tspair"
        read_geocsv_tspair!(S, io)
      elseif fmt == "geocsv.slist"
        read_geocsv_slist!(S, io)
      else
        parse_err = true
        n_badreq += 1
        push!(S, SeisChannel(id = string("XX.FMT..", lpad(n_badreq, 3, "0")),
                             misc = Dict{String,Any}(  "url" => URL,
                                                      "body" => QUERY,
                                                       "raw" => read(io))))
        note!(S, S.n, "unparseable format; raw bytes in :misc[\"raw\"]")
      end
    else
      # Should only happen with an error message (parsable to String) in io
      parse_err = true
      n_badreq += 1
      push!(S, SeisChannel(id = string("XX.FAIL..", lpad(n_badreq, 3, "0")),
                           misc = Dict{String,Any}( "url" => URL,
                                                   "body" => QUERY,
                                                    "msg" => String(read(io)))))
      note!(S, S.n, "request failed; response in :misc[\"msg\"]")
    end
    close(io)
    ts += ti
  end

  # ===================================================================
  # Logging
  note!(S, string( "+source ¦ ", URL ))
  for i in 1:S.n
    id = split_id(S.id[i])
    if isempty(id[3])
      id[3] = "--"
    end
    note!(S, i, string("POST ¦ ", join(id, " "), " ", d0, " ", d1))
    if w
      wstr = string(timestamp(), " ¦ write ¦ get_data(\"FDSN\" ... w=true) ¦ wrote raw download to file ", fname)
      for i in 1:S.n
        push!(S.notes[i], wstr)
      end
    end
  end
  # ===================================================================

  append!(U,S)
  # Done!
  v > 0 && @info(string(timestamp(), ": done FDSNget query."))
  v > 1 && @info(string("n_badreq = ", n_badreq))
  return parse_err
end
