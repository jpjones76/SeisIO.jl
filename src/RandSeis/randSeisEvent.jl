export randSeisHdr, randSeisEvent

"""
    randSeisHdr()

Generate a SeisHdr structure filled with random values.
"""
function randSeisHdr()
  H = SeisHdr()
  setfield!(H, :id, rand(1:2^62))
  setfield!(H, :ot, now())
  setfield!(H, :loc, [(rand(0.0:1.0:89.0)+rand())*-1.0^(rand(1:2)), (rand(0.0:1.0:179.0)+rand())*-1.0^(rand(1:2)), 50.0*randexp(Float64)])
  setfield!(H, :mag, (6.0f0*rand(Float32), "M_"*randstring(rand(2:4))))
  setfield!(H, :int, (UInt8(floor(Int, H.mag[1])), randstring(rand(2:4))))
  setfield!(H, :mt, rand(Float64, 8))
  setfield!(H, :np, [(rand(), rand(), rand()), (rand(), rand(), rand())])
  setfield!(H, :pax, [(rand(), rand(), rand()), (rand(), rand(), rand()), (rand(), rand(), rand())])
  setfield!(H, :src, "randSeisHdr")
  pop_rand_dict!(H.misc, rand(4:24))
  [note!(H, randstring(rand(16:256))) for i = 1:rand(3:18)]

  # Adding a phase catalog
  return H
end

"""
    randSeisEvent([, c=0.2, s=0.6])

Generate a SeisEvent structure filled with random header and channel data.
* 100*c is the percentage of :data channels _after the first_ with irregularly-sampled data (fs = 0.0)
* 100*s is the percentage of :data channels _after the first_ with guaranteed seismic data.
"""
randSeisEvent(; c=0.2::Float64, s=0.6::Float64) = SeisEvent(hdr=randSeisHdr(), data=randSeisData(c=c, s=s))
