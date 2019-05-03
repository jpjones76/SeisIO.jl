SEED_Char(io::IO, BUF::SeisIOBuf, nb::UInt16) = replace(String(read(io, nb, all=false)),
                                            ['\r', '\0'] =>"")

# This gets special handling as Float64 arrays are assumed in S.x[c]
function SEED_Float64!(io::IO, S::SeisData, c::Int64, xi::Int64, nb::UInt16)
  buf = getfield(BUF, :buf)
  x = getindex(getfield(S, :x), c)
  readbytes!(io, buf, nb)
  nx = div(nb, 8)
  if getfield(BUF, :xs) == true
    j = xi
    @inbounds for i = 1:nx
      j += 1
      y  = UInt32(buf[8*i-7]) << 56
      y |= UInt32(buf[8*i-6]) << 48
      y |= UInt32(buf[8*i-5]) << 40
      y |= UInt32(buf[8*i-4]) << 32
      y |= UInt32(buf[8*i-3]) << 24
      y |= UInt32(buf[8*i-2]) << 16
      y |= UInt32(buf[8*i-1]) << 8
      y |= UInt32(buf[8*i])
      x[j] = y
    end
  else
    xr = reinterpret(Float64, buf)
    copyto!(x, xi+1, xr, 1, nx)
  end
  setfield!(BUF, :k, Int64(nx))
  return nothing
end

function SEED_Unenc!(io::IO, S::SeisData, c::Int64, xi::Int64, nb::UInt16)
  buf = getfield(BUF, :buf)
  x = getindex(getfield(S, :x), c)
  readbytes!(io, buf, nb)
  T::Type = if BUF.fmt == 0x01
      Int16
    elseif BUF.fmt == 0x03
      Int32
    elseif BUF.fmt == 0x04
      Float32
    end
  if getfield(BUF, :swap) == true
    xr = bswap.(reinterpret(T, buf))
  else
    xr = reinterpret(T, buf)
  end
  nx = div(nb, sizeof(T))
  copyto!(x, xi+1, xr, 1, nx)
  setfield!(BUF, :k, Int64(nx))
  return nothing
end

function SEED_Geoscope!(io::IO, BUF::SeisIOBuf)
  mm = 0x0fff
  gm = BUF.fmt == 0x0d ? 0x7000 : 0xf000
  for i = 0x0001:BUF.n
    x = BUF.swap ? bswap(read(io, UInt16)) : read(io, UInt16)
    m = Int32(x & mm)
    g = Int32((x & gm) >> 12)
    ex = -1*g
    setindex!(BUF.x, ldexp(Float64(m-2048), ex), i)
  end
  BUF.k = BUF.n
  return nothing
end

function SEED_CDSN!(io::IO, BUF::SeisIOBuf)
  for i = 0x0001:BUF.n
    x = BUF.swap ? bswap(read(io, UInt16)) : read(io, UInt16)
    m = Int32(x & 0x3fff)
    g = Int32((x & 0xc000) >> 14)
    mult = 4^g * g==3 ? 2 : 1
    m -= 0x1fff
    setindex!(BUF.x, m*mult, i)
  end
  BUF.k = BUF.n
  return nothing
end

function SEED_SRO!(io::IO, BUF::SeisIOBuf)
  for i = 0x0001:BUF.n
    x = BUF.swap ? bswap(read(io, UInt16)) : read(io, UInt16)
    m = Int32(x & 0x0fff)
    g = Int32((x & 0xf000) >> 12)
    if m > 0x07ff
      m -= 0x1000
    end
    ex = -1*g + 10
    setindex!(BUF.x, ldexp(Float64(m), ex), i)
  end
  BUF.k = BUF.n
  return nothing
end

function SEED_DWWSSN!(io::IO, BUF::SeisIOBuf)
  for i = 0x0001:BUF.n
    x = signed(UInt32(BUF.swap ? bswap(read(io, UInt16)) : read(io, UInt16)))
    BUF.x[i] = x > 32767 ? x - 65536 : x
  end
  BUF.k = BUF.n
  return nothing
end

# Steim1 or Steim2
function SEED_Steim!(io::IO, BUF::SeisIOBuf, nb::UInt16)
  x = getfield(BUF, :x)
  buf = getfield(BUF, :buf)
  ff = getfield(BUF, :x32)
  nc = Int64(div(nb, 0x0040))
  ni = div(nb, 0x0004)
  readbytes!(io, buf, nb)

  # Parse buf as UInt32s
  if ni > lastindex(ff)
    resize!(ff, ni)
  end
  yy = zero(UInt32)
  if getfield(BUF, :xs) == true
    @inbounds for ib = 1:ni
      yy  = UInt32(buf[4*ib-3]) << 24
      yy |= UInt32(buf[4*ib-2]) << 16
      yy |= UInt32(buf[4*ib-1]) << 8
      yy |= UInt32(buf[4*ib])
      ff[ib] = yy
    end
  else
    @inbounds for il = 1:ni
      yy  = UInt32(buf[4*il]) << 24
      yy |= UInt32(buf[4*il-1]) << 16
      yy |= UInt32(buf[4*il-2]) << 8
      yy |= UInt32(buf[4*il-3])
      ff[il] = yy
    end
  end

  k = zero(Int64)
  x0 = zero(Float32)
  xn = zero(Float32)
  a = zero(UInt8)
  b = zero(UInt8)
  c = zero(UInt8)
  d = zero(UInt8)
  fq = zero(Float32)
  m = zero(UInt8)
  p = zero(UInt32)
  q = zero(Int32)
  u = zero(UInt32)
  y = zero(UInt32)
  z = zero(UInt32)
  χ = zero(UInt32)
  r = zero(Int64)
  for i = 1:nc
    z = getindex(ff, 1+r)
    for j = 1:16
      χ = getindex(ff, j+r)
      y = (z >> steim[j]) & 0x00000003
      if y == 0x00000001
        a = 0x00
        b = 0x08
        c = 0x04
      elseif BUF.fmt == 0x0a
        a = 0x00
        if y == 0x00000002
          b = 0x10
          c = 0x02
        elseif y == 0x00000003
          b = 0x20
          c = 0x01
        end
      else
        p = χ >> 0x0000001e
        if y == 0x00000002
          a = 0x02
          if p == 0x00000001
            b = 0x1e
            c = 0x01
          elseif p == 0x00000002
            b = 0x0f
            c = 0x02
          elseif p == 0x00000003
            b = 0x0a
            c = 0x03
          end
        elseif y == 0x00000003
          if p == 0x00000000
            a = 0x02
            b = 0x06
            c = 0x05
          elseif p == 0x00000001
            a = 0x02
            b = 0x05
            c = 0x06
          else
            a = 0x04
            b = 0x04
            c = 0x07
          end
        end
      end
      if y != 0x00000000
        u = χ << a
        m = zero(UInt8)
        d = 0x20 - b
        while m < c
          k = k + 1
          q = signed(u)
          q >>= d
          fq = Float32(q)
          setindex!(x, fq, k)
          m = m + 0x01
          u <<= b
        end
      end
      if i == 1
        if j == 2
          x0 = Float32(signed(χ))
        elseif j == 3
          xn = Float32(signed(χ))
        end
      end
    end
    r = r+16
  end

  if BUF.wo != 0x01
    vx = view(getfield(BUF, :x), 1:k)
    reverse!(vx)
  end
  setindex!(x, x0, 1)

  # Cumsum by hand
  xa = copy(x0)
  @inbounds for i1 = 2:k
    xa = xa + getindex(x, i1)
    setindex!(x, xa, i1)
  end

  # Check data values
  if isapprox(getindex(x, k), xn) == false
    println(stdout, string("RDMSEED: data integrity -- Steim-",
                            getfield(BUF, :fmt) - 0x09, " sequence #",
                            String(copy(getfield(BUF, :seq))),
                            " integrity check failed, last_data=",
                            getindex(getfield(BUF, :x), k),
                            ", should be xn=", xn))
  end
  setfield!(BUF, :k, k)
  return nothing
end
