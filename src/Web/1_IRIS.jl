export get_pha

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
        Ch.loc = zeros(Float64,5)
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
  req_info_str = string("\nIRIS travel time request:\nΔ = ", Δ, "\nDepth = ", z, "\nPhases = ", pq, "\nmodel = ", model)
  (R, parsable) = get_HTTP_req(url, req_info_str, to)

  if parsable
    req = String(take!(copy(IOBuffer(R))))
    v > 1 && println(stdout, "Request result:\n", req)

    # Parse results
    phase_data = split(req, '\n')
    sa_prune!(phase_data)
    Nf = length(split(phase_data[1]))
    Np = length(phase_data)
    Pha = Array{String, 2}(undef, Np, Nf)
    for p = 1:Np
      Pha[p,1:Nf] = split(phase_data[p])
    end
  else
    Pha = Array{String,2}(undef, 0, 0)
  end
  return Pha
end
