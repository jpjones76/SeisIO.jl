"""
    randSeisHdr()

Generate a SeisHdr structure filled with random values.
"""
function randSeisHdr()
  H = SeisHdr()
  loc = EQLoc()
  loc.lat = (rand(0.0:1.0:89.0)+rand())*-1.0^(rand(1:2))
  loc.lon = (rand(0.0:1.0:179.0)+rand())*-1.0^(rand(1:2))
  loc.dep = min(10.0*randexp(Float64), 660.0)

  setfield!(H, :id, rand(1:2^62))
  setfield!(H, :ot, now())
  setfield!(H, :loc, loc)
  setfield!(H, :mag, (6.0f0*rand(Float32), "M_"*randstring(rand(2:4))))
  setfield!(H, :int, (UInt8(floor(Int, H.mag[1])), randstring(rand(2:4))))
  setfield!(H, :mt, rand(Float64, 8))
  setfield!(H, :axes, [(rand(), rand(), rand()), (rand(), rand(), rand()), (rand(), rand(), rand())])
  setfield!(H, :src, "randSeisHdr")
  pop_rand_dict!(H.misc, rand(4:24))
  [note!(H, randstring(rand(16:256))) for i = 1:rand(3:18)]

  # Adding a phase catalog
  return H
end

"""
    randPhaseCat()

Generate a random seismic phase catalog suitable for testing EventChannel,
EventTraceData, and SeisEvent objects.
"""
function randPhaseCat()
  phase_list = String["P", "PKIKKIKP", "PKIKKIKS", "PKIKPPKIKP", "PKPPKP",
  "PKiKP", "PP", "PS", "PcP", "S", "SKIKKIKP", "SKIKKIKS", "SKIKSSKIKS", "SKKS",
  "SKS", "SKiKP", "SP", "SS", "ScS", "pP", "pPKiKP", "pS", "pSKS", "sP",
  "sPKiKP", "sS", "sSKS"]
  pol_list = Char['U', 'D', '-', '+', '_', ' ']

  phase = Array{String,1}(undef, rand(3:18))
  for j = 1:length(phase)
    phase[j] = rand(phase_list)
  end
  unique!(phase)

  P = PhaseCat()
  for j in phase
    P[j] = SeisPha(rand(), rand(), rand(), rand(), rand(), rand(pol_list))
  end
  return P
end

"""
    randSeisEvent([, c=0.2, s=0.6])

Generate a SeisEvent structure filled with random header and channel data.
* 100*c is the percentage of :data channels _after the first_ with irregularly-sampled data (fs = 0.0)
* 100*s is the percentage of :data channels _after the first_ with guaranteed seismic data.
"""
function randSeisEvent(; c=0.2::Float64, s=0.6::Float64)
  V = SeisEvent(hdr=randSeisHdr(), data=convert(EventTraceData, randSeisData(c=c, s=s)))

  for i = 1:V.data.n
    setindex!(getfield(getfield(V, :data), :pha), randPhaseCat(), i)
    setindex!(getfield(getfield(V, :data), :az),   180*(rand()-0.5), i)
    setindex!(getfield(getfield(V, :data), :baz),  180*(rand()-0.5), i)
    setindex!(getfield(getfield(V, :data), :dist), 180*rand(),       i)
  end
  return V
end
