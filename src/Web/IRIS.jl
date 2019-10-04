# export get_pha!

function irisws(cha::String, d0::String, d1::String;
                fmt::String   = KW.fmt,
                to::Int       = KW.to,
                opts::String  = KW.opts,
                v::Int        = KW.v,
                w::Bool       = KW.w)

  # init
  parse_err = false
  S = SeisData()
  Ch = SeisChannel()
  parsable = false
  if fmt == "mseed"
    fmt = "miniseed"
  end

  # parse channel string cha
  c = (parse_chstr(cha)[1,:])[1:min(end,4)]
  if isempty(c[3])
    c[3] = "--"
  end
  ID = join([c[1], c[2], strip(c[3],'-'), c[4]], '.')
  setfield!(Ch, :id, ID)

  # Build query URL
  url = "http://service.iris.edu/irisws/timeseries/1/query?" *
          build_stream_query(c,d0,d1) * "&scale=AUTO&output=" * fmt
  v > 0 && println(url)
  Ch.src = url
  req_info_str = datareq_summ("IRISWS data", ID, d0, d1)

  # Do request
  (R, parsable) = get_http_req(url, req_info_str, to)
  if parsable
    if w
      savereq(R, fmt, Ch.id, d0)
    end
    if fmt == "sacbl"
      Ch = read_sac_stream(IOBuffer(R), BUF.sac_fv, BUF.sac_iv, BUF.sac_cv, false, false)
      if isempty(Ch.name)
        Ch.name = deepcopy(Ch.id)
      end
    elseif fmt == "miniseed"
      parsemseed!(S, IOBuffer(R), v, KW.nx_add, KW.nx_add)
      Ch = S[1]
      if isempty(Ch.loc)
        Ch.loc = GeoLoc()
      end
    elseif fmt == "geocsv"
      read_geocsv_tspair!(S, IOBuffer(R))
      Ch = S[1]
    else
      # other parsers not yet written
      @warn(string("Unsupported data format", req_info_str, "\nFORMAT = ", fmt,
            "\n\nUnparsed request data in .misc[\"data\"]"))
      Ch.misc["data"] = R
    end
  else
    parse_err = true
    Ch.misc["data"] = String(R)
  end
  return parse_err, Ch
end

function IRISget(C::Array{String,1}, d0::String, d1::String;
                  fmt::String   = KW.fmt,
                  to::Int       = KW.to,
                  opts::String  = KW.opts,
                  v::Int        = KW.v,
                  w::Bool       = KW.w)

  parse_err = false
  S = SeisData()
  K = size(C,1)
  v > 0 && println("IRISWS data request begins...")
  for k = 1:K
    (p, Ch) = irisws(C[k], d0, d1, fmt = fmt, opts = opts, to = to, v = v, w = w)
    S += Ch
    parse_err = max(parse_err, p)
  end
  return parse_err, S
end

# Programming note: if this method is the default, and S is only modified
# within the for loop, then S is copied to a local scope and the newly-added
# data are deleted upon return
function IRISget!(S::SeisData, C::Array{String,1}, d0::String, d1::String;
                  fmt::String   = KW.fmt,
                  to::Int       = KW.to,
                  opts::String  = KW.opts,
                  v::Int        = KW.v,
                  w::Bool       = KW.w)

  (parse_err, U) = IRISget(C, d0, d1, fmt = fmt, to = to, opts = opts, v = v, w = w)
  append!(S,U)
  return parse_err
end
