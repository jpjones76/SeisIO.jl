"""
    randSeisSrc()

Generate a SeisSrc structure filled with random values.
"""
function randSeisSrc(; mw::Float32=0.0f0)
  R = SeisSrc()

  m0 = 1.0e-7*(10^(1.5*((mw == zero(Float32) ? 10^(rand(Float64)-1.0) : Float64(mw))+10.7)))

  setfield!(R, :id, string(rand(1:2^12)))                           # :id
  setfield!(R, :m0, m0)                                             # :m0
  setfield!(R, :gap, abs(rand_lon()))                               # :gap
  setfield!(R, :misc, rand_misc(rand(4:24)))                        # :misc
  setfield!(R, :mt, m0.*(rand(6).-0.5))                             # :mt
  setfield!(R, :dm, m0.*(rand(6).-0.5))                             # :dm
  setfield!(R, :npol, rand(Int64(6):Int64(120)))                    # :npol
  [note!(R, randstring(rand(16:256))) for i = 1:rand(1:6)]          # :notes
  setfield!(R, :pax, vcat(rand_lon(2,3),
      (m0*rand() < 0.5 ? -1 : 1) .* [rand() -1.0*rand() rand()]))   # :pax
  setfield!(R, :planes, rand_lon(3,2))                              # :planes
  setfield!(R, :src, R.id * ",randSeisSrc")                         # :src
  note!(R, "+origin ¦ " * R.src)
  setfield!(R, :st, SourceTime(randstring(2^rand(6:8)), rand(), rand(), rand()))
  return R
end

"""
    randSeisHdr()

Generate a SeisHdr structure filled with random values.
"""
function randSeisHdr()
  H = SeisHdr()

  # moment magnitude and m0 in SI units
  mw = Float32(log10(10.0^rand(0.0:0.1:7.0)))
  m0 = 1.0e-7*(10^(1.5*(Float64(mw)+10.7)))

  # a random earthquake location
  dmin = 10.0^(rand()+0.5)
  dmax = dmin + exp(mw)*10.0^rand()

  loc = EQLoc(
           (rand(0.0:1.0:89.0) + rand())*-1.0^rand(1:2),
           (rand(0.0:1.0:179.0)+rand())*-1.0^rand(1:2),
           min(10.0*randexp(Float64), 660.0),
           rand()*4.0,
           rand()*4.0,
           rand()*8.0,
           rand(),
           rand(),
           rand(),
           10.0*10.0^rand(),
           dmin,
           dmax,
           4 + round(Int64, rand()*exp(mw)),
           rand(0x00:0x10:0xf0),
           rand_datum(),
           rand(loc_types),
           "",
           rand(loc_methods))

  # setfield!(loc, :sig, "1σ")
  # event type
  rtyp = rand()
  typ = rtyp > 0.3 ? "earthquake" : rand(evtypes)

  # Generate random header
  setfield!(H, :id, string(rand(1:2^62)))                           # :id
  setfield!(H, :int, (mw < 0.0f0 ? 0x00 : floor(UInt8, mw),
    randstring(rand(2:4))))                                         # :int
  setfield!(H, :loc, loc)                                           # :loc
  setfield!(H, :mag, EQMag( val   = mw,          # :mag
                            scale = (rand() < 0.5 ? "m" : "M") * randstring(2),
                            nst   = rand(3:100),
                            gap   = abs(rand_lon()),
                            src   = randstring(24)
                            )
            )
  setfield!(H, :misc, rand_misc(rand(4:24)))                        # :misc
  [note!(H, randstring(rand(16:256))) for i = 1:rand(1:6)]          # :notes
  setfield!(H, :ot, now())                                          # :ot
  setfield!(H, :typ, typ)                                           # :typ

  # header :src
  H.src = "randSeisHdr:" * H.id
  note!(H, "+origin ¦ " * H.src)
  return H
end

"""
    randPhaseCat()

Generate a random seismic phase catalog suitable for testing EventChannel,
EventTraceData, and SeisEvent objects.
"""
function randPhaseCat(n::Int64)
  npha = (n <= 0) ? rand(3:18) : n
  phase = Array{String, 1}(undef, npha)
  for j = 1:length(phase)
    phase[j] = rand(phase_list)
  end
  unique!(phase)

  P = PhaseCat()
  for j in phase
    P[j] = SeisPha(rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand(pol_list), Char(rand(0x30:0x39)))
  end
  return P
end
randPhaseCat() = randPhaseCat(0)

"""
    randSeisEvent([, c=0.2, s=0.6])

Generate a SeisEvent structure filled with random header and channel data.
* 100*c is the percentage of :data channels _after the first_ with irregularly-sampled data (fs = 0.0)
* 100*s is the percentage of :data channels _after the first_ with guaranteed seismic data.

See also: `randSeisChannel`, `randSeisData`, `randSeisHdr`, `randSeisSrc`
"""
function randSeisEvent(N::Int64; c::Float64=0.0, s::Float64=1.0, nx::Int64=0)
  V = SeisEvent(hdr=randSeisHdr(),
                source=randSeisSrc(),
                data=convert(EventTraceData, randSeisData(N, c=c, s=s, nx=nx)))
  V.source.eid = V.hdr.id
  V.hdr.loc.src = V.hdr.id * "," * V.hdr.loc.src

  for i = 1:V.data.n
    setindex!(getfield(getfield(V, :data), :pha),  randPhaseCat(),  i)
    setindex!(getfield(getfield(V, :data), :az),   rand_lat(),      i)
    setindex!(getfield(getfield(V, :data), :baz),  rand_lat(),      i)
    setindex!(getfield(getfield(V, :data), :dist), abs(rand_lon()), i)
  end
  return V
end
randSeisEvent(; c::Float64=0.0, s::Float64=1.0, nx::Int64=0) = randSeisEvent(rand(8:24), c=c, s=s, nx=nx)
