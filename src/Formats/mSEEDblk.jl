# All blockette functions return a UInt16 value equal to blockette length in bytes

# [100] Sample Rate Blockette (12 bytes)
function blk_100(S::SeisIO.SeisData, sid::IO)
  SEED.dt = Float64(ntoh(read(sid, Float32)))
  skip(sid, 4)
  return 0x000c
end

# [201] Murdock Event Detection Blockette (60 bytes)
function blk_201(S::SeisIO.SeisData, sid::IO)
  for j = 1:3
    SEED.B201.sig[j]    = read(sid, Float32)
  end
  for j = 1:2
    SEED.B201.flags[j]  = read(sid, UInt8, 2)
  end
  blk_time!(SEED.B201.t, sid, SEED.bswap)
  SEED.B201.det         = String(read(sid, UInt8, 24))
  skip(sid, 32)
  t_evt = round(Int64, sμ*(d2u(DateTime(SEED.B201.t[1:6]..., 0)))) + SEED.B201.t[7] + SEED.tc
  if haskey(S.misc[c], ["Events"])
    push!(S.misc[c]["Events"], t_evt)
  else
    S.misc[c]["Events"] = Array{Int64, 1}([t_evt])
  end
  return 0x000c
end

#  [500] Timing Blockette (200 bytes)
function blk_500(S::SeisIO.SeisData, sid::IO)
  SEED.B500.vco_correction    = ntoh(read(sid, Float32))
  blk_time!(SEED.B500.t, sid, swap)
  SEED.B500.μsec              = read(sid, Int8)
  SEED.B500.reception_quality = read(sid, UInt8)
  SEED.B500.exception_count   = ntoh(read(sid, UInt16))
  SEED.B500.exception_type    = String(read(sid, UInt8, 16))
  SEED.B500.clock_model       = String(read(sid, UInt8, 32))
  SEED.B500.clock_status      = String(read(sid, UInt8, 128))
  return 0x00c8
end
# TO DO: correct S.t[c] when one of these timing blockettes is detected

# [1000] Data Only SEED Blockette (8 bytes)
function blk_1000(S::SeisIO.SeisData, sid::IO)
  SEED.fmt = read(sid, UInt8)
  SEED.wo  = read(sid, UInt8)
  SEED.lx  = read(sid, UInt8)
  skip(sid, 1)

  SEED.nx   = UInt16(2^SEED.lx)
  SEED.xs   = ((SEED.swap == true) && (SEED.wo == 0x01))
  return 0x0008
end

# [1001] Data Extension Blockette  (8 bytes)
function blk_1001(S::SeisIO.SeisData, sid::IO)
  skip(sid, 1)
  SEED.tc += read(sid, Int8)
  skip(sid, 2)
  return 0x0008
end

# [2000] Variable Length Opaque Data Blockette
function blk_2000(S::SeisIO.SeisData, sid::IO)
  # Always big-Endian? Undocumented
  SEED.B2000.blk_length     = ntoh(read(sid, UInt16))
  SEED.B2000.odos           = ntoh(read(sid, UInt16))
  SEED.B2000.record_number  = ntoh(read(sid, UInt32))
  for j = 1:3
    SEED.B2000.flags[j]       = read(sid, UInt8)
  end
  SEED.B2000.header_fields  = String[String(j) for j in split(String(read(sid, UInt8, Int(SEED.B2000.odos)-15)), '~', keepempty=true, limit=SEED.B2000.flags[3])]
  SEED.B2000.opaque_data    = read(sid, UInt8, SEED.B2000.blk_length - SEED.B2000.odos)

  # Store to S.misc[i]
  ri = string(SEED.B2000.record_number)
  S.misc[c][ri * "_flags"] = bits(flags)
  S.misc[c][ri * "_header"] = header_fields
  S.misc[c][ri * "_data"] = opaque_data
  return SEED.B2000.blk_length
end
