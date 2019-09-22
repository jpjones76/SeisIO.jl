function ah_time(t::Array{Int32,1}, ts::Float32)
  broadcast!(bswap, t, t)
  y = t[1]
  ts = Float64(bswap(ts))
  return y2μs(y) + Int64(md2j(y, t[2], t[3])-one(Int32))*86400000000 +
    Int64(t[4])*3600000000 + Int64(t[5])*60000000 + round(Int64, ts*sμ)
end

function read_ah_str(io::IO, j::Int64)
  n = bswap(read(io, Int32))
  r = rem(n, 4)
  # these are all very short; a "for" loop is fastest
  for i = 1:n
    j += 1
    BUF.buf[j] = read(io, UInt8)
  end
  r > 0 && skip(io, 4-r)
  return j
end

function read_comm!(io::IO, buf::Array{UInt8,1}, full::Bool)
  n = bswap(read(io, Int32))
  r = rem(n, 4)
  j = 0
  k = 0
  if full
    checkbuf!(buf, n)
    readbytes!(io, buf, n)
    while k < n
      k += 1
      c = getindex(buf, k)
      if c != 0x00
        j += 1
        BUF.buf[j] = c
      end
    end
    (r > 0) && skip(io, 4-r)
  else
    (r > 0) && (n += 4-r)
    skip(io, n)
  end
  return j
end

# obnoxiously, our sample AH files use both 0x00 and 0x20 as string spacers
function mk_ah_id(js::Int64, jc::Int64, jn::Int64)
  fill!(BUF.id, 0x00)
  j = 0
  k = jc+1
  while j < 2 && k < jn
    c = getindex(BUF.buf, k)
    if c != 0x00 && c != 0x20
      j += 1
      BUF.id[j] = c
    end
    k += 1
  end
  j += 1
  J = j+5
  k = 1
  BUF.id[j] = 0x2e
  while j < J && k < js
    c = getindex(BUF.buf, k)
    if c != 0x00 && c != 0x20
      j += 1
      BUF.id[j] = c
    end
    k += 1
  end
  BUF.id[j] = 0x2e
  BUF.id[j+1] = 0x2e
  j += 1
  J = j+3
  k = js+1
  while j < J && k < jc
    c = getindex(BUF.buf, k)
    if c != 0x00 && c != 0x20
      j += 1
      BUF.id[j] = c
    end
    k += 1
  end
  return j
end

# AH-2
function read_ah2!(S::GphysData, ahfile::String;
  v::Int64=SeisIO.KW.v,
  full::Bool=false
  )

  io = open(ahfile, "r")
  str = getfield(BUF, :sac_cv)
  ti = BUF.date_buf
  resize!(ti, 5)

  while !eof(io)
    loc = GeoLoc()

    ver = bswap(read(io, Int32))
    ver == 1100 || error("Not a valid AH-2 file!")
    len = bswap(read(io, UInt32))

    # Station header =========================================================
    skip(io, 4)
    js = read_ah_str(io, 0)
    skip(io, 4)
    jc = read_ah_str(io, js)
    skip(io, 4)
    jn = read_ah_str(io, jc)
    jrec = read_ah_str(io, jn)
    jsen = read_ah_str(io, jrec)
    j = mk_ah_id(js, jc, jn)
    id = unsafe_string(pointer(BUF.id), j)

    # Fill SeisChannel header
    setfield!(loc, :az, Float64(bswap(read(io, Float32))))
    setfield!(loc, :inc, 90.0-bswap(read(io, Float32)))
    setfield!(loc, :lat, bswap(read(io, Float64)))
    setfield!(loc, :lon, bswap(read(io, Float64)))
    setfield!(loc, :el, Float64(bswap(read(io, Float32))))
    gain = bswap(read(io, Float32))

    C = SeisChannel(id = id,
                    loc = loc,
                    gain = Float64(gain)
                    )

    (v > 1) && println("id = ", C.id)
    if full
      C.misc["recorder"] = unsafe_string(pointer(BUF.buf, jn+1), jrec-jn)
      C.misc["sensor"] = unsafe_string(pointer(BUF.buf, jrec+1), jsen-jrec)
    end
    A0 = bswap(read(io, Float32))
    NP = bswap(read(io, Int32))
    P = zeros(Complex{Float32}, NP)
    read!(io, P)
    NZ = bswap(read(io, Int32))
    Z = zeros(Complex{Float32}, NZ)
    read!(io, Z)
    setfield!(C, :resp, PZResp(a0 = A0, p = P, z = Z))
    j = read_comm!(io, str, full)
    if full
      C.misc["sta_comment"] = unsafe_string(pointer(BUF.buf), j)
    end

    # Event header ==========================================================
    if full
      C.misc["ev_lat"] = bswap(read(io, Float64))
      C.misc["ev_lon"] = bswap(read(io, Float64))
      C.misc["ev_dep"] = bswap(read(io, Float32))
      read!(io, ti)
      t_s = read(io, Float32)
      skip(io, 4)
      j = read_comm!(io, str, full)
      C.misc["event_comment"] = unsafe_string(pointer(BUF.buf), j)
      C.misc["ot"] =  ah_time(ti, t_s)
      (v > 1) && println("ev_lat = ", C.misc["ev_lat"], ", ev_lon = ", C.misc["ev_lon"])
    else
      skip(io, 48)
      read_comm!(io, str, full)
    end

    # Data header ===========================================================
    fmt   = bswap(read(io, Int32))
    nx    = bswap(read(io, UInt32))
    dt    = bswap(read(io, Float32))
    Amax  = bswap(read(io, Float32))
    read!(io, ti)
    t_s   = read(io, Float32)
    n     = bswap(read(io, Int32))
    C.units = n > 0 ? unsafe_string(pointer(read(io, n))) : ""
    n = bswap(read(io, Int32))
    inunits = read(io, n)
    n = bswap(read(io, Int32))
    outunits = read(io, n)
    skip(io, 4)
    j = read_comm!(io, str, full)
    if full
      C.misc["data_comment"] = unsafe_string(pointer(BUF.buf), j)
      C.misc["units_in"] = unsafe_string(pointer(inunits))
      C.misc["units_out"] = unsafe_string(pointer(outunits))
      C.misc["Amax"] = Amax
      C.misc["ti"] = bswap.(copy(ti))
    end
    skip(io, 4)
    k = read_comm!(io, str, full)
    (v > 1) && println("nx = ", nx, ", dt = ", dt, ", Amax = ", Amax, ", k = ", k)
    if full
      # Log all processing to C.notes
      i = 0
      j = 0
      while j < k
        j += 1
        c = BUF.buf[j]
        if c == 0x00
          i = j
        elseif c == 0x3b && j-i > 1
          note!(C, unsafe_string(pointer(BUF.buf[i+1:j-1])) * ", recorded in .ah file log")
          i = j
        end
      end
    end

    nattr = bswap(read(io, Int32))
    if nattr > 0
      UA = Dict{String, String}()
      for i = 1:nattr
        j1 = read_ah_str(io, 0)
        j2 = read_ah_str(io, j)
        k = unsafe_string(pointer(BUF.buf), j1)
        V = unsafe_string(pointer(BUF.buf, j1+1), j2-j1)
        UA[k] = V
      end
      v > 1 && println("UA = ", UA)
      merge!(C.misc, UA)
    end

    # Create C.t
    t0 = ah_time(ti, t_s) #) + round(Int64, t_s*1.0e6)
    t = Array{Int64, 2}(undef, 2, 2)
    setindex!(t, one(Int64), 1)
    setindex!(t, nx, 2)
    setindex!(t, t0, 3)
    setindex!(t, zero(Int64), 4)
    setfield!(C, :t, t)

    # Set C.fs
    setfield!(C, :fs, 1.0/dt)

    # Data
    T = fmt == 1 ? Float32 : Float64
    x = Array{T, 1}(undef, nx)
    read!(io, x)
    x .= bswap.(x)
    v > 2 && println("x = [", x[1], ", ", x[2], ", ", x[3], ", ", x[4], ", ... ", x[nx-3], ", ", x[nx-2], ", ", x[nx-1], ", ", x[nx], "]")

    # Cleanup
    setfield!(C, :x, x)
    push!(S, C)
  end
  close(io)
  resize!(str, 192)
  resize!(ti, 7)
  if length(BUF.buf) != 65535
    resize!(BUF.buf, 65535)
  end
  return S
end

function read_ah1!(S::GphysData, ahfile::String;
  v     ::Int64 = SeisIO.KW.v,
  full  ::Bool  = false
  )

  fullfile = realpath(ahfile)
  io = open(ahfile, "r")
  str = getfield(BUF, :sac_cv)
  ti  = getfield(BUF, :date_buf)
  pz_buf = getfield(BUF, :x)
  if full
    stamp = timestamp() * ": "
  end
  resize!(ti, 5)
  resize!(pz_buf, 125)

  while !eof(io)
    # Create SeisChannel, location container
    misc = Dict{String,Any}()
    notes = Array{String,1}(undef,0)

    # Station header =========================================================
    js = read_ah_str(io, 0)
    jc = read_ah_str(io, js)
    jn = read_ah_str(io, jc)
    j  = mk_ah_id(js, jc, jn)
    id = unsafe_string(pointer(BUF.id), j)
    read!(io, pz_buf)

    # Event header ==========================================================
    if full
      misc["ev_lat"] = bswap(read(io, Float32))
      misc["ev_lon"] = bswap(read(io, Float32))
      misc["ev_dep"] = bswap(read(io, Float32))
      read!(io, ti)
      t_s = read(io, Float32)
      j   = read_comm!(io, str, full)
      misc["event_comment"] = unsafe_string(pointer(BUF.buf), j)
      misc["ot"] =  ah_time(ti, t_s)
      (v > 1) && printstyled("ev_lat = ", misc["ev_lat"], ", ev_lon = ", misc["ev_lon"], ", ev_dep = ", misc["ev_dep"], ", ")
    else
      skip(io, 36)
      read_comm!(io, str, full)
    end

    # Data header ===========================================================
    fmt   = bswap(read(io, Int32))
    nx    = bswap(read(io, UInt32))
    dt    = bswap(read(io, Float32))
    (v > 1) && println("nx = ", nx, ", dt = ", dt)
    if full
      misc["Amax"]  = bswap(read(io, Float32))
      read!(io, ti)
      t_s           = read(io, Float32)
      misc["xmin"]  = bswap(read(io, Float32))
      j             = read_comm!(io, str, full)

      # Log all processing to :notes
      misc["data_comment"] = unsafe_string(pointer(BUF.buf), j)
      k = read_comm!(io, str, full)

      # Log all processing to C.notes
      i = 0
      j = 1
      while j ≤ length(str)
        c = BUF.buf[j]
        if c == 0x00
          i = j
        elseif c == 0x3b && j-i > 1
          push!(notes, stamp * unsafe_string(pointer(BUF.buf, i+1), j-i-1) * ", recorded in .ah file log")
          i = j
        end
        j += 1
      end

      # Set all "extras" in :misc
      ne = bswap(read(io, UInt32))
      if ne > 0
        misc["extras"] = zeros(Float32, ne)
        read!(io, misc["extras"])
        broadcast!(bswap, misc["extras"], misc["extras"])
      end
    else
      skip(io, 4)
      read!(io, ti)
      t_s = read(io, Float32)
      skip(io, 4)
      read_comm!(io, str, full)
      read_comm!(io, str, full)
      ne = bswap(read(io, UInt32))
      if ne > 0
        skip(io, 0x00000004*ne)
      end
    end

    # Set fields in C =======================================================
    broadcast!(bswap, pz_buf, pz_buf)

    # :resp
    NP = round(Int32, pz_buf[6])
    NZ = round(Int32, pz_buf[8])
    P = zeros(Complex{Float32}, NP)
    Z = zeros(Complex{Float32}, NZ)
    NC = max(NP, NZ)
    k = 10
    for i = 1:NC
      (i > NP) || (P[i] = complex(pz_buf[k], pz_buf[k+1]))
      (i > NZ) || (Z[i] = complex(pz_buf[k+2], pz_buf[k+3]))
      k += 4
    end

    j = mk_ah_id(js, jc, jn)
    C = SeisChannel(id,
                    "",
                    GeoLoc("",
                           Float64(pz_buf[1]),
                           Float64(pz_buf[2]),
                           Float64(pz_buf[3]),
                           0.0,
                           0.0,
                           0.0),
                    1.0/dt,
                    Float64(pz_buf[4]),
                    PZResp(pz_buf[5], 0.0f0, P, Z),
                    "",
                    fullfile,
                    misc,
                    notes,
                    mk_t(nx, ah_time(ti, t_s)),
                    Array{fmt == one(Int32) ? Float32 : Float64, 1}(undef, nx))

    x = getfield(C, :x)
    read!(io, x)
    broadcast!(bswap, x, x)
    (v > 2) && println("x[1:5] = ", x[1:5])

    # Cleanup
    push!(S, C)
  end
  close(io)
  resize!(BUF.sac_cv, 192)
  resize!(BUF.date_buf, 7)
  resize!(BUF.x, 65535)
  if length(BUF.buf) != 65535
    resize!(BUF.buf, 65535)
  end
  return S
end
