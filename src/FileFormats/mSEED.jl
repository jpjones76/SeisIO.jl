function parsesl(S::SeisData, buf::IOBuffer; v=false::Bool, vv=false::Bool)
  seekstart(buf)
  if v || vv
    @printf(STDOUT, "Parsing: ")
  end
  while !eof(buf)
    if v || vv
      id = ascii(read(buf,UInt8,8))
      @printf(STDOUT, "%s, ", id)
    else
      skip(buf, 8)
    end
    parserec(S, buf, v=v, vv=vv)
  end
  return(S)
end

"""
S = readmseed(fname)

Read file fname in big-Endian mini-SEED format. Returns a SeisData structure.
Note: Limited functionality; cannot currently handle full SEED files or most
non-data blockettes.
"""
function readmseed(fname::ASCIIString; swap=false::Bool, v=false::Bool, vv=false::Bool)
  nproc  = 0
  ef     = 10
  chno   = 1
  S      = SeisData()

  if isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    ftype = read(fid, Char)
    if search("DRMQ",ftype) == 0
      error( "Scan failed due to invalid file type")
    end
    return parsemseed(S, fid, v=v, vv=vv, fclose=true)
  else
    error(@printf("Invalid file name: %s\n",fname))
  end
  return S
end

"""
parsemseed(Seis, sid)

Parse stream `sid` of mini-SEED data. Assumes `sid` is a mini-SEED stream
in big-Endian format. Modifies Seis, a SeisData object.

"""
function parsemseed(S::SeisData, sid; v=false::Bool, vv=false::Bool, fclose=true::Bool, fmt=10::Int)
  while !eof(sid)
    parserec(S, sid, v=v, vv=vv, fmt=fmt)
  end
  fclose && close(sid)
  return S
end
parsemseed(sid; v=false::Bool, vv=false::Bool, fclose=true::Bool, fmt=10::Int) = (
S = SeisData(); parsemseed(S, sid, v=v, vv=vv, fclose=fclose, fmt=fmt); return S)

function parserec(S::SeisData, sid; v=false::Bool, vv=false::Bool, fmt=10::Int)
  swap= false
  L   = 0
  nx  = 2^12
  wo  = 1
  p_start = position(sid)

  # =========================================================================
  # Fixed section of data header (48 bytes)
  hdr   = join(map(Char,read(sid, Cchar, 20)))
  #hdr                         = ascii(read(sid, UInt8, 20))
  vv && (println(hdr); println("position=", position(sid)-p_start))
  SeqNo = hdr[1:6]
  chid  = hdr[9:20]
  (yr,jd)                     = read(sid, UInt16, 2)
  (HH,MM,SS)                  = read(sid, UInt8, 3)
  skip(sid, 1)
  (ms,nsamp,rateFac,rateMult) = read(sid, UInt16, 4)
  (AFlag,IOFlag,DQFlag,NBlk)  = read(sid, UInt8, 4)
  TimeCorrection              = read(sid, Int32)
  (OffsetBeginData,NBos)      = read(sid, UInt16, 2)
  # =========================================================================
  # Fixed header

  # Post-read header processing
  if ((position(sid)-p_start) < 64 && (yr > 3010 || yr < 1950))
    swap = true
  end
  if swap
    yr               = ntoh(yr)
    jd               = ntoh(jd)
    ms               = ntoh(ms)
    nsamp            = ntoh(nsamp)
    rateFac          = ntoh(rateFac)
    rateMult         = ntoh(rateMult)
    TimeCorrection   = ntoh(TimeCorrection)
    OffsetBeginData  = ntoh(OffsetBeginData)
    NBos             = ntoh(NBos)
  end
  # Units of 0.0001 s...? Seriously?
  TimeCorrection /= 1.0e4
  ms /= 1.0e4
  vv && println(yr, ",", jd, ",", HH, ",", MM, ",", SS, ",", ms)
  vv && (println("position=", position(sid)-p_start))
  # Generate dt
  if rateFac > 0
    dt = 1/Float64(rateFac*rateMult)
    if rateMult < 0
      dt = -1*dt
    end
  else
    dt = Float64(rateFac*rateMult)
    if rateMult >= 0
      dt = -1*dt
    end
  end

  # =========================================================================
  # Update Seis if necessary
  channel = find(S.name .== chid)
  if isempty(channel)
    seisdata_id = join([strip(chid[11:12]), strip(chid[1:5]),
    strip(chid[6:7]), strip(chid[8:10])], '.')
    push!(S, SeisObj(name = chid, id = seisdata_id, fs = 1/dt, src="mseed"))
    channel = S.n
    te = 0
  else
    # Lazy coding; I assume fs doesn't change
    channel = channel[1]
    dt = 1/S.fs[channel]
    te = sum(S.t[channel][:,2]) + length(S.x[channel])*dt
  end

  # =========================================================================
  # Blockettes
  for i = 1:1:NBlk
    BlocketteType = ntoh(read(sid, UInt16))
    if BlocketteType == 100
      skip(sid, 1)
      true_dt = ntoh(read(sid, Float32))
      skip(sid, 4)
      vv && @printf(STDOUT, "BlocketteType 100.\nfs = %.3e.\n", true_dt)
      # Not sure how to handle this, don't know units
    elseif BlocketteType == 500
      # Timing (200 bytes), not much useful, just detail
      skip(sid, 1)
      vco_correction = ntoh(read(sid, Float32))
      time_of_exception = blk_time(sid, b=swap)           # This is a tuple
      μsec = read(sid, Int8)
      reception_quality = read(sid, UInt8)
      exception_count = ntoh(read(sid, UInt16))
      exception_type = ascii(read(io, UInt8, 16))
      clock_model = ascii(read(io, UInt8, 32))
      clock_status = ascii(read(io, UInt8, 128))
      if vv
        println("BlocketteType 500.")
        println("VCO correction: ", vco_correction)
        println("Time of exception: ", time_of_exception)
        println("μsec: ", μsec)
        println("reception quality: ", reception_quality)
        println("exception_count: ", exception_count)
        println("exception_type: ", exception_type)
        println("clock_model: ", clock_model)
        println("clock_status: ", clock_status)
      end
    elseif BlocketteType == 1000
      (null, null, fmt, wo, L, null) = read(sid, UInt8, 6)
      wob = parse(Int, string(wo))
      wo  = wob
      nx  = 2^L
      vv && println("BlocketteType 1000 parsed.")
    elseif BlocketteType == 1001
      skip(sid, 3)
      mu = read(sid, UInt8)
      skip(sid, 2)
      TimeCorrection += mu/1.0e6
      vv && println("BlocketteType 1001 parsed.")
    elseif BlocketteType == 2000
      nextblk_pos = ntoh(read(sid, UInt16)) + p_start
      blk_length = ntoh(read(sid, UInt16))
      opaque_data_offset = ntoh(read(sid, UInt16))
      record_number = ntoh(read(sid, UInt32))
      (word_order, flags, n_header_fields)  = read(sid, UInt8, 3)
      header_fields = collect(split(ascii(read(io, UInt8, opaque_data_offset-15)), '\~')[1:n_header_fields])
      opaque_data = read(io, UInt8, blk_length - opaque_data_offset)
      # Store in S.misc[i]
      ri = string(record_number)
      S.misc[channel][ri * "_flags"] = bits(flags)
      S.misc[channel][ri * "_header"] = collect[header_fields]
      S.misc[channel][ri * "_data"] = opaque_data
    else
      # I have yet to find another BlocketteType in an IRIS stream/archive
      error(@sprintf("No support for BlocketteType %i", BlocketteType))
    end
  end
  # =========================================================================



  # =========================================================================

  # =========================================================================
  # Data: Adapted from rdmseed.m by Francois Beauducel <beauducel@ipgp.fr>,
  #                                 Institut de Physique du Globe de Paris
  mo,dy = j2md(yr, jd)
  vv && @printf(STDOUT,
  "%s %04i %02i/%02i %02i:%02i:%02i.%03i, dt = %0.02f, Nsamp = %i, NBos = %i\n",
  hdr, yr, mo, dy, HH, MM, SS, ms*1.0e4, dt, nsamp, NBos)

  # Determine start time relative to end of data channel
  ts = Dates.datetime2unix(DateTime(yr, mo, dy, HH, MM, SS, 0)) + ms + TimeCorrection - te
  #te = ts + nsamp*dt
  vv && println("ts = ", ts, " te = ", te)
  if te  == 0
    S.t[channel] = [1.0 ts; Float64(nsamp) 0.0]
  else
    S.t[channel] = S.t[channel][1:end-1,:]
    if ts-te > dt
      S.t[channel] = [S.t[channel]; [length(S.x[channel])+1.0 ts-te]]
    end
    S.t[channel] = [S.t[channel]; [Float64(length(S.x[channel])+nsamp) 0.0]]
  end

  # Data Read
  if fmt == 0
    # ASCII
    d = read(sid, Cchar, nx - OffsetBeginData)
  elseif fmt == 1
    # INT16
    dd = read(sid, Int16, Int(ceil((nx - OffsetBeginData)/2)))
    d = ParseUnenc(dd, nsamp, swap)
  elseif fmt == 2
    # Int24
    error("Int24 NYI")
  elseif fmt == 3
    # Int32
    dd = read(sid, Int32, Int(ceil((nx - OffsetBeginData)/4)))
    d = ParseUnenc(dd, nsamp, swap)
  elseif fmt == 4
    # Float
    dd = read(sid, Float32, Int(ceil((nx - OffsetBeginData)/4)))
    d = ParseUnenc(dd, nsamp, swap)
  elseif fmt == 5
    # Double
    dd = read(sid, Float64, Int(ceil((nx - OffsetBeginData)/8)))
    d = ParseUnenc(dd, nsamp, swap)
  elseif fmt == 10 || fmt == 11
    # Steim1 or Steim2 is the default; I haven't coded Steim3 because I've
    # never seen it and have no reason to believe it's in use.
    steim = find(fmt.==[10,11])[1]
    frame32 = read(sid, UInt32, 16, Int((nx - OffsetBeginData)/64))

    # Check for byte swap
    if swap && wo == 1
      for i = 1:1:size(frame32,1)
        for j = 1:1:size(frame32,2)
          frame32[i,j] = bswap(frame32[i,j])
        end
      end
    end

    # Get and parse nibbles
    vals = flipdim(collect(UInt32(0):UInt32(2):UInt32(30)),1)
    nibbles = (repmat(frame32[1,:], 16, 1) .>> repmat(vals,1,size(frame32,2))) & 3
    x0 = bitsplit(frame32[2,1],32,32)[1]
    xn = bitsplit(frame32[3,1],32,32)[1]

    if steim == 1
      ddd = NaN*ones(4,length(frame32))
      for i = 1:1:3
        k = find(nibbles .== i)
        if !isempty(k)
          ddd[1:2^(3-i),k] = bitsplit(frame32[k],32,2^(i+2))
        end
      end
    elseif steim == 2
      ddd = ones(7,length(frame32)).*NaN

      k = find(nibbles .== 1)
      if !isempty(k)
        ddd[1:4,k] = bitsplit(frame32[k],32,8)
      end

      k = find(nibbles .== 2)
      if !isempty(k)
        dnib = frame32[k] .>> 30
        for i = 1:1:3
          kk = k[find(dnib .== i)]
          if !isempty(kk)
            ddd[1:i,kk] = bitsplit(frame32[kk],30,Int(30/i))
          end
        end
      end

      k = find(nibbles .== 3)
      if !isempty(k)
        dnib = frame32[k] .>> 30
        kk = k[find(dnib .== 0)]
        if !isempty(kk)
          ddd[1:5,kk] = bitsplit(frame32[kk],30,6)
        end
        kk = k[find(dnib .== 1)]
        if !isempty(kk)
          ddd[1:6,kk] = bitsplit(frame32[kk],30,5)
        end
        kk = k[find(dnib .== 2)]
        if !isempty(kk)
          ddd[1:7,kk] = bitsplit(frame32[kk],28,4)
        end
      end
    end

    if wo != 1
      ddd = flipdim(ddd,1)
    end
    dd = ddd[find(isnan(ddd).==false)]

    # Check that we read correct # of samples
    if length(dd) != nsamp
      warn(@sprintf("RDMSEED:DataIntegrity -- extracted %i points, expected %i!",
      length(dd), nsamp))
      nsamp = minimum([nsamp, length(dd)])
    end
    d = cumsum(cat(1,x0,dd[2:nsamp]),1)

    # Check data values
    if abs(d[end] - xn) > eps()
      warn(string("RDMSEED:DataIntegrity --",
      @sprintf("Problem in steim%i sequence #%s:", steim, SeqNo),
      @sprintf(" data integrity check failed, last_data=%d, Xn=%d.\n",
      d[end], xn)))
    end
    if nsamp == 0
      d = Float64[]
    end
  else
    # I'll add more someday
    error(@sprintf("Decoding for fmt = %i NYI!",fmt))
  end
  # Append data
  append!(S.x[channel], d)
  return S
end

"""
    d = bitsplit(x,B,N)

Splits B-bit unsigned int X into signed N-bit array
"""
function bitsplit(x,b,n)
  m = Int(b/n)
  y = zeros(m,length(x))
  for j = 1:1:length(x)
    s = bits(x[j])[end-b+1:end]
    for i = 1:1:m
      if s.data[1+(i-1)*n] == 0x30
        os = 0
      else
        os = 2^(n-1)
      end
      y[i,j] = parse(Int, string(s[2+(i-1)*n:i*n]), 2) - os
    end
  end
  return y
end

"""
    d = ParseUnenc(D, N, swap)

Parse N samples of unencoded data D; byteswap if swap = true
"""
function ParseUnenc(D, N, swap)
  if swap
    d = zeros(N)
    for i = 1:1:N
      d[i] = bswap(D[i])
    end
  else
    d = D[1:nsamp]
  end
  return d
end

function blk_time(sid; b=true::Bool)
  (yr,jd)       = read(sid, UInt16, 2)
  (HH,MM,SS)    = read(sid, UInt8, 3)
  skip(sid, 1)
  sss           = read(sid, UInt16, 1)
  if b
    yr = ntoh(yr)
    jd = ntoh(jd)
    sss = ntoh(sss)
  end
  sss = sss*1.0e-4
  return (yr,jd,HH,MM,SS,sss)
end
