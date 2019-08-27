function read_ah_str(io::IO)
  n = bswap(read(io, Int32))
  r = rem(n, 4)
  str = read(io, n)
  r > 0 && skip(io, 4-r)
  return str
end

function read_comm!(io::IO, buf::Array{UInt8,1}, full::Bool)
  n = bswap(read(io, Int32))
  r = rem(n, 4)
  if full
    checkbuf_strict!(buf, n)
    read!(io, buf)
    deleteat!(buf, buf.==0x00)
    r > 0 && skip(io, 4-r)
  else
    (r > 0) && (n += 4-r)
    skip(io, n)
  end
  return nothing
end

function mk_ah_id(net::Array{UInt8,1}, sta::Array{UInt8,1}, cha::Array{UInt8,1})
  nn = length(net)
  ns = length(sta)
  nc = length(cha)
  id = zeros(UInt8, nn+ns+nc+3)
  copyto!(id, 1, net, 1, nn)
  id[nn+1] = 0x2e
  copyto!(id, nn+2, sta, 1, ns)
  id[nn+ns+2] = 0x2e
  id[nn+ns+3] = 0x2e
  copyto!(id, nn+ns+4, cha, 1, nc)
  return unsafe_string(pointer(id))
end

# AH-2
function read_ah2(ahfile::String;
  v::Int64=SeisIO.KW.v,
  full::Bool=false
  )

  S = SeisData()
  io = open(ahfile, "r")
  str = getfield(BUF, :sac_cv)
  ti = zeros(Int32, 5)

  while !eof(io)
    ver = bswap(read(io, Int32))
    ver == 1100 || error("Not a valid AH-2 file!")
    len = bswap(read(io, UInt32))

    # Station header =========================================================
    skip(io, 4)
    sta = read_ah_str(io)
    skip(io, 4)
    cha = read_ah_str(io)
    skip(io, 4)
    net = read_ah_str(io)
    rec = read_ah_str(io)
    sen = read_ah_str(io)

    C = SeisChannel(id = mk_ah_id(net, sta, cha),
      loc = GeoLoc(
        az = Float64(bswap(read(io, Float32))),
        inc = Float64(90.0f0-bswap(read(io, Float32))),
        lat = bswap(read(io, Float64)),
        lon = bswap(read(io, Float64)),
        el = Float64(bswap(read(io, Float32)))
        ),
      gain = Float64(bswap(read(io, Float32)))
      )

    A0 = bswap(read(io, Float32))
    NP = bswap(read(io, Int32))
    P = Array{Complex{Float32},1}(undef, NP)
    read!(io, P)
    NZ = bswap(read(io, Int32))
    Z = Array{Complex{Float32},1}(undef, NZ)
    read!(io, Z)
    setfield!(C, :resp, PZResp(a0 = A0, p = P, z = Z))
    read_comm!(io, str, full)
    if full
      C.misc["sta_comment"] = unsafe_string(pointer(str))
      C.misc["recorder"] = unsafe_string(pointer(rec))
      C.misc["sensor"] = unsafe_string(pointer(sen))
    end
    (v > 2 ) && println("sta = ", String(sta), ", cha = ", String(cha), ", net = ", String(net))

    # Event header ==========================================================
    evlat = bswap(read(io, Float64))
    evlon = bswap(read(io, Float64))
    dep = bswap(read(io, Float32))
    read!(io, ti)
    t_s = read(io, Float32)
    skip(io, 4)
    read_comm!(io, str, full)
    if full
      C.misc["event_comment"] = unsafe_string(pointer(str))
      C.misc["ev_lat"] = evlat
      C.misc["ev_lon"] = evlon
      C.misc["ev_dep"] = dep
      ti = bswap.(ti)
      C.misc["ot"] =  u2d(Float64(div(y2μs(ti[1]), 1000000) +
                      (md2j(ti[1], ti[2], ti[3])-one(Int32))*86400 +
                      Int64(ti[4])*3600 + Int64(ti[5])*60) + t_s)
    end
    (v > 2) && println("ev_lat = ", evlat, ", ev_lon = ", evlon, ", dep = ", dep)

    # Data header ===========================================================
    dtype = bswap(read(io, Int32))
    nx    = bswap(read(io, UInt32))
    dt    = bswap(read(io, Float32))
    Amax  = bswap(read(io, Float32))
    read!(io, ti)
    t_s   = bswap(read(io, Float32))
    n = bswap(read(io, Int32))
    C.units = n > 0 ? unsafe_string(pointer(read(io, n))) : ""
    n = bswap(read(io, Int32))
    inunits = read(io, n)
    n = bswap(read(io, Int32))
    outunits = read(io, n)
    skip(io, 4)
    read_comm!(io, str, full)
    if full
      C.misc["data_comment"] = unsafe_string(pointer(str))
      C.misc["units_in"] = unsafe_string(pointer(inunits))
      C.misc["units_out"] = unsafe_string(pointer(outunits))
      C.misc["Amax"] = Amax
      C.misc["ti"] = bswap.(copy(ti))
      C.misc["t_s"] = t_s
    end
    skip(io, 4)
    read_comm!(io, str, full)
    (v > 2) && println("nx = ", nx, ", dt = ", dt, ", Amax = ", Amax)
    if full
      # Log all processing to C.notes
      i = 0
      j = 1
      while j ≤ length(str)
        if str[j] == 0x00
          i = j
        elseif str[j] == 0x3b && j-i > 1
          note!(C, unsafe_string(pointer(str[i+1:j-1])) * ", recorded in .ah file log")
          i = j
        end
        j += 1
      end
    end

    nattr = bswap(read(io, Int32))
    if nattr > 0
      UA = Dict{String, String}()
      for i = 1:nattr
        k = read_ah_str(io)
        V = read_ah_str(io)
        UA[k] = V
      end
      v > 2 && println("UA = ", UA)
      merge!(C.misc, UA)
    end

    # Create C.t
    ti .= bswap.(ti)
    t0 =  y2μs(ti[1]) +
          (md2j(ti[1], ti[2], ti[3])-one(Int32))*86400000000 +
          Int64(ti[4])*3600000000 +
          Int64(ti[5])*60000000 +
          round(Int64, t_s*1.0e6)
    t = Array{Int64, 2}(undef, 2, 2)
    setindex!(t, one(Int64), 1)
    setindex!(t, nx, 2)
    setindex!(t, t0, 3)
    setindex!(t, zero(Int64), 4)
    setfield!(C, :t, t)

    # Set C.fs
    setfield!(C, :fs, 1.0/dt)

    # Data
    T = dtype == 1 ? Float32 : Float64
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
  return S
end

function read_ah1(ahfile::String;
  v::Int64=SeisIO.KW.v,
  full::Bool=false
  )

  S = SeisData()
  io = open(ahfile, "r")
  str = getfield(BUF, :sac_cv)
  ti = zeros(Int32, 5)

  while !eof(io)

    # Station header =========================================================
    sta = read_ah_str(io)
    cha = read_ah_str(io)
    net = read_ah_str(io)

    C = SeisChannel(id = mk_ah_id(net, sta, cha),
      loc = GeoLoc( "",
        Float64(bswap(read(io, Float32))),
        Float64(bswap(read(io, Float32))),
        Float64(bswap(read(io, Float32))),
        0.0, 0.0, 0.0),
      gain = Float64(bswap(read(io, Float32)))
      )
    (v > 2 ) && println("sta = ", String(sta), ", cha = ", String(cha), ", net = ", String(net))

    A0 = bswap(read(io, Float32))
    NP = round(Int32, bswap(read(io, Float32)))
    skip(io, 4)
    NZ = round(Int32, bswap(read(io, Float32)))
    skip(io, 4)
    P = Array{Complex{Float32},1}(undef, NP)
    Z = Array{Complex{Float32},1}(undef, NZ)
    NC = max(NP,NZ)
    j = 1
    for i = 1:29
      (i > NC) && break
      if i ≤ NP
        P[i] = complex(bswap(read(io, Float32)),bswap(read(io, Float32)))
      else
        skip(io, 8)
      end
      if i ≤ NZ
        Z[i] = complex(bswap(read(io, Float32)),bswap(read(io, Float32)))
      else
        skip(io, 8)
      end
      j += 1
    end
    skip(io, 16*(30-j))
    setfield!(C, :resp, PZResp(a0 = A0, p = P, z = Z))

    # Event header ==========================================================
    evlat = bswap(read(io, Float32))
    evlon = bswap(read(io, Float32))
    dep = bswap(read(io, Float32))
    read!(io, ti)
    t_s = read(io, Float32)
    read_comm!(io, str, full)
    if full
      C.misc["event_comment"] = unsafe_string(pointer(str))
      C.misc["ev_lat"] = evlat
      C.misc["ev_lon"] = evlon
      C.misc["ev_dep"] = dep
      ti = bswap.(ti)
      C.misc["ot"] =  u2d(Float64(div(y2μs(ti[1]), 1000000) +
                      (md2j(ti[1], ti[2], ti[3])-one(Int32))*86400 +
                      Int64(ti[4])*3600 + Int64(ti[5])*60) + t_s)
    end
    (v > 2) && println("ev_lat = ", evlat, ", ev_lon = ", evlon, ", dep = ", dep)

    # Data header ===========================================================
    dtype = bswap(read(io, Int32))
    nx    = bswap(read(io, UInt32))
    dt    = bswap(read(io, Float32))
    Amax  = bswap(read(io, Float32))
    read!(io, ti)
    t_s   = bswap(read(io, Float32))
    xmin  = bswap(read(io, Float32))
    read_comm!(io, str, full)
    if full
      C.misc["data_comment"] = unsafe_string(pointer(str))
      C.misc["Amax"] = Amax
      C.misc["xmin"] = xmin
    end
    (v > 2) && println("nx = ", nx, ", dt = ", dt, ", Amax = ", Amax)
    read_comm!(io, str, full)
    n = bswap(read(io, UInt32))
    if full
      # Log all processing to C.notes
      i = 0
      j = 1
      while j ≤ length(str)
        if str[j] == 0x00
          i = j
        elseif str[j] == 0x3b && j-i > 1
          note!(C, unsafe_string(pointer(str[i+1:j-1])) * ", recorded in .ah file log")
          i = j
        end
        j += 1
      end

      # "Extras"
      if n > 0
        C.misc["extras"] = bswap.(read!(io, zeros(Float32, n)))
      end
    else
      skip(io, 4*n)
    end

    # Create C.t
    ti .= bswap.(ti)
    t0 =  y2μs(ti[1]) +
          (md2j(ti[1], ti[2], ti[3])-one(Int32))*86400000000 +
          Int64(ti[4])*3600000000 +
          Int64(ti[5])*60000000 +
          round(Int64, t_s*1.0e6)
    t = Array{Int64, 2}(undef, 2, 2)
    setindex!(t, one(Int64), 1)
    setindex!(t, nx, 2)
    setindex!(t, t0, 3)
    # setindex!(t, t0 + round(Int64, Float64(dt)*1.0e6), 3)
    setindex!(t, zero(Int64), 4)
    setfield!(C, :t, t)

    # Set C.fs
    setfield!(C, :fs, 1.0/dt)

    # Data
    T = dtype == 1 ? Float32 : Float64
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
  return S
end
