# An order of magnitude faster than parse
function buf_to_uint(buf::Array{UInt8,1}, L::T) where T<:Integer
  o = one(UInt64)
  n = zero(UInt64)
  p = UInt64(L-o)
  i = zero(T)
  t = UInt64(10)
  while i < L
    i += one(T)
    n += UInt64(getindex(buf, i)-0x30)*t^p
    p -= o
  end
  return n
end

function buf_to_int(buf::Array{UInt8,1}, L::Int64)
  c = 10^(L-1)
  n = zero(Int64)
  for i = 1:L
    n += c*(buf[i]-0x30)
    c = div(c, 10)
  end
  return n
end

function buf_to_int(buf::Array{UInt8,1}, i::Int64, j::Int64)
  c = Int16(10)^Int16(i-j)
  n = zero(Int16)
  for p = j:i
    n += c * Int16(buf[p]-0x30)
    c = div(c, Int16(10))
  end
  return n
end

# Factor of two faster than parse(Float64, str) for a string
# Order of magnitude faster than parse(Float64, String[uu]) for a u8 array
function buf_to_double(buf::Array{UInt8,1}, L::Int64)
  read_state = 0x00
  mant_sgn = 1.0e0
  exp_sgn = 1.0e0

  j = one(Int64)
  zz = zero(Int64)
  z = zero(Int8)
  o = one(Int8)
  i = z
  imax = Int8(16)
  p0 = Int64(10)^Int64(imax)
  p = p0
  t = Int64(10)
  d = zz
  m = zz
  q = zz
  v = zz
  x = zz
  while j ≤ L
    c = buf[j]
    if read_state == 0x00
      if is_u8_digit(c) && (i < imax)
        p = div(p,t)
        i += o
        v += Int64(c-0x30)*p
        m = p
      elseif c == 0x2d # '-'
        mant_sgn = -1.0e0
      elseif c == 0x2b # '+'
        mant_sgn = 1.0e0
      elseif c == 0x2e # '.'
        # transition to state 1
        read_state = 0x01
        i = z
        p = p0
      elseif c in (0x45, 0x46, 0x65, 0x66) # 'E', 'F', 'e', 'f'
        # transition to state 2 (no decimal)
        read_state = 0x02
        i = z
        p = p0
      end
    elseif read_state == 0x01
      if is_u8_digit(c) && i < imax
        p = div(p,t)
        i += o
        d += Int64(c-0x30)*p
      elseif c in (0x45, 0x46, 0x65, 0x66)
        # transition to state 2
        read_state = 0x02
        i = z
        p = p0
      end
    else
      if is_u8_digit(c) && (i < imax)
        p = div(p,t)
        i += o
        x += Int64(c-0x30)*p
        q = p
      elseif c == 0x2d # '-'
        exp_sgn = -1.0e0
      elseif c == 0x2b # '+'
        exp_sgn = 1.0e0
      else
        break
      end
    end
    j += 1
  end
  v1 = Float64(div(v, m))
  v2 = Float64(d) / Float64(p0)
  if q > zz
    v3 = 10.0e0^(exp_sgn * Float64(div(x,q)))
  else
    v3 = one(Float64)
  end
  return mant_sgn * (v1 + v2) * v3
end
