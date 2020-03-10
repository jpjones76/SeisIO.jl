rand_net()    = uppercase(randstring(2))
rand_sta()    = randstring('A':'Z', rand(3:5))
rand_loc()    = rand() < 0.5 ? "" : lpad(rand(0:9), 2, "0")
rand_tmax()   = rand(1200:7200)
rand_ts()     = round(Int64, sμ*(time() - 86400.0 + randn()))
rand_irr_id() = string(rand_net(), ".", rand_sta(), ".", rand_loc(), ".OY", rand('A':'Z'))
rand_hc()     = (rand() > 0.8) ? h_crit : 1.0f0

function mk_fc(fs::Float64)
  f_min = 0.5*fs
  fc = rand(fc_vals)
  while f_min ≤ fc
    fc = rand(fc_vals)
  end
  return fc
end

function rand_reg_id(fs::Float64, s::Bool)
  bc = getbandcode(fs)
  cha, units = iccodes_and_units(bc, s)

  # faster and less memory than join(), but looks clumsy
  id = string(rand_net(), ".", randstring('A':'Z', rand(3:5)), ".", rand_loc(), ".", cha)
  return id, units
end

function rand_loc(randomize_loctype::Bool)
  y = randomize_loctype == true ? rand() : 1.0
  datum = rand_datum()
  loc = [ rand_lat(),
          rand_lon(),
          1000.0 * rand(),
          1000.0 * rand(),
          rand_lat(),
          90.0 * rand() ]
  if y > 0.25
    return GeoLoc(datum, loc...)
  else
    g = GenLoc(loc)
    g.datum = datum
    return g
  end
end

function rand_resp(fc::Float64, n::Int64)
  if n > 0
    T = Float64
    i = max(1, div(n,2))
  else
    T = rand() < 0.5 ? Float32 : Float64
    i = rand(2:2:8)
  end
  pstub = T(10.0).*rand(T, i)
  z = zeros(complex(T), 2*i)
  p = vcat(pstub .+ pstub.*im, pstub .- pstub*im)
  if T == Float32
    resp = PZResp(1.0f0, Float32(fc), p, z)
  else
    resp = PZResp64(1.0, fc, p, z)
  end
  return resp
end

# function rand_t(fs::Float64, nx::Int64)
function rand_t(fs::Float64, nx::Int64, n::Int64, gs::Int64)
  ts = rand_ts()

  ngaps = n < 0 ? rand(0:9) : n
  L = ngaps + 2
  Δ = sμ/fs
  δ = 0.5*Δ + 1.0
  t = zeros(Int64, L, 2)

  # first row is always start time; no gap in last row for now
  t[1,1] = 1
  t[1,2] = ts
  t[L,1] = nx

  # rest are random-length time gaps
  if ngaps > 0
    r = ((gs > 1) && ((nx-1)/gs > ngaps)) ? range(gs, step=gs, stop=nx-1) : range(2, step=1, stop=nx-1)
    gi = rand(r, ngaps)
    sort!(gi)
    unique!(gi)
    lg = length(gi)
    while lg < ngaps
      append!(gi, rand(r))
      sort!(gi)
      unique!(gi)
      lg = length(gi)
    end

    # Generate Gaussian-distributed gap lengths
    gl = ceil.(Int64, max.(δ, Δ .* min.(1.0e5, 10.0 .^ abs.(randn(ngaps)))))
    # .* ((-1).^rand(Bool, ngaps))

    t[2:ngaps+1,1] .= gi
    t[2:ngaps+1,2] .= gl
  end
  return t
end

function pop_chan_tail!(C::GphysChannel, c::Bool, nx::Int64)
  src_str = string("randSeisChannel(c=", c, ", nx=",  nx, ")")
  setfield!(C, :name, randstring(rand(12:64)))        # :name
  setfield!(C, :gain, rand()*10^rand(0:10))           # :gain
  setfield!(C, :loc, rand_loc(true))                  # :loc
  setfield!(C, :src, src_str)                         # :src
  setfield!(C, :misc, rand_misc(rand(4:24)))          # :misc
  note!(C, "+source ¦ " * src_str)
  return nothing
end

# Populate a channel with irregularly-sampled (campaign-style) data
function populate_irr!(C::SeisChannel, nx::Int64)
  # number of samples
  L = nx < 1 ? 2^rand(6:12) : nx

  # start time
  ts = rand_ts()

  # generate time matrix that always starts at ts with no duplicate sample times
  t_max = round(Int64, sμ*rand_tmax())
  ti = rand(1:t_max, L)
  ti[1] = zero(Int64)
  unique!(ti)
  sort!(ti)
  broadcast!(+, ti, ti, ts)
  L = length(ti)
  t  = zeros(Int64, L, 2)
  t[:,1] .= 1:L
  t[:,2] .= ti

  # eh, let's use a uniform distribution for irregularly-sampled time series
  x = (rand() > 0.5) ? rand(Float64, L) .- 0.5 : rand(Float64, L)

  # fill fields of C
  C.id      = rand_irr_id()
  C.fs      = zero(Float64)
  C.units   = rand(irregular_units)
  C.t       = t
  C.x       = x
  pop_chan_tail!(C, true, nx)

  return nothing
end

# Populate a channel with regularly-sampled (time-series) data
function populate_chan!(C::SeisChannel, s::Bool, nx::Int64, fs_min::Float64, f0::Float64)
  # determine length, fs, fc
  fs = rand(fs_vals)
  while fs < fs_min
    fs = rand(fs_vals)
  end
  Lx = nx < 1 ? ceil(Int64, fs*rand_tmax()) : nx
  gs = (fs_min ≤ 0.0) ? round(Int64, 2*fs_min) : 1
  fc = mk_fc(fs)
  resp = (f0 > 0.0) ? fctoresp(Float32(f0), rand_hc()) : rand_resp(fc, 0)

  # populate channel
  C.id, C.units = rand_reg_id(fs, s)
  C.fs     = fs                                                     # fs
  C.resp   = resp                                                   # resp
  C.t      = rand_t(fs, Lx, -1, gs)                                 # t
  C.x      = randn(rand() < 0.5 ? Float32 : Float64, Lx)            # x
  pop_chan_tail!(C, false, nx)

  return nothing
end

"""
    randSeisChannel()

Generate a random channel of geophysical time-series data as a SeisChannel.

### Keywords
| KW      | Default | Type      | Meaning                                 |
|-------- |:--------|:----------|:-------------------------------         |
| s       | false   | Bool      | force channel to have seismic data?     |
| c       | false   | Bool      | force channel to have irregular data?   |
| nx      | 0       | Int64     | number of samples in channel [^1]       |
| fs_min  | 0.0     | Float64   | channels will have fs ≥ fs_min          |
| fc      | 0.0     | Float64   | rolloff frequency [^2]                  |

[^1]: if `nx ≤ 0`, the number of samples is determined randomly
[^2]: specifing `fc` with `c=false` returns a geophone instrument response

See also: `randSeisData`, `fctoresp`
"""
function randSeisChannel(; c::Bool=false, s::Bool=false, nx::Int64=0, fs_min::Float64=0.0, fc::Float64=0.0)
  Ch = SeisChannel()
  if c == true
    populate_irr!(Ch, nx)
  else
    populate_chan!(Ch, s, nx, fs_min, fc)
  end
  return Ch
end
