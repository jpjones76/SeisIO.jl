function get_sep(v_buf::Array{UInt8,1}, vi::Int8)
  z = zero(Int8)
  o = one(Int8)
  i = z
  while i < vi
    i += o
    y = getindex(v_buf, i)
    if y != 0x20
      return y
    end
  end
end

function geocsv_mkid(v_buf::Array{UInt8,1}, vi::Int8)
  # SID
  i = 0x00
  while i < vi
    i += 0x01
    if getindex(v_buf, i) == 0x5f
      setindex!(v_buf, 0x2e, i)
    end
  end
  return String(v_buf[0x01:vi])
end

function geocsv_assign!(C::SeisChannel,
                        k_buf::Array{UInt8,1},
                        v_buf::Array{UInt8,1},
                        ki::Int8,
                        vi::Int8)
  o = one(Int8)
  k = String(k_buf[o:ki])
  ptr = pointer(v_buf[o:vi])

  if k == "sample_rate_hz"
    setfield!(C, :fs, parse(Float64, unsafe_string(ptr)))
  elseif k == "latitude_deg"
    setfield!(C.loc, :lat, parse(Float64, unsafe_string(ptr)))
  elseif k == "longitude_deg"
    setfield!(C.loc, :lon, parse(Float64, unsafe_string(ptr)))
  elseif k == "elevation_m"
    setfield!(C.loc, :el, parse(Float64, unsafe_string(ptr)))
  elseif k == "azimuth_deg"
    setfield!(C.loc, :az, parse(Float64, unsafe_string(ptr)))
  elseif k == "dip_deg"
    setfield!(C.loc, :inc, 90.0-parse(Float64, unsafe_string(ptr)))
  elseif k == "depth_m"
    setfield!(C.loc, :dep, parse(Float64, unsafe_string(ptr)))
  elseif k == "scale_factor"
    setfield!(C, :gain, parse(Float64, unsafe_string(ptr)))
  elseif k == "scale_frequency_hz"
    C.misc[k] = parse(Float64, unsafe_string(ptr))
  elseif k == "scale_units"
    setfield!(C, :units, lowercase(unsafe_string(ptr)))
  else
    C.misc[k] = unsafe_string(ptr)
  end
  return nothing
end

function mkhdr(io::IO, c::UInt8, k_buf::Array{UInt8,1}, v_buf::Array{UInt8,1})
  k = true
  o = one(Int8)
  i = zero(Int8)
  j = zero(Int8)

  # skip space after a new line
  while c == 0x20; c = fastread(io); end

  while c != 0x0a
    if c == 0x23
      c = fastread(io)
      while c == 0x20
        c = fastread(io)
      end
    # transition at 0x3a
    elseif c == 0x3a && k == true
      k = false
      c = fastread(io)
      while c == 0x20
        c = fastread(io)
      end
    elseif k
      i += o
      setindex!(k_buf, c, i)
      c = fastread(io)
    else
      j += o
      setindex!(v_buf, c, j)
      c = fastread(io)
    end
  end
  return i,j
end

function read_geocsv_slist!(S::GphysData, io::IO)
  o = one(Int16)
  oo = one(Int64)
  z = zero(Int16)

  c = 0x00
  j = z
  sep = 0x2c
  t = oo
  t_old = oo
  t_exp = 5
  Δ = oo
  Δ_gap = oo
  i = oo
  x = zero(Float32)
  k = ""
  v = ""
  nx = zero(UInt64)

  C = SeisChannel()
  C.loc = GeoLoc()
  X = Array{Float32,1}(undef, 0)

  k_buf = Array{UInt8,1}(undef, 80)
  v_buf = Array{UInt8,1}(undef, 80)
  t_buf = Array{UInt8,1}(undef, 32)
  t_ptr = pointer(t_buf)

  reading_data = false
  is_float = false

  # Time structure
  tm = TmStruct()

  while !fasteof(io)
    c = fastread(io)

    # new line ----------------------------------
    (c == 0x0a) && continue

    # parse header ------------------------------
    if c == 0x23
      if reading_data == true

      # '#' after newline
        C.t = vcat(C.t, [i-1 zero(Int64)])
        append!(C.x, X)
        push!(S, C)
        C = SeisChannel()
        C.loc = GeoLoc()
        i = oo
        reading_data = false
      end
      (ki, vi) = mkhdr(io, c, k_buf, v_buf)

      if ki == Int8(9)
        sep = get_sep(v_buf, vi)
      elseif ki == Int8(12)
        if k_buf[1] == 0x73 && k_buf[2] == 0x61
          nx = buf_to_uint(v_buf, vi)
        else
          geocsv_assign!(C, k_buf, v_buf, ki, vi)
        end
      elseif ki == Int8(3)
        id = geocsv_mkid(v_buf, vi)
        ii = findid(S, id)
        if ii > 0
          C = pull(S, ii)
        else
          C.id = id
        end
        Nt = size(C.t, 1)
        if Nt > 0
          t_old = endtime(C.t, round(Int64, sμ/C.fs))
          i = C.t[Nt, 1] + 1
          if C.t[Nt, 2] == 0
            C.t = C.t[1:Nt-1,:]
          end
        else
          t_old = oo
        end
      else
        geocsv_assign!(C, k_buf, v_buf, ki, vi)
      end

    # any other character after newline
    else
      if reading_data == false
        # transition from header to data
        t_str = get(C.misc, "start_time", "1970-01-01T000000.000000Z")
        t = String.(split(t_str, ('T', '.')))
        ts = (Date(t[1]).instant.periods.value)*86400000000 +
              div(Time(t[2]).instant.value, 1000) -
              dtconst

        #= weirdly, *much* more efficient than *either*
        Array{Float32,1}(undef, 0) with push! or
        Array{Float32,1}(undef, x) s setindex!
        =#
        X = Float32[]; sizehint!(X, nx)
        Δ = round(Int64, sμ/getfield(C, :fs))
        if isempty(C.t)
          C.t = [1 ts]
        else
          C.t = vcat(C.t, [i ts-t_old-Δ])
        end
        reading_data = true
        while is_u8_digit(c) == false
          c = fastread(io)
        end
      end
      x = stream_float(io, c)
      push!(X, x)
      i += 1
    end
  end
  append!(C.x, X)
  push!(S, C)
  return nothing
end

function read_geocsv_tspair!(S::GphysData, io::IO)
  o = one(Int16)
  oo = one(Int64)
  z = zero(Int16)

  c = 0x00
  j = z
  sep = 0x2c
  t = oo
  t_old = oo
  t_exp = 5
  Δ = oo
  Δ_gap = oo
  i = oo
  x = zero(Float32)
  k = ""
  v = ""
  nx = zero(UInt64)

  C = SeisChannel()
  C.loc = GeoLoc()
  X = Array{Float32,1}(undef, 0)

  k_buf = Array{UInt8,1}(undef, 80)
  v_buf = Array{UInt8,1}(undef, 80)
  t_buf = Array{UInt8,1}(undef, 32)
  t_ptr = pointer(t_buf)

  read_state = 0x00
  reading_data = false
  is_float = false

  # Time structure
  tm = TmStruct()

  # read_state:
  # 0x00    new line
  # 0x01    hdr (subroutine)
  # 0x02    time
  # 0x03    fractional-second
  # 0x04    data

  while !fasteof(io)
    c = fastread(io)

    # new line ----------------------------------
    if c == 0x0a
      read_state = 0x00

      # No parsing of c
      continue
    end

    # determine next read state -----------------
    if read_state == 0x00

      # '#' after newline
      if c == 0x23
        # transition from data to header
        if reading_data == true

          # finish current SeisChannel
          C.t = vcat(C.t, [i-1 zero(Int64)])
          append!(C.x, X)
          push!(S, C)
          C = SeisChannel()
          C.loc = GeoLoc()
          i = oo
          reading_data = false
        end
        (ki, vi) = mkhdr(io, c, k_buf, v_buf)
        if ki == Int8(9)
          sep = get_sep(v_buf, vi)
        elseif ki == Int8(12)
          if k_buf[1] == 0x73 && k_buf[2] == 0x61
            nx = buf_to_uint(v_buf, vi)
          else
            geocsv_assign!(C, k_buf, v_buf, ki, vi)
          end
        elseif ki == Int8(3)
          id = geocsv_mkid(v_buf, vi)
          ii = findid(S, id)
          if ii > 0
            C = pull(S, ii)
          else
            C.id = id
          end
          Nt = size(C.t, 1)
          if Nt > 0
            t_old = endtime(C.t, round(Int64, sμ/C.fs))
            i = C.t[Nt, 1] + 1
            if C.t[Nt, 2] == 0
              C.t = C.t[1:Nt-1,:]
            end
          else
            t_old = oo
          end
        else
          geocsv_assign!(C, k_buf, v_buf, ki, vi)
        end
        read_state = 0x00

        continue

      # any other character after newline
      else
        read_state = 0x02
        fill!(t_buf, 0x20)
        j = z

        # Requires transition from header to time
        if reading_data == false
          #= weirdly, *much* more efficient than *either*
          Array{Float32,1}(undef, 0) with push! or
          Array{Float32,1}(undef, x) s setindex!
          =#
          X = Float32[]; sizehint!(X, nx)
          Δ = round(Int64, sμ/getfield(C, :fs))
          Δ_gap = div(3*Δ,2)

          # Flag that we're now reading data
          reading_data = true
        end
      end
    end

    # 0x02 = time state -------------------------
    # elseif read_state == 0x02
    if read_state == 0x02

      # '.'
      if c == 0x2e
        # only happens at a decimal in a time block
        ccall(:strptime, Cstring, (Cstring, Cstring, Ref{TmStruct}), t_ptr, "%FT%T", tm)
        t = (Sys.iswindows() ? ccall(:_mkgmtime, Int64, (Ref{TmStruct},), tm) : ccall(:timegm, Int64, (Ref{TmStruct},), tm))* 1000000
        read_state = 0x03
        continue

      else
        j += o
        setindex!(t_buf, c, j)
      end

    # 0x03 = fractional-second state ------------
    elseif read_state == 0x03

      # ',', typically
      if c == sep
        t_exp = 5
        j = z

        if t-t_old > Δ_gap
          if t_old == oo
            C.t = vcat(C.t, [i t])
          else
            C.t = vcat(C.t, [i t-t_old-Δ])
          end
        end
        t_old = t

        read_state = 0x04
        continue

      # intent: ignore the time zone, users can fix manually
      # zero out t_exp when we reach timezone crap
      elseif c == 0x02b || c == 0x02d || c == 0x05a
        t_exp = 0
      elseif t_exp > oo
        t += Int64(c-0x30)*10^t_exp
        t_exp -= oo
      else
        continue
      end

    # 0x04 = data state -------------------------
    elseif read_state == 0x04
      x = stream_float(io, c)
      push!(X, x)
      read_state = 0x00
      i += 1
    else
      error("indeterminate read state")
    end

  end
  C.t = vcat(C.t, [i-1 zero(Int64)])
  append!(C.x, X)
  push!(S, C)
  return nothing
end

function read_geocsv_file!(S::GphysData, fname::String, tspair::Bool, memmap::Bool)
  io = memmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  if tspair == true
    read_geocsv_tspair!(S, io)
  else
    read_geocsv_slist!(S, io)
  end
  close(io)
  return nothing
end
