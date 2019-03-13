export get_pha

function irisws(cha::String, d0, d1;
                fmt::String   = KW.fmt,
                to::Int       = KW.to,
                opts::String  = KW.opts,
                v::Int        = KW.v,
                w::Bool       = KW.w)

  # init
  Ch = SeisChannel()
  parsed = false
  if fmt == "mseed"
    fmt = "miniseed"
  end

  # parse channel string cha
  c = (parse_chstr(cha)[1,:])[1:min(end,4)]
  if isempty(c[3])
    c[3] = "--"
  end

  # Build query URL
  url = "http://service.iris.edu/irisws/timeseries/1/query?" * build_stream_query(c,d0,d1)* "&scale=AUTO&output=" * fmt
  v > 0 && println(url)

  # Do request
  R = request("GET", url, webhdr(), readtimeout=to)
  if R.status == 200
    if w
      savereq(R.body, fmt, c[1], c[2], c[3], c[4], d0, d1, "R")
    end
    if fmt == "sacbl"
      Ch = read_sac_stream(IOBuffer(R.body))
      Ch.src = url
      if isempty(Ch.name)
        Ch.name = deepcopy(Ch.id)
      end

      parsed = true
    elseif fmt == "miniseed"
      S = SeisData()
      parsemseed!(S, IOBuffer(R.body), v)
      Ch = S[1]
      Ch.src = url
      if isempty(Ch.loc)
        Ch.loc = zeros(Float64,5)
      end

      parsed = true
    else
      # other parsers not yet written
      v > 0 && @warn("Unusual format spec; returning empty channel with unparsed data in [channel].misc[\"data\"]")
    end
  else
    # This should be impossible to see
    @warn("IRISWS request failed; returning empty channel with unparsed data in [channel].misc[\"data\"]")
  end
  if parsed == false
    c[3] = strip(c[3],'-')
    setfield!(Ch, :id, join(c, '.'))
    Ch.misc["data"] = R.body
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
function get_pha(Δ::Float64, z::Float64;
  pha::String = KW.pha,
  model="iasp91"::String,
  to::Int64 = KW.to,
  v::Int64 = KW.v)

  # Generate URL and do web query
  if isempty(pha) || pha == "all"
    pq = "&phases=ttall"
  else
    pq = string("&phases=", pha)
  end

  url = string("http://service.iris.edu/irisws/traveltime/1/query?", "distdeg=", Δ, "&evdepth=", z, pq, "&model=", model, "&mintimeonly=true&noheader=true")
  v > 0 && println(stdout, "url = ", url)
  R = request("GET", url, webhdr(), readtimeout=to)

  # This assumes the request succeeds
  req = String(take!(copy(IOBuffer(R.body))))
  v > 0 && println(stdout, "Request result:\n", req)

  # Parse results
  phase_data = split(req, '\n')
  sa_prune!(phase_data)
  Nf = length(split(phase_data[1]))
  Np = length(phase_data)
  Pha = Array{String, 2}(undef, Np, Nf)
  for p = 1:Np
    Pha[p,1:Nf] = split(phase_data[p])
  end
  return Pha
end
