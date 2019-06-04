# Things that work for both regularly and irregularly sampled data
function randResp(n::Int64=0)
  if n > 0
    T = Float64
    i = n
  else
    T = rand() < 0.5 ? Float32 : Float64
    i = rand(2:2:8)
  end
  zstub = zeros(T, 2*i)
  pstub = 10 .*rand(T, i)
  if T == Float32
    resp = PZResp(0.0f0, complex.(zstub), vcat(pstub .+ pstub.*im, pstub .- pstub*im))    # resp
  else
    resp = PZResp64(0.0, complex.(zstub), vcat(pstub .+ pstub.*im, pstub .- pstub*im))    # resp
  end
  return resp
end

function rand_t(Lx::Int64, n::Int64=0)
  ts = time()-86400+randn()
  L = n == 0 ? rand(0:9) : n
  t = zeros(2+L, 2)

  # first row is always start time
  t[1,:] = [1 round(Int64, ts/μs)]

  # rest are random time gaps
  if L > 0
    gaps = unique(rand(2:Lx, L, 1))

    # try to create exactly L gaps
    j = 0
    while j < 5
      j = j + 1
      gaps_tmp = unique(rand(2:Lx, L, 1))
      if length(gaps_tmp) > length(gaps)
        gaps = gaps_tmp
      end
      (length(gaps) == L) && break
    end
    L = length(gaps)
    
    t[2:L+1,1] = gaps
    for i = 2:L+1
      t[i,2] = round(Int64, (rand(1:100)+rand())*sμ)
    end

    # control for gap in last sample
    if any(t[:,1].==Lx) == true
      t = t[1:L+1,:]
    else
      t[L+2,:] = [Lx 0]
    end
  else
    t[2,:] = [Lx 0]
  end
  return sortslices(t, dims=1)
end

function randLoc(randtype::Bool=true)
  x = rand()
  y = randtype == true ? rand() : 1.0
  datum = x > 0.5 ? "WGS-84 " : x > 0.25 ? "ETRS89 " : x > 0.1 ? "GRS 80 " : "JGD2011"
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
  note!(Ch, "Created by function populate_chan!.")    # notes
end

# Populate a channel with irregularly-sampled (campaign-style) data
function populate_irr!(Ch::SeisChannel; nx::Int64=0)
  irregular_units = ["%", "(% cloud cover)", "(direction vector)", "C", "K", "None", "Pa", "T", "V", "W", "m", "m/m", "m/s", "m/s^2", "m^3/m^3", "rad", "rad/s", "rad/s^2", "tonnes SO2"]

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
  return nothing
end

# Populate a channel with regularly-sampled (time-series) data
function populate_chan!(Ch::SeisChannel; s::Bool=false, nx::Int64=0)
  fc_vals = Float64[1.0/120.0 1.0/60.0 1.0/30.0 0.2 1.0 1.0 1.0 2.0 4.5 15.0]
  fs_vals = Float64[0.1, 1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 40.0, 50.0, 60.0, 62.5, 80.0, 100.0, 120.0, 125.0, 250.0]
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
  Ch.t = rand_t(Lx)                                                   # t

  pop_chan_tail!(Ch)
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
    populate_irr!(Ch, nx=nx)
  else
    populate_chan!(Ch, s=s, nx=nx)
  end
  return Ch
end
