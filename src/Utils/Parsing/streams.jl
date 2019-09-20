# purpose: read ASCII values from a stream
function parse_digits(io::IO, c::UInt8, N::UInt8)
  v = zero(UInt32)
  p = 0x00989680
  i = 0x00
  m = 0x00000001

  while is_u8_digit(c)
    eof(io) && break
    if i < N
      p = div(p, 0x0a)
      i += 0x01
      v += (c-0x30)*p
      m = p
    end
    c = read(io, UInt8)
  end
  skip(io, -1)
  return v, m
end

function stream_int(io::IO, L::Int64)
  p = 10^(L-1)
  n = zero(Int64)
  @inbounds for i = 1:L
    c = read(io, UInt8)
    if is_u8_digit(c)
      n += p*(c-0x30)
    end
    p = div(p, 10)
  end
  return n
end

function stream_float(io::IO, c::UInt8)
  read_state = 0x00
  zz = 0x00000000
  p0 = 0x00989680
  v = zz
  m = 0x00000001
  d = zz
  x = zz
  q = zz
  msgn = true
  esgn = true
  read_exp = false
  while true
    c = read(io, UInt8)
    if is_u8_digit(c)
      if read_exp
        x,q = parse_digits(io, c, 0x04)
      else
        v,m = parse_digits(io, c, 0x08)
      end

    # '-'
    elseif c == 0x2d
      if read_exp
        esgn = false
      else
        msgn = false
      end

    # '+'
    elseif c == 0x2b
      continue

    # '.'
    elseif c == 0x2e
      c = read(io, UInt8)
      d, u = parse_digits(io, c, 0x08)

    # 'E', 'F', 'e', 'f'
    elseif c in (0x45, 0x46, 0x65, 0x66)
      read_exp = true
      sgn = false

    else
      break
    end
  end
  v1 = Float32(div(v, m)) + Float32(d) / Float32(p0)
  if q > zz
    if esgn
      v3 = 10.0f0^Float32(div(x,q))
    else
      v3 = 10.0f0^(-1.0f0*Float32(div(x,q)))
    end
  else
    v3 = one(Float32)
  end
  if msgn
    return v1 * v3
  else
    return -v1 * v3
  end
end

function stream_time(io::IO, T::Array{Y,1}) where Y<:Integer
  fill!(T, zero(Y))
  i = mark(io)
  k = 1
  while true
    c = read(io, UInt8)

    if c in (0x2d, 0x2e, 0x3a, 0x54)
      L = position(io)-i-1
      reset(io)
      T[k] = stream_int(io, L)
      skip(io, 1)
      i = mark(io)
      k += 1

    # exit on any non-digit character except (',', '.', ':', 'T')
    elseif c < 0x30 || c > 0x39
      L = position(io)-i-1
      if L > 0
        reset(io)
        T[k] = stream_int(io, L)
        skip(io, 1)
      end
      break
    end
  end
  y = T[1]
  if T[2] == zero(Y)
    return y2μs(y[1])
  else
    j = md2j(y, T[2], T[3])
    return mktime(y, j, T[4], T[5], T[6], T[7])
  end
end
