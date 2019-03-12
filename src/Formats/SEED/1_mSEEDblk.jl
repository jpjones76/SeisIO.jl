# All blockette functions return a UInt16 value equal to blockette length in bytes
function blk_time!(t::Array{Int32,1}, sid::IOStream, b::Bool)
  yy    = read(sid, UInt16)
  jj    = read(sid, UInt16)
  t[4]  = Int32(read(sid, UInt8))
  t[5]  = Int32(read(sid, UInt8))
  t[6]  = Int32(read(sid, UInt8))
  skip(sid, 1)
  ms    = read(sid, UInt16)
  if b
    yy = ntoh(yy)
    jj = ntoh(jj)
    ms = ntoh(ms)
  end
  yy = Int32(yy)
  jj = Int32(jj)
  t[1] = yy
  (t[2], t[3]) = j2md(yy, jj)
  t[7] = div(Int32(ms), Int32(10))
  return nothing
end

# [100] Sample Rate Blockette (12 bytes)
function blk_100(S::SeisIO.SeisData, sid::IO, c::Int64)
  SEED.dt = Float64(SEED.swap ? ntoh(read(sid, Float32)) : read(sid, Float32))
  skip(sid, 4)
  return 0x000c
end

# [201] Murdock Event Detection Blockette (60 bytes)
function blk_201(S::SeisIO.SeisData, sid::IO, c::Int64)
  read!(sid, SEED.B201.sig)                             # amplitude, period, background estimate
  SEED.B201.flags = read(sid, UInt8)                    # detection flags
  skip(sid, 1)                                          # reserved
  blk_time!(SEED.B201.t, sid, SEED.swap)                # onset time
  read!(sid, SEED.B201.snr)                             # snr, lookback, pick algorithm
  SEED.B201.det  = String(read(sid, 24, all=false))     # detector name

  # will store as a string: t_evt, :sig (3 vals), bittsring(:flags), :snr, :lb, :p)
  # Store event detections in S.misc
  sig = SEED.B201.sig
  flag = SEED.B201.flags == 0x80 ? "dilatation" : "compression"
  if SEED.swap
    sig = ntoh.(sig)
    flag = SEED.B201.flags == 0x01 ? "dilatation" : "compression"
  end
  if !haskey(S.misc[c], "mseed_events")
    S.misc[c]["mseed_events"] = Array{String, 1}(undef,0)
  end
  push!(S.misc[c]["mseed_events"],  join(SEED.B201.t, ',') * "," *
                                    join(sig, ',') * "," *
                                    flag * "," *
                                    join(SEED.B201.snr, ',') * "," *
                                    strip(SEED.B201.det) )
  return 0x000c
end

#  [500] Timing Blockette (200 bytes)
function blk_500(S::SeisIO.SeisData, sid::IO, c::Int64)
  SEED.B500.vco_correction    = SEED.swap ? ntoh(read(sid, Float32)) : read(sid, Float32)
  blk_time!(SEED.B500.t, sid, swap)
  SEED.B500.μsec              = read(sid, Int8)
  SEED.B500.reception_quality = read(sid, UInt8)
  SEED.B500.exception_count   = SEED.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)
  SEED.B500.exception_type    = String(read(sid, UInt8, 16))
  SEED.B500.clock_model       = String(read(sid, UInt8, 32))
  SEED.B500.clock_status      = String(read(sid, UInt8, 128))
  return 0x00c8
end
# TO DO: correct S.t[c] when one of these timing blockettes is detected

# [1000] Data Only SEED Blockette (8 bytes)
function blk_1000(S::SeisIO.SeisData, sid::IO, c::Int64)
  SEED.fmt = read(sid, UInt8)
  SEED.wo  = read(sid, UInt8)
  SEED.lx  = read(sid, UInt8)
  skip(sid, 1)

  SEED.nx   = UInt16(2^SEED.lx)
  SEED.xs   = ((SEED.swap == true) && (SEED.wo == 0x01))
  return 0x0008
end

# [1001] Data Extension Blockette  (8 bytes)
function blk_1001(S::SeisIO.SeisData, sid::IO, c::Int64)
  skip(sid, 1)
  SEED.tc += read(sid, Int8)
  skip(sid, 2)
  return 0x0008
end
