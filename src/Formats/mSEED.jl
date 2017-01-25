const steimvals = flipdim(collect(0x00000000:0x00000002:0x0000001e),1)

function unpack!(x::Array{Float64,1}, k::Int, v::UInt32, s::UInt8, c::UInt8, n::UInt8)
  r = 0x20-c
  for i = 0x01:0x01:n
    k+=1
    x[k] = Float64(>>(signed(<<(v,s)), r))
    s+=c
  end
  return k
end

function blk_time(sid::IOStream, b::Bool)
  (yr,jd)       = read(sid, UInt16, 2)
  (HH,MM,SS)    = read(sid, UInt8, 3)
  skip(sid, 1)
  sss           = read(sid, UInt16, 1)
  if b
    yr = bswap(yr)
    jd = bswap(jd)
    sss = bswap(sss)
  end
  f_sss = Float64(sss)*1.0e-4
  return (yr,jd,HH,MM,SS,f_sss)
end

function parserec!(S::SeisData, sid::IO, swap::Bool, v::Int)
  fmt = 0x0a
  L   = 0x00
  nx  = 0x1000
  wo  = 0x01
  p_start = position(sid)

  # =========================================================================
  # Fixed section of data header (48 bytes)
  hdr                         = String(read(sid, UInt8, 20))
  (yr,jd)                     = read(sid, UInt16, 2)
  (HH,MM,SS,unused)           = read(sid, UInt8, 4)
  (msec,nsamp)                = read(sid, UInt16, 2)
  (rateFac,rateMult)          = read(sid, Int16, 2)
  (AFlag,IOFlag,DQFlag,NBlk)  = read(sid, UInt8, 4)
  TimeCorrection              = read(sid, Int32)
  (OffsetBeginData,NBos)      = read(sid, UInt16, 2)
  SeqNo     = hdr[1:6]
  seed_id   = hdr[9:20]
  # =========================================================================
  # Fixed header

  # Post-read header processing
  if (position(sid) - p_start < 64 && (yr > 0x0bc2 || yr < 0x079e))
    swap = Bool(true)
  end
  if swap
    yr               = bswap(yr)
    jd               = bswap(jd)
    msec             = bswap(msec)
    nsamp            = bswap(nsamp)
    rateFac          = bswap(rateFac)
    rateMult         = bswap(rateMult)
    TimeCorrection   = bswap(TimeCorrection)
    OffsetBeginData  = bswap(OffsetBeginData)
    NBos             = bswap(NBos)
  end

  TC = Float64(TimeCorrection) / 1.0e4
  ms = Float64(msec) / 1.0e4
  RF = Float64(rateFac)
  RM = Float64(rateMult)
  nsamp = Int(nsamp)

  # Generate dt
  if RF > 0.0 && RM > 0.0
    dt = 1.0/(RF*RM)
  elseif RF > 0.0
    dt = -1.0*RM/RF
  elseif RM > 0.0
    dt = -1.0*RF/RM
  else
    dt = RF*RM
  end

  # =========================================================================
  # New channel for Seis if needed
  id = replace(join([seed_id[11:12], seed_id[1:5], seed_id[6:7], seed_id[8:10]], '.')," ","")
  channel = findfirst(S.id .== id)
  if channel == 0
    S += SeisChannel(name=seed_id, id=id, fs=1.0/dt)
    note!(S, S.n, "Channel initialized")
    channel = S.n
    te = 0
  else
    # I assume fs doesn't change within a SeisData structure
    te = sum(S.t[channel][:,2]) + round(Int, length(S.x[channel])*dt*sμ)
  end
  # =========================================================================

  # Blockettes
  nsk = OffsetBeginData-0x0030
  for i = 0x01:0x01:NBlk
    BlocketteType = ntoh(read(sid, UInt16))

    if BlocketteType == 0x0064
      # [100] Sample Rate Blockette (12 bytes)
      # V 2.3 – Introduced in  SEED Version 2.3
      # skip(sid, 2)
      # true_dt = ntoh(read(sid, Float32))
      skip(sid, 10)
      nsk -= 0x000c
      # Not sure how to handle this, don't know units

    elseif BlocketteType == 0x00c9
      # [201] Murdock Event Detection Blockette (60 bytes)
      # First encountered 2016-10-26

      skip(sid, 16)
      (eyr,ejd)           = read(sid, UInt16, 2)
      (eHH,eMM,eSS,enull) = read(sid, UInt8, 4)
      ems                 = read(sid, UInt16)
      skip(sid, 32)
      nsk -= 0x003c

      if swap
        eyr               = ntoh(eyr)
        ejd               = ntoh(ejd)
        ems               = ntoh(ems)
      end
      f_ems     = Float64(ems)/1.0e4
      emo, edy  = j2md(Int16(eyr), Int16(ejd))
      t_evt     = round(Int, sμ*(d2u(DateTime(eyr, emo, edy, eHH, eMM, eSS, 0)) + f_ems + TC))
      misc_keys = collect(keys(getfield(S, :misc)[channel]))
      if findfirst(misc_keys.=="Events") == 0
        S.misc[channel]["Events"] = Array{Int64,1}(t_evt)
      else
        push!(S.misc[channel]["Events"], t_evt)
      end

    elseif BlocketteType == 0x01f4
      #  [500] Timing Blockette (200 bytes)
      # Never encountered in wild

      skip(sid, 1)
      vco_correction    = ntoh(read(sid, Float32))
      time_of_exception = blk_time(sid, swap)
      μsec              = read(sid, Int8)
      reception_quality = read(sid, UInt8)
      exception_count   = ntoh(read(sid, UInt16))
      exception_type    = read(sid, UInt8, 16)
      clock_model       = read(sid, UInt8, 32)
      clock_status      = read(sid, UInt8, 128)
      if v > 1
        println(STDOUT, "BlocketteType 500.")
        println(STDOUT, "VCO correction: ", vco_correction)
        println(STDOUT, "Time of exception: ", time_of_exception)
        println(STDOUT, "μsec: ", μsec)
        println(STDOUT, "reception quality: ", reception_quality)
        println(STDOUT, "exception_count: ", exception_count)
        println(STDOUT, "exception_type: ", exception_type)
        println(STDOUT, "clock_model: ", clock_model)
        println(STDOUT, "clock_status: ", clock_status)
      end
      nsk -= 0x00c8

    elseif BlocketteType == 0x03e8
      # [1000] Data Only SEED Blockette (8 bytes)
      # V 2.3 – Introduced in SEED Version 2.3
      (null1, null2, fmt, wo, L, null3) = read(sid, UInt8, 6)
      nsk -= 0x0008
      nx  = UInt16(2^L)

    elseif BlocketteType == 0x03e9
      # [1001] Data Extension Blockette  (8 bytes)
      # V 2.3 – Introduced in SEED Version 2.3
      # Never encountered in wild
      skip(sid, 3)
      mu = read(sid, UInt8)
      skip(sid, 2)
      nsk -= 0x0008
      TC += Float64(mu)/1.0e6

    elseif BlocketteType == 0x07d0
      # [2000] Variable Length Opaque Data Blockette
      # V 2.3 – Introduced in SEED Version 2.3
      # Never encountered in wild
      nextblk_pos         = ntoh(read(sid, UInt16)) + p_start
      blk_length          = ntoh(read(sid, UInt16))
      opaque_data_offset  = ntoh(read(sid, UInt16))
      record_number       = ntoh(read(sid, UInt32))
      (word_order, flags, n_header_fields)  = read(sid, UInt8, 3)
      header_fields       = [String(i) for i in split(String(read(sid, UInt8, signed(opaque_data_offset)-15)), '\~', limit=n_header_fields)]
      opaque_data         = read(sid, UInt8, blk_length - opaque_data_offset)

      # Store to S.misc[i]
      ri = string(record_number)
      S.misc[channel][ri * "_flags"] = bits(flags)
      S.misc[channel][ri * "_header"] = header_fields
      S.misc[channel][ri * "_data"] = opaque_data
      nsk -= blk_length

    else
      # I have yet to find any other BlocketteType in an IRIS stream/archive
      # Similar reports from C. Trabant @ IRIS
      error(string("No support for BlocketteType ", BlocketteType))
    end
  end
  # =========================================================================
  if nsk > 0x0000
    skip(sid, Int(nsk))
  end

  # =========================================================================
  # Data: Adapted from rdmseed.m by Francois Beauducel <beauducel@ipgp.fr>, Institut de Physique du Globe de Paris
  (mo,dy) = j2md(Int16(yr), Int16(jd))

  # Determine start time
  dts = round(Int64, sμ*(d2u(DateTime(yr, mo, dy, HH, MM, SS, 0)) + ms + TC)) - te
  if te == 0
    S.t[channel] = Array{Int64,2}([1 dts; nsamp 0])
  else
    if v > 1
      println(STDOUT, "Old end = ", te, ", New start = ", d2u(DateTime(yr, mo, dy, HH, MM, SS, 0)) + ms + TC, ", diff = ", dts, " μs")
    end
    S.t[channel] = S.t[channel][1:end-1,:]
    if dts > round(Int64, dt*sμ)
      S.t[channel] = vcat(S.t[channel], [length(S.x[channel])+1 dts])
    end
    S.t[channel] = vcat(S.t[channel], [length(S.x[channel])+nsamp 0])
  end

  x = Array{Float64,1}(nsamp)

  # ASCII
  if fmt == 0x00
    x = map(Float64, read(sid, Int8, nx-OffsetBeginData))

  # Int16
  elseif fmt in [0x01, 0x03, 0x04, 0x05]
    if fmt == 0x01
      T = Int16
    elseif fmt == 0x03
      T = Int32
    elseif fmt == 0x04
      T = Float32
    elseif fmt == 0x05
      T = Float64
    end
    d = read(sid, T, div(nx-OffsetBeginData,sizeof(T)))
    if swap
      d = [ntoh(i) for i in d]
    end
    x = map(Float64, d)

  # Steim1 or Steim2
  elseif fmt in [0x0a, 0x0b]
    nf = div(nx-OffsetBeginData,0x0040)
    frame32 = transpose(read(sid, UInt32, 16, nf))

    # Check for byte swap
    if swap && wo == 0x01
      for i = 1:1:size(frame32,1)
        for j = 1:1:size(frame32,2)
          frame32[i,j] = bswap(frame32[i,j])
        end
      end
    end
    x0 = Float64(signed(frame32[1,2]))
    xn = Float64(signed(frame32[1,3]))
    k = 0

    if fmt == 0x0a
      for i = 1:1:nf
        for j = 1:1:16
          ff = (frame32[i,1] >> steimvals[j]) & 0x00000003
          tmp = frame32[i,j]
          if ff == 0x00000001
            k = unpack!(x, k, tmp, 0x00, 0x08, 0x04)
          elseif ff == 0x00000002
            k = unpack!(x, k, tmp, 0x00, 0x10, 0x02)
          elseif ff == 0x00000003
            k+=1
            x[k] = Float64(signed(tmp))
          end
        end
      end

    else
      for i = 1:1:nf
        for j = 1:1:16
          ff = (frame32[i,1] >> steimvals[j]) & 0x00000003
          tmp = frame32[i,j]
          if ff == 0x00000001
            k = unpack!(x, k, tmp, 0x00, 0x08, 0x04)
          else
            d = tmp >> 0x0000001e
            if ff == 0x00000002
              if d == 0x00000001
                k+=1
                x[k] = Float64(>>(signed(<<(tmp,2)), 2))
              elseif d == 0x00000002
                k = unpack!(x, k, tmp, 0x02, 0x0f, 0x02)
              elseif d == 0x00000003
                k = unpack!(x, k, tmp, 0x02, 0x0a, 0x03)
              end
            elseif ff == 0x00000003
              if d == 0x00000000
                k = unpack!(x, k, tmp, 0x02, 0x06, 0x05)
              elseif d == 0x00000001
                k = unpack!(x, k, tmp, 0x02, 0x05, 0x06)
              else
                k = unpack!(x, k, tmp, 0x04, 0x04, 0x07)
              end
            end
          end
        end
      end
    end

    if wo != 1
      x = flipdim(x,1)
    end
    x[1] = x0
    cumsum!(x, x, 1)

    # Check that we read correct # of samples
    if length(x) != nsamp
      warn(string("RDMSEED: data integrity -- extracted ", length(x), " points, expected ", nsamp, "!"))
    end

    # Check data values
    if abs(x[end] - xn) > eps()
      warn(string("RDMSEED: data integrity -- steim", fmt-0x09, " sequence #", SeqNo, " integrity check failed, last_data=", x[end], ", should be xn=", xn))
    end
  else
    error(@sprintf("Decoding for fmt = %i NYI!",fmt))
  end

  # Append data
  append!(S.x[channel], x)
  return S
end

function parsemseed!(S::SeisData, sid::IO, swap::Bool, v::Int)
  while !eof(sid)
    parserec!(S, sid, swap, v)
  end
  return S
end
parsemseed(sid::IO, swap::Bool, v::Int) = (S = SeisData(); parsemseed!(S, sid, swap, v); return S)

"""
S = readmseed(fname)

Read file fname in big-Endian mini-SEED format. Returns a SeisData structure.
Note: Limited functionality; cannot currently handle full SEED files or most
non-data blockettes.
"""
function readmseed(fname::String; swap=false::Bool, v=0::Int)
  S = SeisData()
  if isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    ftype = read(fid, Char)
    if search("DRMQ",ftype) == 0
      error("Scan failed due to invalid file type")
    end
    seek(fid, 0)
    parsemseed!(S, fid, swap, v)
    close(fid)
  else
    error("Invalid file name!")
  end
  return S
end
