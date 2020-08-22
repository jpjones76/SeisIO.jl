function tdms_header!(TDMS::TDMSbuf, io::IO, v::Integer)
  fastskip(io, 4)
  TDMS.flags  = fastread(io, UInt32)
  fastskip(io, 4)
  TDMS.nsos   = fastread(io, UInt64) + LEAD_IN_LENGTH
  TDMS.rdos   = fastread(io, UInt64) + LEAD_IN_LENGTH
  TDMS.n_ch   = fastread(io, UInt32) - 0x00000002
  l_path      = fastread(io, UInt32)
  fastskip(io, 4 + l_path)
  nprops      = fastread(io, UInt32)

  for i = 1:nprops
    # Get variable name and code
    L         = fastread(io, UInt32)
    name      = String(fastread(io, L))

    # Add dictionaries as needed
    D = TDMS.hdr
    if occursin(".", name)
      k = String.(split(name, "."))
      L = length(k)
      for j in 1:L-1
        if haskey(D, k[j])
          D = D[k[j]]
        else
          D[k[j]] = Dict{String, Any}()
          D = D[k[j]]
        end
      end
      name = k[L]
    end
    pcode     = fastread(io, UInt32)
    (pcode == 0x00000000) && continue

    # Undefined/bad codes
    T         = get(tdms_codes, pcode, nothing)
    (T == nothing) && error("Undefined property type!")

    if pcode == 0x00000044
      # TDMS documentation has the order of these two variables reversed
      nf = fastread(io, UInt64)
      ns = fastread(io, Int64)

      dt = tdms_dtos + ns + nf*2^(-64)
      if name == "GPSTimeStamp"
        TDMS.ts = round(Int64, sμ*dt)
      else
        D[name] = u2d(dt)
        (v > 1) && println(name, " = ", D[name])
      end
      # Will be corrected to UTC by adding SystemInfomation.GPS.UTCOffset

    elseif pcode == 0x00000020
      # No documentation here either
      nn = fastread(io, UInt32)
      val = fastread(io, nn)
      if name == "name"
        TDMS.name = String(val)
      else
        D[name] = String(val)
        (v > 1) && println(name, " = ", D[name])
      end

    else
      if name == "SamplingFrequency[Hz]"
        TDMS.fs = fastread(io, T)
      elseif name == "Latitude"
        TDMS.oy = fastread(io, T)
      elseif name == "Longitude"
        TDMS.ox = fastread(io, T)
      elseif name == "Altitude"
        TDMS.oz = fastread(io, T)
      else
        D[name] = fastread(io, T)
        (v > 1) && println(name, " = ", D[name])
      end

      #=
       In which direction is StartPosition[m]?
                  what about Start Distance (m)?

      =#
    end
  end
  return nothing
end

function read_silixa_tdms(file::String, nn::String, s::TimeSpec, t::TimeSpec, chans::ChanSpec, memmap::Bool, v::Integer)

  io = memmap ? IOBuffer(Mmap.mmap(file)) : open(file, "r")
  tdms_header!(TDMS, io, v)


  # not documented; inferred from manufacturer's Matlab script
  # uses general formula: mask = 2^(n-1); N & mask != mask
  #                       N = UInt8(data_flags & 0b00100000)
  #                       n = 6 (6th bit = 1 if data are decimated)
  decimated = Bool(UInt8(TDMS.flags & DECIMATE_MASK) != 2^5)
  # I don't think this is actually part of the standard TDMS data spec

  # data header info
  fastskip(io, fastread(io, UInt32)+8) # Group information
  fastskip(io, fastread(io, UInt32)+4) # first channel path and length
  DataType = fastread(io, UInt32)
  fastskip(io, 4)
  chunk_size = Int64(fastread(io, UInt32))
  T = get(tdms_codes, DataType, nothing)
  (T == nothing) && error("Unsupported data type!")

  seg1_length   = Int64(div(div(TDMS.nsos - TDMS.rdos, TDMS.n_ch), sizeof(T)))
  if v > 0
    println("data type = ", T,
            ", chunk size = ", chunk_size,
            ", channel length = ", seg1_length,
            ", decimated = ", decimated)
  end

  # parse start time to get zero-indexed si, ei in each channel
  if (typeof(s) <: Real) && (typeof(t) <: Real)
    si = max(round(Int64, TDMS.fs*s), 0)
    ei = min(round(Int64, TDMS.fs*t), seg1_length) - 1
  else
    Δ = round(Int64, SeisIO.sμ / TDMS.fs)
    if s == "0001-01-01T00:00:00"
      s = u2d(TDMS.ts*μs)
    elseif isa(s, Real)
      s = u2d(TDMS.ts*μs + s)
    end
    if t == "9999-12-31T12:59:59"
      t = u2d(TDMS.ts*μs + seg1_length/TDMS.fs)
    elseif isa(t, Real)
      t = u2d(TDMS.ts*μs + t)
    end
    (d0, d1) = parsetimewin(s, t)
    t0 = DateTime(d0).instant.periods.value*1000 - dtconst
    t1 = DateTime(d1).instant.periods.value*1000 - dtconst
    (v > 2) && println("t0 = ", t0, ", t1 = ", t1)
    si = max(div(t0-TDMS.ts, Δ), 0)
    ei = min(div(t1-TDMS.ts, Δ), seg1_length) - 1
  end
  si = Int64(si)
  ei = Int64(ei)

  # this prints one-indexed forms
  (v > 1) && println("reading from si = ", si+1, " to ei = ", ei+1)

  # Chunk bounds
  first_chunk = div(si, chunk_size) + 1
  last_chunk = div(ei, chunk_size) + 1
  n_chunks = last_chunk - first_chunk + 1

  # Skip to start of data
  nskip = TDMS.rdos - position(io)
  if first_chunk > 1
    chunk_os = (first_chunk-1)*chunk_size*sizeof(T)*TDMS.n_ch
    nskip += chunk_os
    (v > 2) && println("To skip: ", chunk_os, " bytes of chunks.")
  end
  if nskip != 0
    (v > 0) && println("Skipping ", nskip, " bytes total.")
    fastskip(io, nskip)
  end

  # Read Data
  buf = Array{T, 2}(undef, TDMS.n_ch, chunk_size)
  data = Array{Float32, 2}(undef, ei-si+1, TDMS.n_ch)

  # ===================================================================
  # Read chunks
  # sj = starting index within chunk
  # ej = ending index within chunk
  j = 1
  jmax = div(seg1_length, chunk_size)*chunk_size - si
  for i in first_chunk:last_chunk
    if j > jmax
      if VERSION < v"1.4"
        buf = Array{T, 2}(undef, TDMS.n_ch, rem(seg1_length, chunk_size))
        read!(io, buf)
      else
        vbuf = view(buf, :, 1:rem(seg1_length, chunk_size))
        read!(io, vbuf)
      end
    else
      read!(io, buf)
    end
    sj = (i == first_chunk ? rem(si+1, chunk_size) : 1)
    ej = (i == last_chunk ? rem(ei, chunk_size) + 1 : chunk_size)
    nj = ej-sj+1
    vx = view(data, j:j+nj-1, :)
    vb = view(buf, :, sj:ej)
    (v > 2) && println("chunk #", i, "/", n_chunks, ", sj = ", sj, ", ej = ", ej, ", j = ", j, ":", j+nj-1)

    transpose!(vx, vb) # converts to Float32 if needed
    j += nj
  end

  # Done with file
  close(io)

  # ----------------------------------------------------------------
  # String values for :name, :id
  name = (try
    string(TDMS.hdr["SystemInfomation"]["OS"]["HostName"], "_",
           TDMS.hdr["SystemInfomation"]["Devices0"]["Model"], "_",
           TDMS.hdr["SystemInfomation"]["Devices1"]["Model"])
  catch
    ""
  end)
  net = nn * "."
  cha = string("..O", getbandcode(TDMS.fs), "0")

  # -----------------------------------------------------------------
  # Time values
  utc_os = get(TDMS.hdr, "SystemInfomation.GPS.UTCOffset", zero(Float64))
  ts = TDMS.ts + round(Int64, sμ*utc_os)

  # =================================================================
  # Parse to NodalData
  if isempty(chans)
    chans = 1:TDMS.n_ch
  end
  S = NodalData(data, TDMS.hdr, chans, ts)
  fill!(S.fs, TDMS.fs)
  fill!(S.src, realpath(file))
  fill!(S.units, "m/m")
  S.ox = TDMS.ox
  S.oy = TDMS.oy
  S.oz = TDMS.oz
  for (i,j) in enumerate(chans)
    S.id[i] = string(net, lpad(j, 5, '0'), cha)
    S.name[i] = string(name, "_", j)
  end
  # =================================================================

  return S
end
