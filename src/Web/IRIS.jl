function irisws(cha::String,
                 d0::String,
                 d1::String,
                fmt::String,
               opts::String,
                 to::Int64,
                  v::Integer,
                  w::Bool)

  # init
  parse_err = false
  parsable = false
  fname = ""

  # parse channel string cha
  c = (parse_chstr(cha, ',', false, false)[1,:])[1:min(end,4)]
  if isempty(c[3])
    c[3] = "--"
  end
  ID = join([c[1], c[2], strip(c[3],'-'), c[4]], '.')

  # Build query url
  url = "http://service.iris.edu/irisws/timeseries/1/query?" *
          build_stream_query(c, d0, d1) * "&scale=" * (fmt == "miniseed" ? "AUTO" : "1.0") * "&format=" * fmt
  v > 0 && println(url)
  req_info_str = datareq_summ("IRISWS data", ID, d0, d1)
  # see CHANGELOG, 2020-05-28

  # Do request
  (R, parsable) = get_http_req(url, req_info_str, to)
  if parsable
    if w
      fname = savereq(R, fmt, ID, d0)
    end

    if fmt == "sacbl"
      Ch = read_sac_stream(IOBuffer(R), false, false)
    elseif fmt == "miniseed"
      S = SeisData()
      parsemseed!(S, IOBuffer(R), KW.nx_add, KW.nx_add, true, v)
      Ch = S[1]
    elseif fmt == "geocsv"
      S = SeisData()
      read_geocsv_tspair!(S, IOBuffer(R))
      Ch = S[1]
    else
      # other parsers not supported
      parse_err = true
      Ch = SeisChannel(id = string("XX.FMT..001"),
                       misc = Dict{String,Any}(
                         "url" => url,
                         "raw" => read(IOBuffer(R))
                       )
                     )
      note!(Ch, "unparseable format; raw bytes in :misc[\"raw\"]")
    end

  else
    parse_err = true
    Ch = SeisChannel(id = string("XX.FAIL..001"),
                     misc = Dict{String,Any}(
                       "url" => url,
                       "msg" => String(read(IOBuffer(R)))
                       )
                     )
    note!(Ch, "request failed; response in :misc[\"msg\"]")
  end
  setfield!(Ch, :src, url)
  note!(Ch, "+source ¦ " * url)

  # fill :id and empty fields if no parse_err
  if parse_err == false
    setfield!(Ch, :id, ID)
    if isempty(Ch.name)
      Ch.name = deepcopy(ID)
    end
    unscale!(Ch)        # see CHANGELOG, 2020-05-28
    Ch.loc = GeoLoc()   # see CHANGELOG, 2020-05-28
  end
  if parsable && w
    push!(Ch.notes, string(timestamp(), " ¦ write ¦ get_data(\"IRIS\", ... w=true) ¦ wrote raw download to file ", fname))
  end
  return parse_err, Ch
end

# Programming note: if this method is the default, and S is only modified
# within the for loop, then S is copied to a local scope and the newly-added
# data are deleted upon return
function IRISget!(S::GphysData,
                  C::Array{String, 1},
                 d0::String,
                 d1::String,
                fmt::String,
               opts::String,
                 to::Int64,
                  v::Integer,
                  w::Bool)

  parse_err = false
  if fmt == "mseed"
    fmt = "miniseed"
  elseif fmt == "sac"
    fmt = "sacbl"
  end
  U = SeisData()
  K = size(C, 1)
  v > 0 && println("IRISWS data request begins...")
  for k = 1:K
    (p, Ch) = irisws(C[k], d0, d1, fmt, opts, to, v, w)
    push!(U, Ch)
    parse_err = max(parse_err, p)
  end
  append!(S, U)
  return parse_err
end
