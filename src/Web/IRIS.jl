export get_pha!

function irisws(cha::String, d0::String, d1::String;
                fmt::String   = KW.fmt,
                to::Int       = KW.to,
                opts::String  = KW.opts,
                v::Int        = KW.v,
                w::Bool       = KW.w)

  # init
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
  (R, parsable) = get_HTTP_req(url, req_info_str, to)
  if parsable
    if w
      savereq(R, fmt, c[1], c[2], c[3], c[4], d0, d1, "R")
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
    Ch.misc["data"] = String(R)
  end
  return Ch
end

function IRISget(C::Array{String,1}, d0::String, d1::String;
                  fmt::String   = KW.fmt,
                  to::Int       = KW.to,
                  opts::String  = KW.opts,
                  v::Int        = KW.v,
                  w::Bool       = KW.w)

  S = SeisData()
  K = size(C,1)
  v > 0 && println("IRISWS data request begins...")
  for k = 1:K
    S += irisws(C[k], d0, d1, fmt = fmt, opts = opts, to = to, v = v, w = w)
  end
  return S
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

  U = IRISget(C, d0, d1, fmt = fmt, to = to, opts = opts, v = v, w = w)
  merge!(S,U)
  return nothing
end

"""
    T = get_pha(Δ::Float64, z::Float64)

Command-line interface to IRIS online travel time calculator, which calls TauP [1-2].
Returns a matrix of strings.

Specify Δ in decimal degrees, z in km treating down as +.

Standard keywords: pha, to, v

Additional keywords:
* model: velocity model ("iasp91")

### References
[1] TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf
[2] Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit:
Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.
"""
function get_pha!(Ev::SeisEvent;
                  pha::String   = KW.pha,
                  model::String = "iasp91",
                  to::Int64     = KW.to,
                  v::Int64      = KW.v
                  )

  # Check that distaz has been done
  TD = getfield(Ev, :data)
  N = getfield(TD, :n)
  z = zeros(Float64, N)
  if (TD.az == z) && (TD.baz == z) && (TD.dist == z)
    v > 0 && println(stdout, "az, baz, and dist are unset; calling distaz!...")
    distaz!(Ev)
  end

  # Generate URL and do web query
  src_dep = getfield(getfield(getfield(Ev, :hdr), :loc), :dep)
  if isempty(pha) || pha == "all"
    pq = "&phases=ttall"
  else
    pq = string("&phases=", pha)
  end
  url_tail = string("&evdepth=", src_dep, pq, "&model=", model, "&mintimeonly=true&noheader=true")

  # Loop begins
  dist = getfield(TD, :dist)
  PC = getfield(TD, :pha)
  for i = 1:N
    Δ = getindex(dist, i)
    pcat = getindex(PC, i)

    url = string("http://service.iris.edu/irisws/traveltime/1/query?", "distdeg=", Δ, url_tail)
    v > 1 && println(stdout, "url = ", url)

    req_info_str = string("\nIRIS travel time request:\nΔ = ", Δ, "\nDepth = ", z, "\nPhases = ", pq, "\nmodel = ", model)
    (R, parsable) = get_HTTP_req(url, req_info_str, to)

    # Parse results
    if parsable
      req = String(take!(copy(IOBuffer(R))))
      pdat = split(req, '\n')
      deleteat!(pdat, findall(isempty, pdat))   # can have trailing blank line
      npha = length(pdat)
      for j = 1:npha
        pha = split(pdat[j], keepempty=false)
        pcat[pha[10]] = SeisPha(parse(Float64, pha[8]),
                                parse(Float64, pha[4]),
                                parse(Float64, pha[5]),
                                parse(Float64, pha[6]),
                                parse(Float64, pha[7]),
                                ' ')
      end
    end
  end
  return nothing
end
