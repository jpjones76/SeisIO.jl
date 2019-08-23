const evtypes = String[ "not_existing",
                        "not_reported",
                        "anthropogenic_event",
                        "collapse",
                        "cavity_collapse",
                        "mine_collapse",
                        "building_collapse",
                        "explosion",
                        "accidental_explosion",
                        "chemical_explosion",
                        "controlled_explosion",
                        "experimental_explosion",
                        "industrial_explosion",
                        "mining_explosion",
                        "quarry_blast",
                        "road_cut",
                        "blasting_levee",
                        "nuclear_explosion",
                        "induced_or_triggered_event",
                        "rock_burst",
                        "reservoir_loading",
                        "fluid_injection",
                        "fluid_extraction",
                        "crash",
                        "plane_crash",
                        "train_crash",
                        "boat_crash",
                        "other_event",
                        "atmospheric_event",
                        "sonic_boom",
                        "sonic_blast",
                        "acoustic_noise",
                        "thunder",
                        "avalanche",
                        "snow_avalanche",
                        "debris_avalanche",
                        "hydroacoustic_event",
                        "ice_quake",
                        "slide",
                        "landslide",
                        "rockslide",
                        "meteorite",
                        "volcanic_eruption"]


"""
    randSeisSrc()

Generate a SeisSrc structure filled with random values.
"""
function randSeisSrc(; mw::Float32=0.0f0)
  R = SeisSrc()

#    src:
#     st: dur 0.0, rise 0.0, decay 0.0

  m0 = 1.0e-7*(10^(1.5*((mw == zero(Float32) ? 10^(rand(Float64)-1.0) : Float64(mw))+10.7)))

  setfield!(R, :id, string(rand(1:2^62)))                           # :id
  setfield!(R, :m0, m0)                                             # :m0
  setfield!(R, :gap, rand(Float64)*180.0)                           # :gap
  pop_rand_dict!(getfield(R, :misc), rand(4:24))                    # :misc
  setfield!(R, :mt, m0.*(rand(Float64, 6).-0.5))                    # :mt
  setfield!(R, :dm, m0.*(rand(Float64, 6).-0.5))                    # :dm
  setfield!(R, :npol, rand(Int64(6):Int64(120)))                    # :npol
  [note!(R, randstring(rand(16:256))) for i = 1:rand(1:6)]          # :notes
  setfield!(R, :pax,
    vcat(360.0.*(rand(Float64, 2, 2).-0.5),
          (rand(-1:2:1)*m0).*[rand() -1.0*rand()]))                 # :pax
  setfield!(R, :planes,
    360.0.*(rand(Float64, rand(2:3), rand(2:3)).-0.5))              # :planes
  setfield!(R, :src, "randSeisSrc")                                 # :src
  # setfield!(R, :src, join([join([randstring(12), " ",
  #                           randstring(20)]) for i=1:5], ","
  #                         ))                                        # :src
  setfield!(R, :st, SourceTime( randstring(2^rand(6:8)),            # :st
                                rand(Float64),
                                rand(Float64),
                                rand(Float64)))
  return R
end

"""
    randSeisHdr()

Generate a SeisHdr structure filled with random values.
"""
function randSeisHdr()
  H = SeisHdr()

  # a random earthquake location
  loc = EQLoc()
  setfield!(loc, :lat, (rand(0.0:1.0:89.0)+rand())*-1.0^(rand(1:2)))
  setfield!(loc, :lon, (rand(0.0:1.0:179.0)+rand())*-1.0^(rand(1:2)))
  setfield!(loc, :dep, (min(10.0*randexp(Float64), 660.0)))
  setfield!(loc, :dx, rand()*4.0)
  setfield!(loc, :dy, rand()*4.0)
  setfield!(loc, :dz, rand()*8.0)
  setfield!(loc, :src, rand(["HYPOELLIPSE", "HypoDD", "Velest", "centroid"]))
  setfield!(loc, :typ, "hypocenter")
  setfield!(loc, :sig, "1σ")

  # moment magnitude and m0 in SI units
  mw = 10^(rand(Float32)-1.0f0)
  m0 = 1.0e-7*(10^(1.5*(Float64(mw)+10.7)))

  # event type
  rtyp = rand()
  typ = rtyp > 0.3 ? "earthquake" : rand(evtypes)

  # Generate random header
  setfield!(H, :id, string(rand(1:2^62)))                           # :id
  setfield!(H, :int, (floor(UInt8, mw), randstring(rand(2:4))))     # :int
  setfield!(H, :loc, loc)                                           # :loc
  setfield!(H, :mag, EQMag( val   = mw,                             # :mag
                            scale = rand(["M","m"]) * randstring(2),
                            nst   = rand(3:100),
                            gap   = 360.0*rand(Float64),
                            src   = randstring(24)
                            )
            )
  # setfield!(H, :mech, FocalMech(src = join([join([randstring(12),     # :mech
  #                                     " ",
  #                                     randstring(20)]) for i=1:5], ","),
  #                               np  = 360.0.*(rand(Float64, 3, 2).-0.5),
  #                               pax = vcat(360.0.*(rand(Float64, 2, 2).-0.5),
  #                                     (rand(-1:2:1)*m0).*[rand() -1.0*rand()]),
  #                               m0  = m0,
  #                               mt  = m0.*(rand(Float64, 6).-0.5),
  #                               dm  = m0.*(rand(Float64, 6).-0.5)
  #                               )
  #         ) # obviously not pure DC, jajaja "random"
  pop_rand_dict!(H.misc, rand(4:24))                                # :misc
  [note!(H, randstring(rand(16:256))) for i = 1:rand(1:6)]          # :notes
  setfield!(H, :ot, now())                                          # :ot
  setfield!(H, :src, "randSeisHdr")                                 # :src
  setfield!(H, :typ, typ)                                           # :typ

  return H
end

"""
    randPhaseCat()

Generate a random seismic phase catalog suitable for testing EventChannel,
EventTraceData, and SeisEvent objects.
"""
function randPhaseCat(n::Int64=0)
  phase_list = String["P", "PKIKKIKP", "PKIKKIKS", "PKIKPPKIKP", "PKPPKP",
  "PKiKP", "PP", "PS", "PcP", "S", "SKIKKIKP", "SKIKKIKS", "SKIKSSKIKS", "SKKS",
  "SKS", "SKiKP", "SP", "SS", "ScS", "pP", "pPKiKP", "pS", "pSKS", "sP",
  "sPKiKP", "sS", "sSKS"]
  pol_list = Char['U', 'D', '-', '+', '_', ' ']

  phase = Array{String,1}(undef, n == 0 ? rand(3:18) : n)
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

"""
    randSeisEvent([, c=0.2, s=0.6])

Generate a SeisEvent structure filled with random header and channel data.
* 100*c is the percentage of :data channels _after the first_ with irregularly-sampled data (fs = 0.0)
* 100*s is the percentage of :data channels _after the first_ with guaranteed seismic data.
"""
function randSeisEvent(N::Int64; c::Float64=0.0, s::Float64=1.0, nx::Int64=0)
  V = SeisEvent(hdr=randSeisHdr(),
                source=randSeisSrc(),
                data=convert(EventTraceData, randSeisData(N, c=c, s=s, nx=nx)))

  for i = 1:V.data.n
    setindex!(getfield(getfield(V, :data), :pha), randPhaseCat(), i)
    setindex!(getfield(getfield(V, :data), :az),   180*(rand()-0.5), i)
    setindex!(getfield(getfield(V, :data), :baz),  180*(rand()-0.5), i)
    setindex!(getfield(getfield(V, :data), :dist), 180*rand(),       i)
  end
  return V
end
randSeisEvent(; c::Float64=0.0, s::Float64=1.0, nx::Int64=0) = randSeisEvent(rand(8:24), c=c, s=s, nx=nx)
