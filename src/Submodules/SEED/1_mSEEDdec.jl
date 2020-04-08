SEED_Char(io::IO, BUF::SeisIOBuf, nb::UInt16) = replace(String(fastread(io, nb)),
                                            ['\r', '\0'] =>"")

function SEED_Unenc!(io::IO, S::GphysData, c::Int64, xi::Int64, nb::UInt16, nx::UInt16)
  buf = getfield(BUF, :buf)
  checkbuf_8!(buf, xi)
  x = getindex(getfield(S, :x), c)
  fast_readbytes!(io, buf, nb)
  T::Type = (if BUF.fmt == 0x01
      Int16
    elseif BUF.fmt == 0x03
      Int32
    elseif BUF.fmt == 0x04
      Float32
    else
      Float64
    end)
  xr = reinterpret(T, buf)
  if BUF.swap
    x[xi+1:xi+nx] .= bswap.(xr[1:nx])
  else
    copyto!(x, xi+1, xr, 1, nx)
  end
  setfield!(BUF, :k, Int64(nx))
  return nothing
end

function SEED_Geoscope!(io::IO, BUF::SeisIOBuf)
  mm = 0x0fff
  gm = BUF.fmt == 0x0d ? 0x7000 : 0xf000
  for i = 0x0001:BUF.n
    x = BUF.swap ? bswap(fastread(io, UInt16)) : fastread(io, UInt16)
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
    x = BUF.swap ? bswap(fastread(io, UInt16)) : fastread(io, UInt16)
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
    x = BUF.swap ? bswap(fastread(io, UInt16)) : fastread(io, UInt16)
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
    x = signed(UInt32(BUF.swap ? bswap(fastread(io, UInt16)) : fastread(io, UInt16)))
    BUF.x[i] = x > 32767 ? x - 65536 : x
  end
  BUF.k = BUF.n
  return nothing
end

# Steim1 or Steim2
function SEED_Steim!(io::IO, BUF::SeisIOBuf, nb::UInt16)
  x = getfield(BUF, :x)
  buf = getfield(BUF, :buf)
  ff = getfield(BUF, :uint32_buf)
  nc = Int64(div(nb, 0x0040))
  ni = div(nb, 0x0004)
  fast_readbytes!(io, buf, nb)
  (ni > lastindex(ff)) && resize!(ff, ni)
  fillx_u32_be!(ff, buf, ni, 0)
  k = zero(Int64)       # number of values read
  x0 = zero(Float32)    # first data value
  xn = zero(Float32)    # last data value
  a = zero(UInt8)       # byte offset to first data in each UInt32
  b = zero(UInt8)       # number of reads in each UInt32
  c = zero(UInt8)       # length (in bits) of each read in each UInt32
  d = zero(UInt8)       # amount of right bitshift
  fq = zero(Float32)    # Float32 data placeholder
  m = zero(UInt8)       # counter to reads in each UInt32
  dnib = zero(UInt8)    # dnib; two-bit secondary encoding flag
  q = zero(Int32)       # Int32 data placeholder
  u = zero(UInt32)      # placeholder for bit-shifted UInt32
  ck = zero(UInt8)      # two-bit primary encoding flag
  z = zero(UInt32)      # UInt32 containing nibbles
  χ = zero(UInt32)      # packed UInt32
  r = zero(Int64)       # "row" index to "matrix" of UInt32s
  for i = 1:nc
    z = getindex(ff, 1+r)
    for j = 1:16
      χ = getindex(ff, j+r)
      ck = UInt8((z >> steim[j]) & 0x03)

      # Steim1 and Steim2 are the same here
      if ck == 0x01
        a = 0x00
        b = 0x08
        c = 0x04

      # Steim1 for ck > 0x01
      elseif BUF.fmt == 0x0a
        a = 0x00
        if ck == 0x02
          b = 0x10
          c = 0x02
        elseif ck == 0x03
          b = 0x20
          c = 0x01
        end

      # Steim2
      else
        dnib = UInt8(χ >> 0x0000001e)
        if ck == 0x02
          a = 0x02
          if dnib == 0x01
            b = 0x1e
            c = 0x01
          elseif dnib == 0x02
            b = 0x0f
            c = 0x02
          elseif dnib == 0x03
            b = 0x0a
            c = 0x03
          end
        elseif ck == 0x03
          if dnib == 0x00
            a = 0x02
            b = 0x06
            c = 0x05
          elseif dnib == 0x01
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
      if ck != 0x00
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

  # Cumsum by hand
  setindex!(x, x0, 1)
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
