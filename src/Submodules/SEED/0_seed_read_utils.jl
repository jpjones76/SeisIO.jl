
function store_int!(X::Array{Int64,1}, buf::Array{UInt8,1}, i::Int64, n::Int64)
  n == 0 && return
  nx = length(X)
  if n > 0
    if n > nx
      append!(X, zeros(Int64, n-nx))
    end
    X[n] = u8_to_int(buf, i)
  end
  return nothing
end

function store_dbl!(X::Array{Float64,1}, buf::Array{UInt8,1}, i::Int64, n::Int64)
  n == 0 && return
  nx = length(X)
  if n > 0
    if n > nx
      append!(X, zeros(Float64, n-nx))
    end
    X[n] = mkdbl(buf, i)
  end
  return nothing
end

function get_coeff_n(io::IO, c::UInt8, buf::Array{UInt8,1})
  i = 1
  while c != 0x20
    buf[i] = c
    i += 1
    c = read(io, UInt8)
  end
  return u8_to_int(buf, i-1)+1
end


function to_newline(io::IO, c::UInt8)
  while c != 0x0a
    c = read(io, UInt8)
  end
  return c
end

function skip_whitespace(io::IO, c::UInt8)
  c = read(io, UInt8)
  while c == 0x20
    c = read(io, UInt8)
  end
  return c
end

function parse_resp_date(io::IO, T::Array{UInt16,1})
  fill!(T, zero(UInt16))
  i = mark(io)
  k = 1
  while true
    c = read(io, UInt8)
    if c in (0x2c, 0x2e, 0x3a)
      L = position(io)-i-1
      reset(io)
      T[k] = string_int(io, L)
      skip(io, 1)
      i = mark(io)
      k += 1
    elseif c == 0x7e
      L = position(io)-i-1
      if L > 0
        reset(io)
        T[k] = string_int(io, L)
        skip(io, 1)
      end
      break
    end
  end
  return mktime(T)
end

function string_int(io::IO, L::Int64)
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

function string_field(sio::IO)
  m = mark(sio)
  c = read(sio, UInt8)
  while c != 0x7e
    c = read(sio, UInt8)
  end
  p = position(sio)-m
  reset(sio)
  return String(read(sio, p))[1:p-1]
end

function skip_string!(sio::IO)
  c = read(sio, UInt8)
  while c != 0x7e
    c = read(sio, UInt8)
  end
  return nothing
end

function blk_string_read(io::IO, nb::Int64, v::Int64)
  checkbuf!(BUF.buf, nb)
  if nb + BUF.k > 4096
    part1 = 4096-BUF.k
    readbytes!(io, BUF.buf, part1)
    read!(io, BUF.seq)
    nb -= part1
    while nb > 4088
      bv = pointer(BUF.buf, part1+1)
      unsafe_read(io, bv, 4088)
      read!(io, BUF.seq)
      part1 += 4088
      nb -= 4088
    end
    bv = pointer(BUF.buf, part1+1)
    unsafe_read(io, bv, nb)
    BUF.k = 8+nb
  else
    readbytes!(io, BUF.buf, nb)
    BUF.k += nb
  end
  sio = IOBuffer(BUF.buf)
  return sio
end
