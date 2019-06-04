function uwdf(datafile::String;
              v::Int=KW.v,
              full::Bool=KW.full
              )
  fname = realpath(datafile)
  D = Dict{String,Any}()

  # Open data file
  fid = open(fname, "r")

  # Process master header
  N             = Int64(bswap(read(fid, Int16)))
  mast_fs       = bswap(read(fid, Int32))
  mast_lmin     = bswap(read(fid, Int32))
  mast_lsec     = bswap(read(fid, Int32))
  mast_nx       = bswap(read(fid, Int32))
  skip(fid, 24)
  extra         = read(fid, 10)
  skip(fid, 80)

  if v > 2
    println("mast_header:")
    println("N = ", N)
    println("mast_fs = ", mast_fs)
    println("mast_lmin = ", mast_lmin)
    println("mast_lsec = ", mast_lsec)
    println("mast_nx = ", mast_nx)
    println("extra = ", Char.(extra))
  end


  # Seek EOF to get number of structures
  seekend(fid)
  skip(fid, -4)
  nstructs = bswap(read(fid, Int32))
  v>0 && println(stdout, "nstructs = ", nstructs)
  structs_os = (-12*nstructs)-4
  tc_os = 0
  v>1 && println(stdout, "structs_os = ", structs_os)

  # Set version of UW seismic data file (char may be empty, leave code as-is!)
  uw2::Bool = extra[3] == 0x32 ? true : false
  chno = Array{Int32, 1}(undef, N)
  corr = Array{Int32, 1}(undef, N)

  # Read in UW2 data structures from record end
  if uw2
    seekend(fid)
    skip(fid, structs_os)
    for j = 1:nstructs
      structtag     = read(fid, UInt8)
      skip(fid, 3)
      M             = bswap(read(fid, Int32))
      byteoffset    = bswap(read(fid, Int32))
      if structtag == 0x43 # 'C'
        N = Int64(M)
      elseif structtag == 0x54 # 'T'
        fpos        = position(fid)
        seek(fid, byteoffset)
        chno = Array{Int32, 1}(undef, M)
        corr = Array{Int32, 1}(undef, M)
        n = 0
        @inbounds while n < M
          n += 1
          chno[n]   = read(fid, Int32)
          corr[n]   = read(fid, Int32)
        end
        chno .= (bswap.(chno) .+ 1)
        corr .= bswap.(corr)
        tc_os = -8*M
        seek(fid, fpos)
      end
    end
  end
  v>0 && println(stdout, "Processing ", N , " channels.")

  # Write time corrections
  timecorr = zeros(Int64, N)
  if length(chno) > 0
    for n = 1:N
      # corr is in μs
      timecorr[chno[n]] = Int64(corr[n])
    end
  end

  # Read UW2 channel headers ========================================
  S = SeisData()

  if uw2
    seekend(fid)
    skip(fid, -56*N + structs_os + tc_os)
    I32 = Array{Int32, 2}(undef, 5, N)    # chlen, offset, lmin, lsec (μs), fs,   unused: expan1
    I16 = Array{Int16, 2}(undef, 3, N)    # lta, trig, bias                       unused: fill
    U8  = Array{UInt8, 2}(undef, 24, N)   # name(8), tmp(4), compflg(4), chid(4), expan2(4)
    i = 0
    @inbounds while i < N
      i = i + 1
      I32[1,i] = bswap(read(fid, Int32))
      I32[2,i] = bswap(read(fid, Int32))
      I32[3,i] = bswap(read(fid, Int32))
      I32[4,i] = bswap(read(fid, Int32))
      I32[5,i] = bswap(read(fid, Int32))
      if full == true
        skip(fid, 4)
        I16[1,i] = bswap(read(fid, Int16))
        I16[2,i] = bswap(read(fid, Int16))
        I16[3,i] = bswap(read(fid, Int16))
        skip(fid, 2)
      else
        skip(fid, 12)
      end
      j = 0
      while j < 24
        j = j + 1
        U8[j,i] = read(fid, UInt8)
      end
    end

    # Parse U8 --------------------------------------------
    # rows 01:08    channel name
    # rows 09:12    format code
    # rows 13:16    compflg(4)
    # rows 17:20    chid
    # rows 21:24    expan2
    if full == true
      j = 0
      while j < N
        j = j + 1
        i = 16
        while i < 24
          i = i + 1
          if getindex(U8, i, j) == 0x00
            setindex!(U8, 0x20, i, j)
          end
        end
      end
    end

    seek(fid, getindex(I32, 2, 1))
    buf = getfield(BUF, :buf)
    checkbuf_8!(buf, 4*maximum(I32[1,:]))
    id = zeros(UInt8, 15)
    i = 0
    os = 0
    @inbounds while i < N
      i += 1
      skip(fid, os)
      nx = getindex(I32, 1, i)

      # Generate ID
      fill!(id, 0x00)
      id[1] = 0x55
      id[2] = 0x57
      id[3] = 0x2e
      id[12] = 0x2e
      fill_id!(id, getindex(U8, 1:8, i), 1, 8, 4, 8)
      fill_id!(id, getindex(U8, 13:16, i), 1, 4, 13, 15)
      id_str = String(id[id.!=0x00])

      # Save to SeisChannel
      C = SeisChannel()
      setfield!(C, :id, id_str)
      setfield!(C, :fs, Float64(getindex(I32, 5, i))*1.0e-3)
      setfield!(C, :units, "m/s")
      setfield!(C, :src, fname)
      if full == true
        D = getfield(C, :misc)
        D["lta"]    = I16[1,i]
        D["trig"]   = I16[2,i]
        D["bias"]   = I16[3,i]
        D["chid"]   = String(getindex(U8, 17:20, i))
        D["expan2"] = String(getindex(U8, 21:24, i))
        if i == 1
          D["mast_fs"]    = mast_fs*1.0f-3
          D["mast_lmin"]  = mast_lmin
          D["mast_lsec"]  = mast_lsec
          D["mast_nx"]    = mast_nx
          D["extra"]      = String(extra)

          # Go back to master header; grab what we skipped
          p = position(fid)
          seek(fid, 18)         # we have the first few fields already
          D["mast_tape_no"]   = bswap(read(fid, Int16))
          D["mast_event_no"]  = bswap(read(fid, Int16))
          D["flags"]          = bswap.(read!(fid, Array{Int16, 1}(undef, 10)))
          skip(fid, 10)         # we have "extra" already
          comment             = read(fid,80)
          D["comment"]        = String(comment[comment.!=0x00])

          # Return to where we were
          seek(fid, p)
        end
      end

      # Generate T
      t = Array{Int64,2}(undef,2,2)
      ch_time = 60000000*Int64(getindex(I32, 3, i)) +
                Int64(getindex(I32, 4, i)) +
                getindex(timecorr, i) -
                11676096000000000
      setindex!(t, one(Int64), 1)
      setindex!(t, nx, 2)
      setindex!(t, ch_time, 3)
      setindex!(t, zero(Int64), 4)
      setfield!(C, :t, t)

      # Generate X
      x = Array{Float32,1}(undef, nx)
      fmt = getindex(U8, 9, i)
      if fmt == 0x53
        readbytes!(fid, buf, 2*nx)
        fillx_i16_be!(x, buf, nx, 0)
      elseif fmt == 0x4c
        readbytes!(fid, buf, 4*nx)
        fillx_i32_be!(x, buf, nx, 0)
      else
        readbytes!(fid, buf, 4*nx)
        x .= bswap.(reinterpret(Float32, buf))[1:nx]
      end
      setfield!(C, :x, x)

      # Push to SeisData
      push!(S,C)

      if i < N
        os = getindex(I32, 2, i+1) - position(fid)
      end
    end
    note!(S, string("+src: readuw(", fname, ")"))
  end
  close(fid)
  return S
end
