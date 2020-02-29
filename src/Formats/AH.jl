function ah_time(t::Array{Int32,1}, ts::Float32)
  broadcast!(bswap, t, t)
  y = t[1]
  ts = Float64(bswap(ts))
  return y2μs(y) + Int64(md2j(y, t[2], t[3])-one(Int32))*86400000000 +
    Int64(t[4])*3600000000 + Int64(t[5])*60000000 + round(Int64, ts*sμ)
end

function read_ah_str(io::IO, j::Int64)
  n = bswap(fastread(io, Int32))
  r = rem(n, 4)
  # these are all very short; a "for" loop is fastest
  for i = 1:n
    j += 1
    BUF.buf[j] = fastread(io)
  end
  r > 0 && fastskip(io, 4-r)
  return j
end

function read_comm!(io::IO, buf::Array{UInt8,1}, full::Bool)
  n = bswap(fastread(io, Int32))
  r = rem(n, 4)
  j = 0
  k = 0
  if full
    checkbuf!(buf, n)
    fast_readbytes!(io, buf, n)
    while k < n
      k += 1
      c = getindex(buf, k)
      if c != 0x00
        j += 1
        BUF.buf[j] = c
      end
    end
    (r > 0) && fastskip(io, 4-r)
  else
    (r > 0) && (n += 4-r)
    fastskip(io, n)
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

mk_ah_chan(id::String, loc::GeoLoc, fs::Float64, resp::PZResp, ahfile::String, misc::Dict{String, Any}, notes::Array{String, 1}, nx::Integer, t0::Integer, x::FloatArray) =
  SeisChannel(id,
              "",
              loc,
              fs,
              Float64(BUF.x[4]),
              resp,
              "",
              ahfile,
              misc,
              notes,
              mk_t(nx, t0),
              x)

# AH-2
function read_ah2!(S::GphysData, ahfile::String, full::Bool, memmap::Bool, strict::Bool, v::Integer)
  io = memmap ? IOBuffer(Mmap.mmap(ahfile)) : open(ahfile, "r")
  str = getfield(BUF, :sac_cv)
  ti = BUF.date_buf
  resize!(ti, 5)
  if full
    stamp = timestamp() * " ¦ "
  end

  while !eof(io)
    misc = Dict{String,Any}()
    notes = Array{String,1}(undef, 0)
    loc = GeoLoc()

    ver = bswap(fastread(io, Int32))
    ver == 1100 || error("Not a valid AH-2 file!")
    len = bswap(fastread(io, UInt32))

    # Station header =========================================================
    fastskip(io, 4)
    js = read_ah_str(io, 0)
    fastskip(io, 4)
    jc = read_ah_str(io, js)
    fastskip(io, 4)
    jn = read_ah_str(io, jc)
    j = mk_ah_id(js, jc, jn)
    id = unsafe_string(pointer(BUF.id), j)
    (v > 1) && println("id = ", id)

    jrec = read_ah_str(io, jn)
    jsen = read_ah_str(io, jrec)
    if full
      misc["recorder"] = unsafe_string(pointer(BUF.buf, jn+1), jrec-jn)
      misc["sensor"] = unsafe_string(pointer(BUF.buf, jrec+1), jsen-jrec)
    end

    # location
    setfield!(loc, :az, Float64(bswap(fastread(io, Float32))))
    setfield!(loc, :inc, 90.0-bswap(fastread(io, Float32)))
    setfield!(loc, :lat, bswap(fastread(io, Float64)))
    setfield!(loc, :lon, bswap(fastread(io, Float64)))
    setfield!(loc, :el, Float64(bswap(fastread(io, Float32))))

    BUF.x[4] = bswap(fastread(io, Float32))     # gain
    BUF.x[5] = bswap(fastread(io, Float32))     # A0

    # poles
    NP = bswap(fastread(io, Int32))
    P = zeros(Complex{Float32}, NP)
    fastread!(io, P)

    # zeros
    NZ = bswap(fastread(io, Int32))
    Z = zeros(Complex{Float32}, NZ)
    fastread!(io, Z)

    # station comment
    j = read_comm!(io, str, full)
    if full
      misc["sta_comment"] = unsafe_string(pointer(BUF.buf), j)
    end

    # Event header ==========================================================
    if full
      misc["ev_lat"] = bswap(fastread(io, Float64))
      misc["ev_lon"] = bswap(fastread(io, Float64))
      misc["ev_dep"] = bswap(fastread(io, Float32))
      fastread!(io, ti)
      t_s = fastread(io, Float32)
      fastskip(io, 4)
      j = read_comm!(io, str, full)
      misc["event_comment"] = unsafe_string(pointer(BUF.buf), j)
      misc["ot"] =  ah_time(ti, t_s)
      (v > 1) && println("ev_lat = ", misc["ev_lat"], ", ev_lon = ", misc["ev_lon"])
    else
      fastskip(io, 48)
      read_comm!(io, str, full)
    end

    # Data header ===========================================================
    fmt   = bswap(fastread(io, Int32))
    nx    = bswap(fastread(io, UInt32))
    dt    = bswap(fastread(io, Float32))
    Amax  = bswap(fastread(io, Float32))
    fastread!(io, ti)
    t_s   = fastread(io, Float32)
    n     = bswap(fastread(io, Int32))
    units = n > 0 ? unsafe_string(pointer(fastread(io, n))) : ""
    n     = bswap(fastread(io, Int32))
    u_i   = fastread(io, n)
    n     = bswap(fastread(io, Int32))
    u_o   = fastread(io, n)
    fastskip(io, 4)
    j     = read_comm!(io, str, full)
    if full
      misc["data_comment"]  = unsafe_string(pointer(BUF.buf), j)
      misc["units_in"]      = unsafe_string(pointer(u_i))
      misc["units_out"]     = unsafe_string(pointer(u_o))
      misc["Amax"]          = Amax
      misc["ti"]            = bswap.(copy(ti))
    end
    fastskip(io, 4)
    k     = read_comm!(io, str, full)
    (v > 1) && println("nx = ", nx, ", dt = ", dt, ", Amax = ", Amax, ", k = ", k)
    if full
      # Log all processing to C.notes
      i = 0
      j = 0
      while j < k
        j += 1
        c = BUF.buf[j]
        if c == 0x3b && j-i > 1
          push!(notes, stamp * unsafe_string(pointer(BUF.buf, i+1), j-i-1) * ", recorded in .ah file log")
          i = j
        end
      end
    end

    nattr = bswap(fastread(io, Int32))
    if nattr > 0
      UA = Dict{String, String}()
      for i = 1:nattr
        j1 = read_ah_str(io, 0)
        j2 = read_ah_str(io, j1)
        k = unsafe_string(pointer(BUF.buf), j1)
        V = unsafe_string(pointer(BUF.buf, j1+1), j2-j1)
        UA[k] = V
      end
      v > 1 && println("UA = ", UA)
      merge!(misc, UA)
    end

    # Determine if we have data from this channel already
    fs = 1.0/dt
    resp = PZResp(BUF.x[5], 0.0f0, P, Z)
    units = units2ucum(units)
    j = findid(S, id)
    if strict
      j = channel_match(S, j, fs, BUF.x[4], loc, resp, units)
    end

    t0 = ah_time(ti, t_s)
    x = Array{fmt == one(Int32) ? Float32 : Float64, 1}(undef, nx)
    fastread!(io, x)
    broadcast!(bswap, x, x)
    if j == 0
      C = mk_ah_chan(id, loc, fs, resp, ahfile, misc, notes, nx, t0, x)
      C.units = units
      push!(S, C)
      j = S.n
    else
      check_for_gap!(S, j, t0, nx, v)
      append!(S.x[j], x)
    end
    (v > 1) && println("id = ", id, " channel ", j)
    (v > 2) && println("x = [", x[1], ", ", x[2], ", ", x[3], ", ", x[4], ", ... ", x[nx-3], ", ", x[nx-2], ", ", x[nx-1], ", ", x[nx], "]")
  end
  close(io)
  resize!(str, 192)
  resize!(ti, 7)
  resize!(BUF.buf, 65535)
  return S
end

function read_ah1!(S::GphysData, ahfile::String, full::Bool, memmap::Bool, strict::Bool, v::Integer)

  io = memmap ? IOBuffer(Mmap.mmap(ahfile)) : open(ahfile, "r")
  str = getfield(BUF, :sac_cv)
  ti  = getfield(BUF, :date_buf)
  pz_buf = getfield(BUF, :x)
  if full
    stamp = timestamp() * " ¦ "
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
    fastread!(io, pz_buf)

    # Event header ==========================================================
    if full
      misc["ev_lat"] = bswap(fastread(io, Float32))
      misc["ev_lon"] = bswap(fastread(io, Float32))
      misc["ev_dep"] = bswap(fastread(io, Float32))
      fastread!(io, ti)
      t_s = fastread(io, Float32)
      j   = read_comm!(io, str, full)
      misc["event_comment"] = unsafe_string(pointer(BUF.buf), j)
      misc["ot"] =  ah_time(ti, t_s)
      (v > 1) && printstyled("ev_lat = ", misc["ev_lat"], ", ev_lon = ", misc["ev_lon"], ", ev_dep = ", misc["ev_dep"], ", ")
    else
      fastskip(io, 36)
      read_comm!(io, str, full)
    end

    # Data header ===========================================================
    fmt   = bswap(fastread(io, Int32))
    nx    = bswap(fastread(io, UInt32))
    dt    = bswap(fastread(io, Float32))
    (v > 1) && println("nx = ", nx, ", dt = ", dt)
    if full
      misc["Amax"]  = bswap(fastread(io, Float32))
      fastread!(io, ti)
      t_s           = fastread(io, Float32)
      misc["xmin"]  = bswap(fastread(io, Float32))
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
      ne = bswap(fastread(io, UInt32))
      if ne > 0
        misc["extras"] = zeros(Float32, ne)
        fastread!(io, misc["extras"])
        broadcast!(bswap, misc["extras"], misc["extras"])
      end
    else
      fastskip(io, 4)
      fastread!(io, ti)
      t_s = fastread(io, Float32)
      fastskip(io, 4)
      read_comm!(io, str, full)
      read_comm!(io, str, full)
      ne = bswap(fastread(io, UInt32))
      if ne > 0
        fastskip(io, 0x00000004*ne)
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

    # Determine if we have data from this channel already
    fs = 1.0/dt
    loc = GeoLoc("", Float64(BUF.x[1]), Float64(BUF.x[2]), Float64(BUF.x[3]), 0.0, 0.0, 0.0)
    resp = PZResp(BUF.x[5], 0.0f0, P, Z)
    j = findid(S, id)
    if strict
      j = channel_match(S, j, fs, BUF.x[4], loc, resp, "")
    end

    # Assign to SeisChannel, or append S[j]
    t0 = ah_time(ti, t_s)
    x = Array{fmt == one(Int32) ? Float32 : Float64, 1}(undef, nx)
    fastread!(io, x)
    broadcast!(bswap, x, x)
    if j == 0
      C = mk_ah_chan(id, loc, fs, resp, ahfile, misc, notes, nx, t0, x)
      push!(S, C)
      j = S.n
    else
      S.t[j] = t_extend(S.t[j], t0, nx, S.fs[j])
      append!(S.x[j], x)
    end
    (v > 0) && println("id = ", id, " channel ", j, ", L = ", length(S.x[j]))
    (v > 2) && println("x[1:5] = ", x[1:5])
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
