import Base.Libc:TmStruct
export readgeocsv, readgeocsv!

function get_sep(vi::Int8, v_buf::Array{UInt8,1})
  z = zero(Int8)
  o = one(Int8)
  i = z
  while i < vi
    i += o
    y = getindex(v_buf, i)
    if y != 0x20
      return y
      break
    end
  end
  return nothing
end

function assign_val!(C::SeisChannel,
                      loc::Array{Float64,1},
                      k_buf::Array{UInt8,1},
                      v_buf::Array{UInt8,1},
                      ki::Int8,
                      vi::Int8)
  z = zero(Int8)
  o = one(Int8)
  k::String = ""

  # SID
  if ki == 3
    i = z
    while i < vi
      i += o
      if getindex(v_buf,i) == 0x5f
        setindex!(v_buf, 0x2e, i)
      end
    end
    v = String(v_buf[o:vi])
    setfield!(C, :id, v)

  else
    k = String(k_buf[o:ki])
    ptr = pointer(v_buf[o:vi])
    loc_i = z

    if k == "sample_rate_hz"
      # setfield!(C, :fs, ccall(:strtod, Float64, (Cstring, Ptr), ptr, C_NULL))
      setfield!(C, :fs, parse(Float64, unsafe_string(ptr)))
    elseif k == "latitude_deg"
      loc_i = Int8(1)
    elseif k == "longitude_deg"
      loc_i = Int8(2)
    elseif k == "elevation_m"
      loc_i = Int8(3)
    elseif k == "azimuth_deg"
      loc_i = Int8(4)
    elseif k == "dip_deg"
      loc_i = Int8(5)
    elseif k == "depth_m"
      loc_i = Int8(6)
    elseif k == "scale_factor"
      # setfield!(C, :gain, ccall(:strtod, Float64, (Cstring, Ptr), ptr, C_NULL))
      setfield!(C, :gain, parse(Float64, unsafe_string(ptr)))
    elseif k == "scale_frequency_hz"
      # C.misc[k] = ccall(:strtod, Float64, (Cstring, Ptr), ptr, C_NULL)
      C.misc[k] = parse(Float64, unsafe_string(ptr))
    elseif k == "scale_units"
      setfield!(C, :units, lowercase(unsafe_string(ptr)))
    else
      C.misc[k] = unsafe_string(ptr)
    end

    if loc_i > z
      # d = ccall(:strtod, Float64, (Cstring, Ptr), ptr, C_NULL)
      d = parse(Float64, unsafe_string(ptr))
      setindex!(loc, d, loc_i)
    end
  end
  return nothing
end

function mkhdr(io::IO, c::UInt8, k_buf::Array{UInt8,1}, v_buf::Array{UInt8,1})
  k = true
  o = one(Int8)
  i = zero(Int8)
  j = zero(Int8)

  # skip space after a new line
  while c == 0x20
    c = read(io, UInt8)
  end

  while c != 0x0a
    if c == 0x23
      c = read(io, UInt8)
      while c == 0x20
        c = read(io, UInt8)
      end
    # transition at 0x3a
    elseif c == 0x3a && k == true
      k = false
      c = read(io, UInt8)
      while c == 0x20
        c = read(io, UInt8)
      end
    elseif k
      i += o
      setindex!(k_buf, c, i)
      c = read(io, UInt8)
    else
      j += o
      setindex!(v_buf, c, j)
      c = read(io, UInt8)
    end
  end
  return i,j
end

function read_geocsv_slist!(S::SeisData, io::IO)
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
  loc = Array{Float64,1}(undef, 6)
  T = Array{Int64,2}(undef, 0, 2)
  X = Array{Float32,1}(undef, 0)

  k_buf = Array{UInt8,1}(undef, 80)
  v_buf = Array{UInt8,1}(undef, 80)
  t_buf = Array{UInt8,1}(undef, 32)
  t_ptr = pointer(t_buf)

  reading_data = false
  is_float = false

  # Time structure
  tm = TmStruct()

  while !eof(io)
    c = read(io, UInt8)

    # new line ----------------------------------
    if c == 0x0a
      continue
    end

    # parse header ------------------------------
    if c == 0x23
      if reading_data == true

      # '#' after newline
        setfield!(C, :loc, loc)
        setfield!(C, :t, T)
        setfield!(C, :x, X)
        push!(S, C)
        C = SeisChannel()
        loc = Array{Float64,1}(undef, 6)
        i = oo
        reading_data = false
      end
      (ki, vi) = mkhdr(io, c, k_buf, v_buf)
      # println(String(k_buf[1:ki]), " = ", String(v_buf[1:vi]))
      if ki == Int8(9)
        sep = get_sep(vi, v_buf)
      elseif ki == Int8(12)
        if k_buf[1] == 0x73 && k_buf[2] == 0x61
          nx = mkuint(vi, v_buf)
        else
          assign_val!(C, loc, k_buf, v_buf, ki, vi)
        end
      else
        assign_val!(C, loc, k_buf, v_buf, ki, vi)
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
        T = Array{Int64,2}(undef, 2, 2)
        setindex!(T, one(Int64), 1)
        setindex!(T, Int64(nx), 2)
        setindex!(T, ts, 3)
        setindex!(T, zero(Int64), 4)

        Δ = round(Int64, 1.0e6/getfield(C, :fs))
        Δ_gap = div(3*Δ,2)
        t_old = oo
        reading_data = true
        while is_u8_digit(c) == false
          c = read(io, UInt8)
        end
      end
      x = mkfloat(io, c)
      push!(X, x)
      i += 1
    end
  end
  setfield!(C, :loc, loc)
  setfield!(C, :t, T)
  setfield!(C, :x, X)
  push!(S, C)
  return nothing
end

function read_geocsv_tspair!(S::SeisData, io::IO)
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
  loc = Array{Float64,1}(undef, 6)
  T = Array{Int64,2}(undef, 0, 2)
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

  while !eof(io)
    c = read(io, UInt8)

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
          T = vcat(T, [i zero(Int64)])
          setfield!(C, :loc, loc)
          setfield!(C, :t, T)
          setfield!(C, :x, X)
          push!(S, C)
          C = SeisChannel()
          loc = Array{Float64,1}(undef, 6)
          i = oo
          reading_data = false
        end
        (ki, vi) = mkhdr(io, c, k_buf, v_buf)
        if ki == Int8(9)
          sep = get_sep(vi, v_buf)
        elseif ki == Int8(12)
          if k_buf[1] == 0x73 && k_buf[2] == 0x61
            nx = mkuint(vi, v_buf)
          else
            assign_val!(C, loc, k_buf, v_buf, ki, vi)
          end
        else
          assign_val!(C, loc, k_buf, v_buf, ki, vi)
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
          T = Array{Int64,2}(undef, 0, 2)
          Δ = round(Int64, 1.0e6/getfield(C, :fs))
          Δ_gap = div(3*Δ,2)
          t_old = oo

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
        t = ccall(:mktime, Int64, (Ref{TmStruct},), tm) * 1000000
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
            T = vcat(T, [i t-t_old])
          else
            T = vcat(T, [i t-t_old-Δ])
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
      x = mkfloat(io, c)
      push!(X, x)
      read_state = 0x00
      i += 1
    else
      error("indeterminate read state")
    end

  end
  T = vcat(T, [i zero(Int64)])
  setfield!(C, :loc, loc)
  setfield!(C, :t, T)
  setfield!(C, :x, X)
  push!(S, C)
  return nothing
end

function read_geocsv_file!(S::SeisData, fname::String, tspair::Bool)
  io = open(fname, "r")
  if tspair == true
    read_geocsv_tspair!(S, io)
  else
    read_geocsv_slist!(S, io)
  end
  close(io)
  return nothing
end

@doc """

    readgeocsv!(S, filestr[, tspair])

Read GeoCSV time-series ASCII files matching `filestr` into existing SeisData
object `S`.

    S = readgeocsv(filestr[, tspair])

Read GeoCSV time-series ASCII files matching `filestr` into new SeisData object
`S`.

`tspair=true` (default) assumes data are given as time-sample pairs, with one
pair per line. If `tspair=false`, data are assumed to be in "slist" (single-
column) format with no time stamps.

!!! note

GeoCSV .zip files are **NOT** supported.

!!! warning

    In `tspair` mode, GeoCSV treats sample time stamps as UTC. If this yields
wrong times, the user must manually correct `S.t`.
""" readgeocsv
function readgeocsv!(S::SeisData, filestr::String; tspair::Bool=true)
  if safe_isfile(filestr)
    read_geocsv_file!(S, filestr, tspair)
  else
    files = ls(filestr)
    nf = length(files)
    for fname in files
      read_geocsv_file!(S, fname, tspair)
    end
  end
  return nothing
end

@doc (@doc readgeocsv)
function readgeocsv(filestr::String; tspair::Bool=true)
  S = SeisData()
  readgeocsv!(S, filestr, tspair=tspair)
  return S
end
