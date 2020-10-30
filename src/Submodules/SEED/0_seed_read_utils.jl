
function store_int!(X::Array{Int64,1}, buf::Array{UInt8,1}, i::Int64, n::Int64)
  n == 0 && return
  nx = length(X)
  if n > 0
    (n > nx) && append!(X, zeros(Int64, n-nx))
    X[n] = buf_to_int(buf, i)
  end
  return nothing
end

function store_dbl!(X::Array{Float64,1}, buf::Array{UInt8,1}, i::Int64, n::Int64)
  n == 0 && return
  nx = length(X)
  if n > 0
    (n > nx) && append!(X, zeros(Float64, n-nx))
    X[n] = buf_to_double(buf, i)
  end
  return nothing
end

function get_coeff_n(io::IO, c::UInt8, buf::Array{UInt8,1})
  i = 1
  while c != 0x20
    buf[i] = c
    i += 1
    c = fastread(io)
  end
  return buf_to_int(buf, i-1)+1
end


function to_newline(io::IO, c::UInt8)
  while c != 0x0a
    c = fastread(io)
  end
  return c
end

function skip_whitespace(io::IO, c::UInt8)
  c = fastread(io)
  while c == 0x20
    c = fastread(io)
  end
  return c
end

function parse_resp_date(io::IO, T::Array{UInt16,1})
  fill!(T, zero(UInt16))
  i = mark(io)
  k = 1
  while true
    c = fastread(io)
    if c in (0x2c, 0x2e, 0x3a)
      L = fastpos(io)-i-1
      reset(io)
      T[k] = stream_int(io, L)
      fastskip(io, 1)
      i = mark(io)
      k += 1
    elseif c == 0x7e
      L = fastpos(io)-i-1
      if L > 0
        reset(io)
        T[k] = stream_int(io, L)
        fastskip(io, 1)
      end
      break
    end
  end
  return mktime(T)
end

function string_field(sio::IO)
  m = mark(sio)
  c = fastread(sio)
  while c != 0x7e
    c = fastread(sio)
  end
  p = fastpos(sio)-m
  reset(sio)
  return String(fastread(sio, p))[1:p-1]
end

function skip_string!(sio::IO)
  c = fastread(sio)
  while c != 0x7e
    c = fastread(sio)
  end
  return nothing
end

function blk_string_read(io::IO, nb::Int64, v::Integer)
  checkbuf!(BUF.buf, nb)
  if nb + BUF.k > 4096
    part1 = 4096-BUF.k
    fast_readbytes!(io, BUF.buf, part1)
    fastread!(io, BUF.seq)
    nb -= part1
    while nb > 4088
      bv = pointer(BUF.buf, part1+1)
      fast_unsafe_read(io, bv, 4088)
      fastread!(io, BUF.seq)
      part1 += 4088
      nb -= 4088
    end
    bv = pointer(BUF.buf, part1+1)
    fast_unsafe_read(io, bv, nb)
    BUF.k = 8+nb
  else
    fast_readbytes!(io, BUF.buf, nb)
    BUF.k += nb
  end
  sio = IOBuffer(BUF.buf)
  return sio
end

seed_time(u16::Array{UInt16, 1}, hh::UInt8, mm::UInt8, ss::UInt8, δt::Int64) =
  y2μs(u16[1]) + Int64(u16[2] - one(UInt16))*86400000000 + Int64(u16[3])*100 +
  Int64(hh)*3600000000 + Int64(mm)*60000000 + Int64(ss)*1000000 + δt
