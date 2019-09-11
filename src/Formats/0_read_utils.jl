is_u8_digit(u::UInt8) = u > 0x2f && u < 0x3a

function u8_to_int(buf::Array{UInt8,1}, L::Int64)
  c = 10^(L-1)
  n = zero(Int64)
  for i = 1:L
    n += c*(buf[i]-0x30)
    c = div(c, 10)
  end
  return n
end

function u8_to_int(buf::Array{UInt8,1}, i::Int64, j::Int64)
  c = Int16(10)^Int16(i-j)
  n = zero(Int16)
  for p = j:i
    n += c * Int16(buf[p]-0x30)
    c = div(c, Int16(10))
  end
  return n
end

# id = targ vector
# cv = char vector
# i = starting index in cv
# imax = max index in cv
# j = starting index in id
# jmax = max index in id
function fill_id!(id::Array{UInt8,1}, cv::Array{UInt8,1}, i::T, i_max::T, j::T, j_max::T) where T<:Integer
  o = one(T)
  while true
    c = getindex(cv, i)
    i = i+o
    i > i_max && break
    c < 0x2f && continue
    setindex!(id, c, j)
    j = j+o
    j > j_max && break
  end
  if j_max < T(15)
    id[j_max+1] = 0x2e
  end
  return i
end

function checkbuf!(buf::Array{UInt8,1}, nx::T1, T::Type) where T1<:Integer
  nb = Int64(nx)*sizeof(T)
  if lastindex(buf) > nb
    resize!(buf, nb)
  end
  return nb
end

function checkbuf!(buf::AbstractArray, nx::T) where {T<:Integer}
  if nx > lastindex(buf)
    resize!(buf, nx)
  end
end

function checkbuf_strict!(buf::AbstractArray, nx::T) where {T<:Integer}
  if nx != lastindex(buf)
    resize!(buf, nx)
  end
end

# ensures length(buf) is divisible by 8
function checkbuf_8!(buf::Array{UInt8,1}, n::Integer)
  if div(n, 8) == 0
    nx = n
  else
    nx = n + 8 - rem(n,8)
  end
  if nx > lastindex(buf)
    resize!(buf, nx)
  end
end

function fillx_i4!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y = getindex(buf, i)
    x[j] = Int32(y >> 4)
    if i < nx
      j += 1
      x[j] = Int32((y << 4) >> 4)
    end
  end
  return nothing
end

function fillx_i8!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    x[j] = signed(buf[i])
  end
  return nothing
end

function fillx_i16_le!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  y = zero(UInt16)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y  = UInt16(buf[2*i-1])
    y |= UInt16(buf[2*i]) << 8
    x[j] = signed(y)
  end
  return nothing
end

function fillx_i16_be!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  y = zero(UInt16)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y  = UInt16(buf[2*i-1]) << 8
    y |= UInt16(buf[2*i])
    x[j] = signed(y)
  end
  return nothing
end

function fillx_i24_be!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  y = zero(UInt32)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y  = UInt32(buf[3*i-2]) << 24
    y |= UInt32(buf[3*i-1]) << 16
    y |= UInt32(buf[3*i])   << 8
    x[j] = signed(y)        >> 8
  end
end

function fillx_i32_le!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  y = zero(UInt32)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y = UInt32(buf[4*i-3])
    y |= UInt32(buf[4*i-2]) << 8
    y |= UInt32(buf[4*i-1]) << 16
    y |= UInt32(buf[4*i])   << 24
    x[j] = signed(y)
  end
  return nothing
end

function fillx_i32_be!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  y = zero(UInt32)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y  = UInt32(buf[4*i-3]) << 24
    y |= UInt32(buf[4*i-2]) << 16
    y |= UInt32(buf[4*i-1]) << 8
    y |= UInt32(buf[4*i])
    x[j] = signed(y)
  end
  return nothing
end

function fillx_u32_be!(x::AbstractArray, buf::Array{UInt8,1}, nx::Integer, os::Int64)
  y = zero(UInt32)
  j = os
  i = 0
  while i < nx
    i += 1
    j += 1
    y  = UInt32(buf[4*i-3]) << 24
    y |= UInt32(buf[4*i-2]) << 16
    y |= UInt32(buf[4*i-1]) << 8
    y |= UInt32(buf[4*i])
    x[j] = y
  end
  return nothing
end

# An order of magnitude faster than parse
function mkuint(vi::Int8, v_buf::Array{UInt8,1})
  v_buf .-= 0x30
  o = one(UInt64)
  p = UInt64(vi-o)
  nx = zero(UInt64)
  i = zero(Int8)
  m = i
  t = UInt64(10)
  while i < vi
    i += one(Int8)
    nx += UInt64(getindex(v_buf, i))*t^p
    p -= o
  end
  return UInt64(nx)
end

# A factor of two faster than ccall(:strtof, Float32, (Cstring, Ptr), Cstring(ptr), C_NULL)
# even with ptr being a pointer to a predefined array
function mkfloat(io::IO, c::UInt8)
  read_state = 0x00
  mant_sgn = 1.0f0
  exp_sgn = 1.0f0

  while c == 0x20
    c = read(io, UInt8)
  end

  zz = zero(Int32)
  z = zero(Int8)
  o = one(Int8)
  i = z
  imax = Int8(8)
  p0 = Int32(10)^Int32(imax)
  p = p0
  t = Int32(10)
  d = zz
  m = zz
  q = zz
  v = zz
  x = zz
  while c != 0x0a
    if read_state == 0x00
      if is_u8_digit(c) && i < imax
        p = div(p,t)
        i += o
        v += Int32(c-0x30)*p
        m = p
      elseif c == 0x2d
        mant_sgn = -1.0f0
      elseif c == 0x2b
        mant_sgn = 1.0f0
      elseif c == 0x2e
        # transition to state 1
        read_state = 0x01
        i = z
        p = p0
      elseif c == 0x65 || c == 0x66 || c == 0x65 || c == 0x65
        # transition to state 2 (no decimal)
        read_state = 0x02
        i = z
        p = p0
      end
    elseif read_state == 0x01
      if is_u8_digit(c) && i < imax
        p = div(p,t)
        i += o
        d += Int32(c-0x30)*p

      elseif c == 0x65 || c == 0x66 || c == 0x65 || c == 0x65
        # transition to state 2
        read_state = 0x02
        i = z
        p = p0
      end
    else
      if is_u8_digit(c) && i < imax
        p = div(p,t)
        i += o
        x += Int32(c-0x30)*p
        q = p
      elseif c == 0x2d
        exp_sgn = -1.0f0
      elseif c == 0x2b
        exp_sgn = 1.0f0
      end
    end
    c = read(io, UInt8)
  end
  v1 = Float32(div(v, m))
  v2 = Float32(d) / Float32(p0)
  if q > zz
    v3 = 10.0f0^(exp_sgn * Float32(div(x,q)))
  else
    v3 = one(Float32)
  end
  return mant_sgn * (v1 + v2) * v3
end

# Factor of two faster than parse(Float64, str) for a string
# Order of magnitude faster than parse(Float64, String[uu]) for a u8 array
function mkdbl(buf::Array{UInt8,1}, L::Int64)
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
