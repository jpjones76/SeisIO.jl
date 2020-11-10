# TO DO: [200], [400], [405]
# [200] Generic Event Detection Blockette (52 bytes)
# [400] Beam Blockette (16 bytes)
# [405] Beam Delay Blockette (6 bytes)

# All blockette functions return a UInt16 value equal to blockette length in bytes
function blk_time!(t::Array{Int32,1}, sid::IO, b::Bool)
  yy    = fastread(sid, UInt16)
  jj    = fastread(sid, UInt16)
  t[4]  = Int32(fastread(sid))
  t[5]  = Int32(fastread(sid))
  t[6]  = Int32(fastread(sid))
  fastskip(sid, 1)
  ms    = fastread(sid, UInt16)
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
  BUF.dt = 1.0 / Float64(BUF.swap ? ntoh(fastread(sid, Float32)) : fastread(sid, Float32))
  fastskip(sid, 4)
  return 0x000c
end

# [201] Murdock Event Detection Blockette (60 bytes)
function blk_201(S::SeisData, sid::IO, c::Int64)
  fastread!(sid, BUF.B201.sig)                          # amplitude, period, background estimate
  BUF.B201.flags = fastread(sid)                        # detection flags
  fastskip(sid, 1)                                      # reserved
  blk_time!(BUF.B201.t, sid, BUF.swap)                  # onset time
  fastread!(sid, BUF.B201.snr)                          # snr, lookback, pick algorithm
  BUF.B201.det  = String(fastread(sid, 24))             # detector name

  # will store as a string: t_evt, :sig (3 vals), bittsring(:flags), :snr, :lb, :p)
  # Store event detections in S.misc
  sig = BUF.B201.sig
  flag = BUF.B201.flags == 0x80 ? "dilatation" : "compression"
  if BUF.swap
    sig = ntoh.(sig)
    flag = BUF.B201.flags == 0x01 ? "dilatation" : "compression"
  end
  if !haskey(S.misc[c], "seed_event")
    S.misc[c]["seed_event"] = Array{String, 1}(undef, 0)
  end
  push!(S.misc[c]["seed_event"],  join(BUF.B201.t, ',') * "," *
                                    join(sig, ',') * "," *
                                    flag * "," *
                                    join(BUF.B201.snr, ',') * "," *
                                    strip(BUF.B201.det) )
  return 0x003c
end

# [300] Step Calibration Blockette (60 bytes)
# [310] Sine Calibration Blockette (60 bytes)
# [320] Pseudo-random Calibration Blockette (64 bytes)
# [390] Generic Calibration Blockette (28 bytes)
function blk_calib(S::SeisData, sid::IO, c::Int64, bt::UInt16)
  p = fastpos(sid)
  blk_time!(BUF.Calib.t, sid, BUF.swap)         # Calibration time
  fastskip(sid, 1)                                  # Reserved byte
  (bt == 0x012c) && (BUF.Calib.n = fastread(sid))          # Number of step calibrations
  BUF.Calib.flags      = fastread(sid)       # Calibration flags
  BUF.Calib.dur1       = fastread(sid, UInt32)      # Calibration duration
  (bt == 0x012c) && (BUF.Calib.dur2   = fastread(sid, UInt32))    # Interval duration
  (bt == 0x0136) && (BUF.Calib.period = fastread(sid, Float32))   # Period of signal (seconds)
  BUF.Calib.amplitude  = fastread(sid, Float32)     # Peak-to-peak amplitude
  BUF.Calib.channel    = fastread(sid, 3)
  fastskip(sid, 1)                                  # Reserved byte
  BUF.Calib.ref        = fastread(sid, UInt32)      # Reference amplitude

  # String arrays
  if bt < 0x0186
    BUF.Calib.coupling = fastread(sid, 12)
    BUF.Calib.rolloff  = fastread(sid, 12)
    if bt == 0x0140
      BUF.Calib.noise  = fastread(sid, 8)
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
  dur = bt == 0x012c ? string(BUF.Calib.dur1, ",", BUF.Calib.dur2) : string(BUF.Calib.dur1)
  amp = bt == 0x0136 ? string(per, ",", amp) : string(amp)
  flag = bt == 0x012c ? string(flag, ",", BUF.Calib.n) : flag
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
  return UInt16(fastpos(sid)-p) + 0x0004
end

# [500] Timing Blockette (200 bytes)
function blk_500(S::SeisData, sid::IO, c::Int64)
  BUF.B500.vco_correction    = BUF.swap ? ntoh(fastread(sid, Float32)) : fastread(sid, Float32)
  blk_time!(BUF.B500.t, sid, BUF.swap)
  BUF.B500.μsec              = fastread(sid, Int8)
  BUF.B500.reception_quality = fastread(sid)
  BUF.B500.exception_count   = BUF.swap ? ntoh(fastread(sid, UInt32)) : fastread(sid, UInt32)
  BUF.B500.exception_type    = strip(String(fastread(sid, 16)), ['\0',' '])
  BUF.B500.clock_model       = strip(String(fastread(sid, 32)), ['\0',' '])
  BUF.B500.clock_status      = strip(String(fastread(sid, 128)), ['\0',' '])

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
  BUF.fmt  = fastread(sid)
  BUF.wo   = fastread(sid)
  lx       = fastread(sid)
  fastskip(sid, 1)
  BUF.nx   = 2^lx
  BUF.xs   = ((BUF.swap == true) && (BUF.wo == 0x01))
  return 0x0008
end

# [1001] Data Extension Blockette (8 bytes)
function blk_1001(S::SeisData, sid::IO, c::Int64)
  fastskip(sid, 1)
  BUF.tc += signed(fastread(sid))
  fastskip(sid, 2)
  return 0x0008
end

# [2000] Variable Length Opaque Data Blockette
function blk_2000(S::SeisData, sid::IO, c::Int64)
  # Always big-Endian? Undocumented
  BUF.B2000.NB     = BUF.swap ? ntoh(fastread(sid, UInt16)) : fastread(sid, UInt16)
  BUF.B2000.os     = BUF.swap ? ntoh(fastread(sid, UInt16)) : fastread(sid, UInt16)
  n                 = BUF.swap ? ntoh(fastread(sid, UInt32)) : fastread(sid, UInt32)
  wo                = fastread(sid)
  nf                = fastread(sid)
  flag              = fastread(sid)
  BUF.B2000.hdr    = fastread(sid, Int(BUF.B2000.os)-15)
  BUF.B2000.data   = fastread(sid, BUF.B2000.NB-BUF.B2000.os)

  # Store to S.misc[i]
  r = "seed_opaque_" * string(n)
  S.misc[c][r * "_wo"]    = wo
  S.misc[c][r * "_flag"]  = bitstring(BUF.B2000.flag)
  S.misc[c][r * "_hdr"]   = String.(split(String(BUF.B2000.hdr), '~', keepempty=true, limit=Int(nf)))
  S.misc[c][r * "_data"]  = BUF.B2000.data
  return BUF.B2000.NB
end
