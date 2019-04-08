# TO DO: [200], [400], [405]
# [200] Generic Event Detection Blockette (52 bytes)
# [400] Beam Blockette (16 bytes)
# [405] Beam Delay Blockette (6 bytes)

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
  if !haskey(S.misc[c], "seed_event")
    S.misc[c]["seed_event"] = Array{String, 1}(undef,0)
  end
  push!(S.misc[c]["seed_event"],  join(SEED.B201.t, ',') * "," *
                                    join(sig, ',') * "," *
                                    flag * "," *
                                    join(SEED.B201.snr, ',') * "," *
                                    strip(SEED.B201.det) )
  return 0x000c
end

# [300] Step Calibration Blockette (60 bytes)
# [310] Sine Calibration Blockette (60 bytes)
# [320] Pseudo-random Calibration Blockette (64 bytes)
# [390] Generic Calibration Blockette (28 bytes)
function blk_calib(S::SeisIO.SeisData, sid::IO, c::Int64, bt::UInt16)
  p = position(sid)
  blk_time!(SEED.Calib.t, sid, SEED.swap)       # Calibration time
  skip(sid, 1)                                  # Reserved byte
  if bt == 0x012c
    SEED.Calib.n        = read(sid, UInt8)      # Number of step calibrations
  end
  SEED.Calib.flags      = read(sid, UInt8)      # Calibration flags
  SEED.Calib.dur1       = read(sid, UInt32)     # Calibration duration
  if bt == 0x012c
    SEED.Calib.dur2     = read(sid, UInt32)     # Interval duration
  elseif bt == 0x0136
    SEED.Calib.period   = read(sid, Float32)    # Period of signal (seconds)
  end
  SEED.Calib.amplitude  = read(sid, Float32)    # Peak-to-peak amplitude
  SEED.Calib.channel    = read(sid, 3, all=false)
  skip(sid, 1)                                  # Reserved byte
  SEED.Calib.ref        = read(sid, UInt32)     # Reference amplitude

  # String arrays
  if bt < 0x0186
    SEED.Calib.coupling = read(sid, 12, all=false)
    SEED.Calib.rolloff  = read(sid, 12, all=false)
    if bt == 0x0140
      SEED.Calib.noise  = read(sid, 8, all=false)
    end
  else
    SEED.Calib.coupling = Array{UInt8,1}(undef,0)
    SEED.Calib.rolloff  = Array{UInt8,1}(undef,0)
  end
  bc = Char[' ', '\0']

  # Check that we already have "seed_calib"
  if !haskey(S.misc[c], "seed_calib")
    S.misc[c]["seed_calib"] = Array{String, 1}(undef,0)
  end

  # Swap as needed
  if SEED.swap
    flag = reverse(bitstring(SEED.Calib.flags))
    amp = ntoh(SEED.Calib.amplitude)
    ref = ntoh(SEED.Calib.ref)
    per = ntoh(SEED.Calib.period)
    SEED.Calib.dur1 = ntoh(SEED.Calib.dur1)
    SEED.Calib.dur2 = ntoh(SEED.Calib.dur2)
  else
    flag = bitstring(SEED.Calib.flags)
    amp = SEED.Calib.amplitude
    ref = SEED.Calib.ref
    per = SEED.Calib.period
  end
  typ = (bt == 0x012c ? "Step" : (bt == 310 ? "Sine" : (bt == 320 ? "Pseudo-random" : "Generic")))
  dur = bt == 0x012c ? string(SEED.Calib.dur1 * "," * SEED.Calib.dur2) : string(SEED.Calib.dur1)
  amp = bt == 0x0136 ? join([string(per), string(amp)], ",") : string(amp)
  flag = bt == 0x012c ? flag * "," * string(SEED.Calib.n) : flag
  calib_str = join( [ typ,
                      join(SEED.Calib.t, ","),
                      flag,
                      dur,
                      amp,
                      strip(String(SEED.Calib.channel), bc),
                      string(ref) ], "," )
  if bt < 0x0186
    calib_str *= string(",", strip(String(SEED.Calib.coupling), bc), ",",
                        strip(String(SEED.Calib.rolloff), bc))
    if bt == 0x0140
      calib_str *= string(",", strip(String(SEED.Calib.noise), bc))
    end
  end
  push!(S.misc[c]["seed_calib"], calib_str)
  return UInt16(position(sid)-p) + 0x0004
end

# [395] Calibration Abort Blockette (16 bytes)
function blk_395(S::SeisIO.SeisData, sid::IO, c::Int64)
  blk_time!(SEED.Calib.t, sid, SEED.swap)
  skip(sid, 2)
  if !haskey(S.misc[c], "seed_calib")
    S.misc[c]["seed_calib"] = Array{String, 1}(undef,0)
  end
  push!(S.misc[c]["seed_calib"], "Abort," * join(SEED.Calib.t, ","))
  return 0x0010
end

#  [500] Timing Blockette (200 bytes)
function blk_500(S::SeisIO.SeisData, sid::IO, c::Int64)
  SEED.B500.vco_correction    = SEED.swap ? ntoh(read(sid, Float32)) : read(sid, Float32)
  blk_time!(SEED.B500.t, sid, SEED.swap)
  SEED.B500.μsec              = read(sid, Int8)
  SEED.B500.reception_quality = read(sid, UInt8)
  SEED.B500.exception_count   = SEED.swap ? ntoh(read(sid, UInt32)) : read(sid, UInt32)
  SEED.B500.exception_type    = strip(String(read(sid, 16, all=false)), ['\0',' '])
  SEED.B500.clock_model       = strip(String(read(sid, 32, all=false)), ['\0',' '])
  SEED.B500.clock_status      = strip(String(read(sid, 128, all=false)), ['\0',' '])

  # TO DO: something with this
  if !haskey(S.misc[c], "seed_timing")
    S.misc[c]["seed_timing"] = Array{String, 1}(undef,0)
  end
  push!(S.misc[c]["seed_timing"], join([string(SEED.B500.vco_correction),
                                        join(SEED.B500.t, ','),
                                        SEED.B500.μsec,
                                        SEED.B500.reception_quality,
                                        SEED.B500.exception_count,
                                        SEED.B500.exception_type,
                                        SEED.B500.clock_model,
                                        SEED.B500.clock_status], ',')
        )
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

# [2000] Variable Length Opaque Data Blockette
function blk_2000(S::SeisIO.SeisData, sid::IO, c::Int64)
  # Always big-Endian? Undocumented
  SEED.B2000.NB     = SEED.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)
  SEED.B2000.os     = SEED.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)
  n                 = SEED.swap ? ntoh(read(sid, UInt32)) : read(sid, UInt32)
  wo                = read(sid, UInt8)
  nf                = read(sid, UInt8)
  flag              = read(sid, UInt8)
  SEED.B2000.hdr    = read(sid, Int(SEED.B2000.os)-15, all=false)
  SEED.B2000.data   = read(sid, SEED.B2000.NB-SEED.B2000.os, all=false)

  # Store to S.misc[i]
  r = "seed_opaque_" * string(n)
  S.misc[c][r * "_wo"]    = wo
  S.misc[c][r * "_flag"]  = bitstring(SEED.B2000.flag)
  S.misc[c][r * "_hdr"]   = String.(split(String(SEED.B2000.hdr), '~', keepempty=true, limit=Int(nf)))
  S.misc[c][r * "_data"]  = SEED.B2000.data
  return SEED.B2000.NB
end
