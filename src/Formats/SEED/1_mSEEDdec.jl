# Home of SEED data decoders
function unpack!(S::SeedVol)
  @inbounds for m = 0x01:0x01:S.u8[3]
    S.k += 1
    setindex!(S.x, >>(signed(<<(S.u[1], S.u8[1])), 0x20-S.u8[2]), S.k)
    S.u8[1] += S.u8[2]
  end
end

SEED_Char(io::IO) = replace(String(read(io, SEED.nx-SEED.u16[4], all=false)), ['\r', '\0'] =>"")

function SEED_Unenc(io::IO)
  T::Type = if SEED.fmt == 0x01
      Int16
    elseif SEED.fmt == 0x03
      Int32
    elseif SEED.fmt == 0x04
      Float32
    elseif SEED.fmt == 0x05
      Float64
    end
  nv = div(SEED.nx - SEED.u16[4], sizeof(T))
  for i = 1:nv
    SEED.x[i] = Float64(SEED.swap ? ntoh(read(io, T)) : read(io, T))
  end
  SEED.k = nv
  return nothing
end

function SEED_Geoscope(io::IO)
  mm = 0x0fff
  gm = SEED.fmt == 0x0d ? 0x7000 : 0xf000
  for i = 0x0001:SEED.n
    x = SEED.swap ? ntoh(read(io, UInt16)) : read(io, UInt16)
    m = Int32(x & mm)
    g = Int32((x & gm) >> 12)
    ex = -1*g
    setindex!(SEED.x, ldexp(Float64(m-2048), ex), i)
  end
  SEED.k = SEED.n
  return nothing
end

function SEED_CDSN(io::IO)
  for i = 0x0001:SEED.n
    x = SEED.swap ? ntoh(read(io, UInt16)) : read(io, UInt16)
    m = Int32(x & 0x3fff)
    g = Int32((x & 0xc000) >> 14)
    if (g == 0)
      mult = 1
    elseif g == 1
      mult = 4
    elseif g == 2
      mult = 16
    elseif g == 3
      mult = 128
    end
    m -= 0x1fff
    setindex!(SEED.x, m*mult, i)
  end
  SEED.k = SEED.n
  return nothing
end

function SEED_SRO(io::IO)
  for i = 0x0001:SEED.n
    x = SEED.swap ? ntoh(read(io, UInt16)) : read(io, UInt16)
    m = Int32(x & 0x0fff)
    g = Int32((x & 0xf000) >> 12)
    if m > 0x07ff
      m -= 0x1000
    end
    ex = -1*g + 10
    setindex!(SEED.x, ldexp(Float64(m), ex), i)
  end
  SEED.k = SEED.n
  return nothing
end

function SEED_DWWSSN(io::IO)
  for i = 0x0001:SEED.n
    x = signed(UInt32(SEED.swap ? ntoh(read(io, UInt16)) : read(io, UInt16)))
    SEED.x[i] = x > 32767 ? x - 65536 : x
  end
  SEED.k = SEED.n
  return nothing
end

# Steim1 or Steim2
function SEED_Steim(io::IO)
  nf = div(SEED.nx-SEED.u16[4], 0x0040)
  SEED.k = 0
  @inbounds for i = 1:nf
    for j = 1:16
      SEED.u[1] = SEED.xs ? ntoh(read(io, UInt32)) : read(io, UInt32)
      if j == 1
        SEED.u[2] = copy(SEED.u[1])
      end
      SEED.u[3] = (SEED.u[2] >> SEED.steimvals[j]) & 0x00000003
      if SEED.u[3] == 0x00000001
        SEED.u8[1] = 0x00
        SEED.u8[2] = 0x08
        SEED.u8[3] = 0x04
      elseif SEED.fmt == 0x0a
        SEED.u8[1] = 0x00
        if SEED.u[3] == 0x00000002
          SEED.u8[2] = 0x10
          SEED.u8[3] = 0x02
        elseif SEED.u[3] == 0x00000003
          SEED.u8[2] = 0x20
          SEED.u8[3] = 0x01
        end
      else
        dd = SEED.u[1] >> 0x0000001e
        if SEED.u[3] == 0x00000002
          SEED.u8[1] = 0x02
          if dd == 0x00000001
            SEED.u8[2] = 0x1e
            SEED.u8[3] = 0x01
          elseif dd == 0x00000002
            SEED.u8[2] = 0x0f
            SEED.u8[3] = 0x02
          elseif dd == 0x00000003
            SEED.u8[2] = 0x0a
            SEED.u8[3] = 0x03
          end
        elseif SEED.u[3] == 0x00000003
          if dd == 0x00000000
            SEED.u8[1] = 0x02
            SEED.u8[2] = 0x06
            SEED.u8[3] = 0x05
          elseif dd == 0x00000001
            SEED.u8[1] = 0x02
            SEED.u8[2] = 0x05
            SEED.u8[3] = 0x06
          else
            SEED.u8[1] = 0x04
            SEED.u8[2] = 0x04
            SEED.u8[3] = 0x07
          end
        end
      end
      if SEED.u[3] != 0x00000000
        unpack!(SEED)
      end
      if i == 1
        if j == 2
          SEED.x0 = Float64(signed(SEED.u[1]))
        elseif j == 3
          SEED.xn = Float64(signed(SEED.u[1]))
        end
      end
    end
  end

  n = SEED.k
  if SEED.wo != 0x01
    SEED.x[1:n] = reverse(SEED.x[1:n])
  end
  SEED.x[1] = SEED.x0

  # Cumsum by hand
  xa = SEED.x0
  @inbounds for i = 2:n
    xa += SEED.x[i]
    SEED.x[i] = xa
  end

  # Check data values
  if abs(SEED.x[n] - SEED.xn) > eps()
    println(stdout, string("RDMSEED: data integrity -- Steim-", SEED.fmt - 0x09, " sequence #", String(SEED.hdr[1:6]), " integrity check failed, last_data=", SEED.x[n], ", should be xn=", SEED.xn))
  end
  return nothing
end

function SEED_DecErr(io::IO)
  error(string("No decoder for data format ", SEED.fmt, "!"))
end
