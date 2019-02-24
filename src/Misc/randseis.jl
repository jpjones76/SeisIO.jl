export randseischannel, randseisdata, randseisevent, randseishdr

OK = [0x00, 0x01, 0x10, 0x11, 0x12, 0x13, 0x14, 0x20, 0x21, 0x22, 0x23, 0x24, 0x30, 0x31, 0x32, 0x50, 0x51, 0x52, 0x53, 0x54, 0x60, 0x61, 0x62, 0x63, 0x64, 0x70, 0x71, 0x72, 0x80, 0x81, 0x90, 0x91, 0x92, 0x93, 0x94, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xb0, 0xb1, 0xb2, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xf0, 0xf1, 0xf2]
ur2() = uppercase(Random.randstring(2))

function pop_rand_dict!(D::Dict{String,Any}, N::Int)
  for n = 1:N
    t = code2typ(rand(OK))
    k = Random.randstring(rand(2:12))
    if isa(Char, t)
      D[k] = rand(Char)
    elseif isa(String, t)
      D[k] = Random.randstring(rand(1:1000))
    elseif Bool(t <: Real) == true
      D[k] = rand(t)
    elseif Bool(t <: Complex) == true
      D[k] = rand(Complex{real(t)})
    elseif Bool(t <: Array) == true
      y = eltype(t)
        if isa(y,Char)
          D[k] = Array{Char,1}([rand(Char) for i = 1:rand(Int, 1:256)])
        elseif isa(y,String)
          D[k] = Array{String,1}([Random.randstring(rand(1:256)) for i = 1:rand(Int, 1:64)])
        elseif Bool(y <: Number) == true
          D[k] = rand(y, rand(1:1000))
        end
      end
  end
  return D
end


#
#    (i,c,u) = getyp2codes(b::Char, g=false::Bool)
#
# Using band code `b`, generate quasi-sane random instrument char code (`i`)
# and channel char code (`c`), plus unit string `u`. if s=true, use only seismic
# data codes
function getyp2codes(b::Char, s=false::Bool)
  if s
    # Neglecting gravimeters ('G') and mass position sensors ('M')
    i = rand(['H','L','N'])
    if rand() > 0.2
      c = rand(['Z','N','E'])
    else
      c = rand(['A','B','C','1','2','3','U','V','W'])
    end
    if Base.in(i, ['H','L'])
      u = rand(["m", "m/s"])
    else
      u = "m/s^2"
    end
  else
    i = rand(['A','B','D','F','G','I','J','K','M','O','P','Q','R','S','T','U','V','W',
      'Z'])
    if i == 'A' # tiltmeter
      c = rand(['N','E'])
      u = "rad"
    elseif i == 'B' # creep meter
      c = '_'
      u = "m"
      # C is calibration input
    elseif i == 'D' # pressure (barometer, infrasound, hydrophone ∈ 'D')
      c = rand(['O','I','D','F','H','U'])
      u = "Pa"
      # E is an electronic test point
    elseif i == 'F' # magnetometer
      c = rand(['Z','N','E'])
      u = "T"
    elseif i == 'G' # tiltmeter
        c = rand(['A','B','C','1','2','3','U','V','W'])
        u = "m/s^2"
    elseif i == 'I' # humidity
      c = rand(['O','I','D'])
      u = "%"
    elseif i == 'J' # rotational seismometer
      c = rand(['Z','N','E','A','B','C','T','R','1','2','3','U','V','W'])
      u = rand(["rad", "rad/s", "rad/s^2"])
    elseif i == 'K' # thermal (thermometer or radiometer)
      c = rand(['O', 'I', 'D'])
      u = rand(["C","K"])
    elseif i == 'M' # mass position sensor
        c = rand(['A','B','C','1','2','3','U','V','W'])
        u = "m"
    elseif i == 'O' # current gauge
      c = '_'
      u = "m/s"
    elseif i == 'P' # very short-period geophone
      c = rand(['Z','N','E'])
      u = rand(["m", "m/s", "m/s^2"])
    elseif i == 'Q' # voltmeter
      c = '_'
      u = "V"
    elseif i == 'R' # rain gauge
      c = '_'
      u = rand(["m", "m/s"])
    elseif i == 'S' # strain gauge
      c = rand(['Z','N','E'])
      u = "m/m"
    elseif i == 'T' # tide gauge
      c = 'Z'
      u = "m"
    elseif i == 'U' # bolometer
      c = '_'
      u = "(% cloud cover)"
    elseif i == 'V' # volumetric strainmeter
      c = '_'
      u = "m^3/m^3"
    elseif i == 'W' # wind speed ('S') or direction ('D')
      c = rand(['S','D'])
      u = c == 'S' ? "m/s" : "(direction vector)"
      # X, Y are instrument-specific
    elseif i == 'Z' # synthesized beam or stack
      c = rand(['I','C','F','O'])
      u = rand(["m", "m/s", "m/s^2"])
    end
  end
  return i,c,u
end


# Things that work for both regularly and irregularly sampled data
function pop_chan_tail!(Ch::SeisChannel)
  ((Ch.gain == 1) || isnan(Ch.gain)) && (Ch.gain = rand()*10^rand(0:10))    # gain
  if isempty(Ch.loc) || Ch.loc == zeros(Float64,5)
    Ch.loc = [90, 180, 500, 90, 45].*(rand(5).-0.5)
  end                                                                       # loc
  if isempty(Ch.misc)
    pop_rand_dict!(Ch.misc, rand(4:24))                                     # misc
  end
  note!(Ch, "Created by function populate_chan!.")                          # note
end

# Populate a channel with irregularly sampled data
function populate_irr!(Ch::SeisChannel)
  irregular_units = ["%", "(% cloud cover)", "(direction vector)", "C", "K", "None", "Pa", "T", "V", "W", "m", "m/m", "m/s", "m/s^2", "m^3/m^3", "rad", "rad/s", "rad/s^2", "tonnes SO2"]

  Ch.fs = 0
  if isempty(Ch.id) || Ch.id == "...YYY"
    chan = "OY"*Random.randstring('A':'Z',1)
    net = ur2()
    sta = uppercase(Random.randstring('A':'Z', rand(1:5)))
    loc = ur2()

    # id
    Ch.id = join([net,sta,loc,chan],'.')

  end

  # units
  if isempty(Ch.units) || units == lowercase("unknown")
    Ch.units = rand(irregular_units)
  end

  if isempty(Ch.x) || isempty(Ch.t)
    ts = time()-86400+randn()
    Lx = 2^rand(1:12)
    L = rand(2:8)
    Ch.x = rand(L) .* 10 .^(rand(1:10, L))
    Ch.t = cumsum([Int64(0) round(Int64, ts/μs); zeros(Int64, L-1) round.(Int, diff(sort(rand(2:Lx, L)))/μs)], dims=1)
  end
  Ch.src = "randseischannel(c=true)"

  pop_chan_tail!(Ch)
  return nothing
end

#    populate_chan!(S::SeisChannel)
#
# Populate all empty fields of S with quasi-random values.
# s = 'Seismic'
function populate_chan!(Ch::SeisChannel; s=false::Bool)
  fc_vals = Float64[1/120 1/60 1/30 0.2 1.0 1.0 1.0 2.0 4.5 15.0]
  fs_vals = Float64[0.1, 1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 40.0, 50.0, 60.0, 62.5,
    80.0, 100.0, 120.0, 125.0, 250.0]
  bcodes = Char['V', 'L', 'M', 'M', 'B', 'S', 'S', 'S', 'S', 'S', 'S', 'H', 'S', 'E', 'E', 'C']

  # Ch.name
  isempty(Ch.name) && (Ch.name = Random.randstring(12))

  # Ch.fs
  (isempty(Ch.fs) || Ch.fs == 0 || isnan(Ch.fs)) && (Ch.fs = rand(fs_vals))

  fc = rand(fc_vals[fc_vals .< Ch.fs/2])

  # An empty ID generates codes and units to match values real data might have
  if isempty(Ch.id) || Ch.id == "...YYY"
    bcode = getbandcode(Ch.fs)
    (icode,ccode,units) = getyp2codes(bcode, s)
    chan = join([bcode, icode, ccode])
    net = ur2()
    sta = uppercase(Random.randstring('A':'Z', rand(1:5)))
    loc = rand() < 0.3 ? "" : ur2()
    Ch.id = join([net,sta,"",chan],'.')                                     # id
    if isempty(Ch.units)
      Ch.units = units                                                      # units
    end
  end

  # Need this even if Ch had an ID value when populate_chan! was called
  cha = split(Ch.id, '.')[4]
  if isempty(cha)
    ccode = 'Y'
  else
    ccode = cha[2]
  end

  # A random instrument response function
  if isempty(Ch.resp)
    if Base.in(ccode,['H','L','N'])
      i = rand(1:4)
      zstub = zeros(2*i)
      pstub = 10 .*rand(i)
      Ch.resp = [complex(zstub) [pstub .+ pstub.*im; pstub .- pstub*im]]    # resp
    end
  end

  # random noise for data, with random short time gaps; gaussian noise for a
  # time series, uniform noise with a random exponent otherwise
  if isempty(Ch.x) || isempty(Ch.t)                                         # x
    Lx = ceil(Int, Ch.fs)*(2^rand(8:12))
    Ch.x = randn(Lx)

    L = rand(0:9)
    ts = time()-86400+randn()                                               # t
    t = zeros(2+L, 2)
    t[1,:] = [1 round(Int64, ts/μs)]
    t[2:L+1,:] = [rand(2:Lx, L, 1) round.(Int, rand(L,1)./μs)]
    t[L+2,:] = [Lx 0]
    Ch.t = sortslices(t, dims=1)
  end

  Ch.src = "randseischannel(c=false)"
  pop_chan_tail!(Ch)
  return nothing
end

"""
    randseischannel()

Generate a random channel of seismic data as a SeisChannel.

"""
function randseischannel(; c=false::Bool, s=false::Bool)
  Ch = SeisChannel()
  if c == true
    populate_irr!(Ch)
  else
    populate_chan!(Ch, s=s)
  end
  return Ch
end
"""
    populate_seis!(S::SeisData)

Fill empty fields of S with random data.

    populate_seis!(S::SeisData, N)

Add N channels of random data to S.

    populate_seis!(S::SeisData, N, c=C::Float64, s=F::Float64)

Specify that (100*c)% of channels are campaign (irregularly sampled) data or
(100*s)% of channels are guaranteed to be seismic data. Note that populate_seis!
restricts channel types so that (n_seismic + n_campaign) < S.n, and n_seismic
takes precedence.

Defaults: c = 0.2, s = 0.6
"""
function populate_seis!(S::SeisData; c=0.2::Float64, s=0.6::Float64)
  n_seis = max(min(ceil(Int, s*S.n), S.n-1),0)
  n_irr = max(min(floor(Int, c*S.n), S.n-n_seis-1),0)
  data_spec = zeros(UInt8, S.n)
  data_spec[1:n_seis] .= 0x01
  data_spec[n_seis+1:n_seis+n_irr] .= 0x02
  data_spec = Random.shuffle!(data_spec)
  for i = 1:S.n
    if data_spec[i] == 0x01
      S[i] = randseischannel(s=true)
    elseif data_spec[i] == 0x02
      S[i] = randseischannel(c=true)
    else
      S[i] = randseischannel()
    end
  end
  return nothing
end
populate_seis!(S::SeisData, N::Int; c=0.2::Float64, s=0.6::Float64) =
  (U = SeisData(N); populate_seis!(U, c=c, s=s); append!(S,U))

"""
    randseisdata()

Generate 8 to 24 channels of random seismic data as a SeisData object.

    randseisdata(N)

Generate N channels of random seismic data as a SeisData object.
"""
function randseisdata(; c=0.2::Float64, s=0.6::Float64)
  S = SeisData()
  populate_seis!(S, rand(8:24), c = c, s = s)
  return S
end
function randseisdata(i::Int; c = 0.2::Float64, s = 0.6::Float64)
  S = SeisData()
  populate_seis!(S, i, c = c, s = s)
  return S
end

"""
    randseishdr()

Generate a SeisHdr structure filled with random values.
"""
function randseishdr()
  H = SeisHdr()
  setfield!(H, :id, rand(1:2^62))
  setfield!(H, :ot, now())
  setfield!(H, :loc, [(rand(0.0:1.0:89.0)+rand())*-1.0^(rand(1:2)), (rand(0.0:1.0:179.0)+rand())*-1.0^(rand(1:2)), 50.0*randexp(Float64)])
  setfield!(H, :mag, (6.0f0*rand(Float32), "M_"*Random.randstring(rand(2:4))))
  setfield!(H, :int, (UInt8(floor(Int, H.mag[1])), Random.randstring(rand(2:4))))
  setfield!(H, :mt, rand(Float64, 8))
  setfield!(H, :np, [(rand(), rand(), rand()), (rand(), rand(), rand())])
  setfield!(H, :pax, [(rand(), rand(), rand()), (rand(), rand(), rand()), (rand(), rand(), rand())])
  setfield!(H, :src, "randseishdr")
  pop_rand!(H.misc, rand(4:24))
  [note!(H, Random.randstring(rand(16:256))) for i = 1:rand(3:18)]

  # Adding a phase catalog
  return H
end

function randseisevent(; c=false::Bool)
  D = SeisData()
  populate_seis!(D, rand(8:24), c=c)
  return SeisEvent(hdr=randseishdr(), data=D)
end

function add_fake_net_code!(S::SeisData, str::String)
  if length(str) > 2
    str = str[1:2]
  end
  str = uppercase(str)
  for i = 1:S.n
    if startswith(S.id[i],'.')
      S.id[i] = join(str, S.id[i][2:end])
    end
  end
end
