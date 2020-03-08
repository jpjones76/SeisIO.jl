function rand_datum()
  x = rand()
  return x > 0.5 ? "WGS-84 " : x > 0.25 ? "ETRS89 " : x > 0.1 ? "GRS 80 " : "JGD2011"
end

# Things that work for both regularly and irregularly sampled data
function randResp(n::Int64=0)
  if n > 0
    T = Float64
    i = max(1, div(n,2))
  else
    T = rand() < 0.5 ? Float32 : Float64
    i = rand(2:2:8)
  end
  zstub = zeros(T, 2*i)
  pstub = 10 .*rand(T, i)
  if T == Float32
    resp = PZResp(a0 = 1.0f0, f0 = 1.0f0, p = vcat(pstub .+ pstub.*im, pstub .- pstub*im), z = complex.(zstub))    # resp
  else
    resp = PZResp64(a0 = 1.0, f0 = 1.0, p = vcat(pstub .+ pstub.*im, pstub .- pstub*im), z = complex.(zstub))    # resp
  end
  return resp
end

# function rand_t(fs::Float64, nx::Int64)
function rand_t(fs::Float64, nx::Int64, n::Int64)
  ts = time()-86400+randn()
  ngaps = n < 0 ? rand(0:9) : n
  L = ngaps + 2

  Δ = ceil(Int64, sμ/fs)
  δ = Float64(div(Δ, 2) + 1)
  t = zeros(Int64, L, 2)

  # first row is always start time; no gap in last row for now
  t[1,1] = 1
  t[1,2] = round(Int64, ts/μs)
  t[L,1] = nx

  # rest are random-length time gaps
  if ngaps > 0
    gi = sort(rand(2:nx, ngaps))
    ui = unique(gi)
    lg = length(ui)
    while lg < ngaps
      gi = copy(ui)
      append!(gi, rand(2:nx, ngaps-lg))
      sort!(gi)
      ui = unique(gi)
      lg = length(ui)
    end

    # Generate exponentially-distributed gap lengths
    gl = ceil.(Int64, max.(δ, Δ .* 10.0 .^ randexp(ngaps)))

    t[2:ngaps+1,1] .= gi
    t[2:ngaps+1,2] .= gl
  end
  return t
end

function randLoc(randtype::Bool=true)
  y = randtype == true ? rand() : 1.0
  datum = rand_datum()
  loc = [ 180*(rand()-0.5),
          360*(rand()-0.5),
          1000*rand(),
          100*rand(),
          360*(rand()-0.5),
          180*(rand()-0.5) ]
  if y > 0.5
    return GeoLoc(datum, loc...)
  else
    g = GenLoc(loc)
    g.datum = datum
    return g
  end
end

function pop_chan_tail!(Ch::SeisChannel)
  setfield!(Ch, :name, randstring(rand(12:64)))       # name
  setfield!(Ch, :gain,  rand()*10^rand(0:10))         # gain
  setfield!(Ch, :loc, randLoc())                      # loc
  pop_rand_dict!(Ch.misc, rand(4:24))                 # misc
end

# Populate a channel with irregularly-sampled (campaign-style) data
function populate_irr!(Ch::SeisChannel, nx::Int64)
  chan = "OY"*randstring('A':'Z',1)
  net = ur2()
  sta = uppercase(randstring('A':'Z', rand(1:5)))
  loc = ur2()

  ts = round(Int, sμ*(time()-86400+randn()))
  if nx == 0
    L = 2^rand(6:12)
  else
    L = nx
  end
  Ls = rand(1200:7200)

  Ch.id     = join([net,sta,loc,chan],'.')
  Ch.fs     = 0
  Ch.src    = string("randSeisChannel(c=true, nx=",  nx, ")")
  Ch.units  = rand(irregular_units)
  Ch.t      = hcat(collect(1:1:L), ts.+sort(rand(UnitRange{Int64}(1:Ls), L)))
  Ch.x      = (rand(L) .- (rand(Bool) == true ? 0.5 :  0.0)).*(10 .^ (rand(1:10, L)))
  pop_chan_tail!(Ch)
  note!(Ch, "+source ¦ " * Ch.src)
  return nothing
end

# Populate a channel with regularly-sampled (time-series) data
function populate_chan!(Ch::SeisChannel, s::Bool, nx::Int64)

  bcodes  = Char['V', 'L', 'M', 'M', 'B', 'S', 'S', 'S', 'S', 'S', 'S', 'H', 'S', 'E', 'E', 'C']

  # Ch.fs
  fs = rand(fs_vals)
  fc = rand(fc_vals[fc_vals .< fs/2])

  # An empty ID generates codes and units to match values real data might have
  bc = getbandcode(fs)
  (ic, cc, units) = getyp2codes(bc, s)
  sta = randstring('A':'Z', rand(3:5))
  loc = rand() < 0.5 ? "" : ur2()
  cha = string(bc, ic, cc)

  Ch.id     = join([ur2(), sta, loc, cha],'.')                        # id
  Ch.fs     = fs                                                      # fs
  Ch.units  = units                                                   # units
  Ch.resp   = randResp()                                              # resp
  Ch.src    = string("randSeisChannel(c=false, nx=",  nx, ")")        # src

  # random noise for data, with random time gaps
  if nx == 0
    Ls = rand(1200:7200)
    Lx = ceil(Int, Ls*Ch.fs)
  else
    Lx = nx
  end
  Ch.x = randn(rand() < 0.5 ? Float32 : Float64, Lx)                  # x
  Ch.t = rand_t(fs, Lx, -1)                                           # t

  pop_chan_tail!(Ch)
  note!(Ch, "+source ¦ " * Ch.src)
  return nothing
end

"""
    randSeisChannel()

Generate a random channel of geophysical time-series data as a SeisChannel.

    randSeisChannel(c=true)

Generate a random channel of irregularly-sampled data.

    randSeisChannel(s=true)

Generate a random channel of regularly-sampled seismic data.
"""
function randSeisChannel(; c::Bool=false, s::Bool=false, nx::Int64=0)
  Ch = SeisChannel()
  if c == true
    populate_irr!(Ch, nx)
  else
    populate_chan!(Ch, s, nx)
  end
  return Ch
end
