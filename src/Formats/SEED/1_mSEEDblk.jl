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
function blk_100(S::SeisData, sid::IO, c::Int64)
  BUF.dt = Float64(BUF.swap ? ntoh(read(sid, Float32)) : read(sid, Float32))
  skip(sid, 4)
  return 0x000c
end

# [201] Murdock Event Detection Blockette (60 bytes)
function blk_201(S::SeisData, sid::IO, c::Int64)
  read!(sid, BUF.B201.sig)                             # amplitude, period, background estimate
  BUF.B201.flags = read(sid, UInt8)                    # detection flags
  skip(sid, 1)                                          # reserved
  blk_time!(BUF.B201.t, sid, BUF.swap)                # onset time
  read!(sid, BUF.B201.snr)                             # snr, lookback, pick algorithm
  BUF.B201.det  = String(read(sid, 24, all=false))     # detector name

  # will store as a string: t_evt, :sig (3 vals), bittsring(:flags), :snr, :lb, :p)
  # Store event detections in S.misc
  sig = BUF.B201.sig
  flag = BUF.B201.flags == 0x80 ? "dilatation" : "compression"
  if BUF.swap
    sig = ntoh.(sig)
    flag = BUF.B201.flags == 0x01 ? "dilatation" : "compression"
  end
  if !haskey(S.misc[c], "seed_event")
    S.misc[c]["seed_event"] = Array{String, 1}(undef,0)
  end
  push!(S.misc[c]["seed_event"],  join(BUF.B201.t, ',') * "," *
                                    join(sig, ',') * "," *
                                    flag * "," *
                                    join(BUF.B201.snr, ',') * "," *
                                    strip(BUF.B201.det) )
  return 0x000c
end

# [300] Step Calibration Blockette (60 bytes)
# [310] Sine Calibration Blockette (60 bytes)
# [320] Pseudo-random Calibration Blockette (64 bytes)
# [390] Generic Calibration Blockette (28 bytes)
function blk_calib(S::SeisData, sid::IO, c::Int64, bt::UInt16)
  p = position(sid)
  blk_time!(BUF.Calib.t, sid, BUF.swap)       # Calibration time
  skip(sid, 1)                                  # Reserved byte
  if bt == 0x012c
    BUF.Calib.n        = read(sid, UInt8)      # Number of step calibrations
  end
  BUF.Calib.flags      = read(sid, UInt8)      # Calibration flags
  BUF.Calib.dur1       = read(sid, UInt32)     # Calibration duration
  if bt == 0x012c
    BUF.Calib.dur2     = read(sid, UInt32)     # Interval duration
  elseif bt == 0x0136
    BUF.Calib.period   = read(sid, Float32)    # Period of signal (seconds)
  end
  BUF.Calib.amplitude  = read(sid, Float32)    # Peak-to-peak amplitude
  BUF.Calib.channel    = read(sid, 3, all=false)
  skip(sid, 1)                                  # Reserved byte
  BUF.Calib.ref        = read(sid, UInt32)     # Reference amplitude

  # String arrays
  if bt < 0x0186
    BUF.Calib.coupling = read(sid, 12, all=false)
    BUF.Calib.rolloff  = read(sid, 12, all=false)
    if bt == 0x0140
      BUF.Calib.noise  = read(sid, 8, all=false)
    end
  else
    BUF.Calib.coupling = Array{UInt8,1}(undef,0)
    BUF.Calib.rolloff  = Array{UInt8,1}(undef,0)
  end
  bc = Char[' ', '\0']

  # Check that we already have "seed_calib"
  if !haskey(S.misc[c], "seed_calib")
    S.misc[c]["seed_calib"] = Array{String, 1}(undef,0)
  end

  # Swap as needed
  if BUF.swap
    flag = reverse(bitstring(BUF.Calib.flags))
    amp = ntoh(BUF.Calib.amplitude)
    ref = ntoh(BUF.Calib.ref)
    per = ntoh(BUF.Calib.period)
    BUF.Calib.dur1 = ntoh(BUF.Calib.dur1)
    BUF.Calib.dur2 = ntoh(BUF.Calib.dur2)
  else
    flag = bitstring(BUF.Calib.flags)
    amp = BUF.Calib.amplitude
    ref = BUF.Calib.ref
    per = BUF.Calib.period
  end
  typ = (bt == 0x012c ? "Step" : (bt == 310 ? "Sine" : (bt == 320 ? "Pseudo-random" : "Generic")))
  dur = bt == 0x012c ? string(BUF.Calib.dur1 * "," * BUF.Calib.dur2) : string(BUF.Calib.dur1)
  amp = bt == 0x0136 ? join([string(per), string(amp)], ",") : string(amp)
  flag = bt == 0x012c ? flag * "," * string(BUF.Calib.n) : flag
  calib_str = join( [ typ,
                      join(BUF.Calib.t, ","),
                      flag,
                      dur,
                      amp,
                      strip(String(BUF.Calib.channel), bc),
                      string(ref) ], "," )
  if bt < 0x0186
    calib_str *= string(",", strip(String(BUF.Calib.coupling), bc), ",",
                        strip(String(BUF.Calib.rolloff), bc))
    if bt == 0x0140
      calib_str *= string(",", strip(String(BUF.Calib.noise), bc))
    end
  end
  push!(S.misc[c]["seed_calib"], calib_str)
  return UInt16(position(sid)-p) + 0x0004
end

# [500] Timing Blockette (200 bytes)
function blk_500(S::SeisData, sid::IO, c::Int64)
  BUF.B500.vco_correction    = BUF.swap ? ntoh(read(sid, Float32)) : read(sid, Float32)
  blk_time!(BUF.B500.t, sid, BUF.swap)
  BUF.B500.μsec              = read(sid, Int8)
  BUF.B500.reception_quality = read(sid, UInt8)
  BUF.B500.exception_count   = BUF.swap ? ntoh(read(sid, UInt32)) : read(sid, UInt32)
  BUF.B500.exception_type    = strip(String(read(sid, 16, all=false)), ['\0',' '])
  BUF.B500.clock_model       = strip(String(read(sid, 32, all=false)), ['\0',' '])
  BUF.B500.clock_status      = strip(String(read(sid, 128, all=false)), ['\0',' '])

  # TO DO: something with this
  if !haskey(S.misc[c], "seed_timing")
    S.misc[c]["seed_timing"] = Array{String, 1}(undef,0)
  end
  push!(S.misc[c]["seed_timing"], join([string(BUF.B500.vco_correction),
                                        join(BUF.B500.t, ','),
                                        BUF.B500.μsec,
                                        BUF.B500.reception_quality,
                                        BUF.B500.exception_count,
                                        BUF.B500.exception_type,
                                        BUF.B500.clock_model,
                                        BUF.B500.clock_status], ',')
        )
  return 0x00c8
end
# TO DO: correct S.t[c] when one of these timing blockettes is detected

# [1000] Data Only SEED Blockette (8 bytes)
function blk_1000(S::SeisData, sid::IO, c::Int64)
  BUF.fmt  = read(sid, UInt8)
  BUF.wo   = read(sid, UInt8)
  lx        = read(sid, UInt8)
  skip(sid, 1)
  BUF.nx   = 2^lx
  BUF.xs   = ((BUF.swap == true) && (BUF.wo == 0x01))
  return 0x0008
end

# [1001] Data Extension Blockette (8 bytes)
function blk_1001(S::SeisData, sid::IO, c::Int64)
  skip(sid, 1)
  BUF.tc += read(sid, Int8)
  skip(sid, 2)
  return 0x0008
end

# [2000] Variable Length Opaque Data Blockette
function blk_2000(S::SeisData, sid::IO, c::Int64)
  # Always big-Endian? Undocumented
  BUF.B2000.NB     = BUF.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)
  BUF.B2000.os     = BUF.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)
  n                 = BUF.swap ? ntoh(read(sid, UInt32)) : read(sid, UInt32)
  wo                = read(sid, UInt8)
  nf                = read(sid, UInt8)
  flag              = read(sid, UInt8)
  BUF.B2000.hdr    = read(sid, Int(BUF.B2000.os)-15, all=false)
  BUF.B2000.data   = read(sid, BUF.B2000.NB-BUF.B2000.os, all=false)

  # Store to S.misc[i]
  r = "seed_opaque_" * string(n)
  S.misc[c][r * "_wo"]    = wo
  S.misc[c][r * "_flag"]  = bitstring(BUF.B2000.flag)
  S.misc[c][r * "_hdr"]   = String.(split(String(BUF.B2000.hdr), '~', keepempty=true, limit=Int(nf)))
  S.misc[c][r * "_data"]  = BUF.B2000.data
  return BUF.B2000.NB
end
