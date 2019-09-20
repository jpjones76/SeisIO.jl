is_u8_digit(u::UInt8) = u > 0x2f && u < 0x3a

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

# ensures length(buf) is divisible by 8...needed to reinterpret as 64-bit type
function checkbuf_8!(buf::Array{UInt8,1}, n::Integer)
  if div(n, 8) == 0
    nx = n
  else
    nx = n + 8 - rem(n,8)
  end
  L = length(buf)
  if nx > L
    resize!(buf, nx)
  else
    r = rem(L, 8)
    if r > 0
      resize!(buf, L + 8 - r)
    end
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
