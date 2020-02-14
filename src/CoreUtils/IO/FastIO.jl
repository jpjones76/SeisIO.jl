module FastIO
const FastReadInt = Union{Type{Int16}, Type{UInt16}, Type{Int32}, Type{UInt32}, Type{Int64}, Type{UInt64}}
const FastReads   = Union{FastReadInt, Type{Float16}, Type{Float32}, Type{Float64}}

#=TO DO:
fastread Char
IBM-Float
=#

# =====================================================================
#=
  This section: file position commands

  No rewrite needed in 1.3: mark, reset, seekstart
=#

# fastpos
fastpos(io::Base.GenericIOBuffer) = io.ptr-1
fastpos(io::IOStream) = ccall(:ios_pos, Int64, (Ptr{Cvoid},), io.ios)

# fasteof
fasteof(io::Base.GenericIOBuffer) = (io.ptr-1 == io.size)
fasteof(io::IOStream) = Bool(ccall(:ios_eof_blocking, Cint, (Ptr{Cvoid},), io.ios))

# fastseek
function fastseek(io::Base.GenericIOBuffer, p::Integer)
  p -= 1
  (p < 0) && throw(ArgumentError("Attempted to seek outside IOBuffer boundaries."))
  (p-1 > io.size) && throw(ArgumentError("Attempted to seek outside IOBuffer boundaries."))
  io.ptr = p
  return nothing
end
function fastseek(io::IOStream, n::Integer)
  ccall(:ios_seek, Int64, (Ptr{Cvoid}, Int64), io.ios, n)
  return nothing
end

# fastskip
fastskip(io::Base.GenericIOBuffer, n::Integer) = skip(io, n)
function fastskip(io::IOStream, n::Integer)
  ccall(:ios_skip, Int64, (Ptr{Cvoid}, Int64), io.ios, n)
  return nothing
end

# fastseekend
fastseekend(io::Base.GenericIOBuffer) = (io.ptr = io.size+1)
fastseekend(io::IOStream) = ccall(:ios_seek_end, Int64, (Ptr{Cvoid},), io.ios)

# =====================================================================
#= This section: file read commands

fastread(io) returns a UInt8
fastread(io, T) returns a T
fastread_i32(io::IO, N::Integer; b::Bool=false) reads an N-byte Integer to Int32.
fastread_iN(io): read N bits to Int32 (for N ≤ 32) or Int64; defined for N = 8, 16, 24
fastread_fN(io): return 32-bit float converted from an n-bit float. Defined for N = 16, 64.
fastread_i64(io::IO, N::Integer; b::Bool=false) reads an N-byte Integer to Int64.

=#
fastread!(io::IO, buf::Array{T}) where T = read!(io, buf)
fastread!(io::IOStream, buf::Array{T}) where T = @GC.preserve buf ccall(:ios_readall, Csize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), io, pointer(buf), sizeof(buf))
# fastread!(io::IOStream, buf::Array{UInt8,1}) = ccall(:ios_readall, Csize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), io.ios, pointer(buf, 1), sizeof(buf))

# fastread
fastread(io::Base.GenericIOBuffer) = read(io, UInt8)
fastread(io::Base.GenericIOBuffer, T::FastReadInt) = read(io, T)
fastread(io::Base.GenericIOBuffer, T::Union{Type{Float32}, Type{Float64}}) = read(io, T)
fastread(io::Base.GenericIOBuffer, n::Integer) = read(io, n)

# IOStream methods avoid locking in 1.3
fastread(io::IOStream) = ccall(:ios_getc, Cint, (Ptr{Cvoid},), io.ios) % UInt8
function fastread(io::IOStream, n::Integer)
  buf = Vector{UInt8}(undef, n)
  ccall(:ios_readall, Csize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), io.ios, pointer(buf, 1), n)
  return buf
end

# Working solution 2020-02-10T16:00:00
function fastread(io::IOStream, T::FastReadInt)
  if VERSION > v"1.2.0"
    # ccall(:ios_flush, Cint, (Ptr{Cvoid},), io.ios)
    ccall(:ios_readprep, UInt64, (Ptr{Cvoid}, Csize_t), io.ios, sizeof(T))
  end
  return (ccall(:jl_ios_get_nbyte_int, UInt64, (Ptr{Cvoid}, Csize_t), io.ios, sizeof(T)) % T)
end
#= I *don't* like this. jl_ios_get_nbyte_int seems more likely to change than
   ios_getc, and version-dependent "if" loop is undesirable =#

# function fastread1(io::IOStream, ::Type{Int16})
#   ccall(:ios_flush, Cint, (Ptr{Cvoid},), io.ios)
#   x  = ccall(:ios_getc, Cint, (Ptr{Cvoid},), io.ios) | (ccall(:ios_getc, Cint, (Ptr{Cvoid},), io.ios) << 0x08)
#   return signed(x % UInt16)
# end
#
fastread(io::IO, ::Type{Bool})    = fastread(io) % Bool
fastread(io::IO, ::Type{UInt8})   = fastread(io)
fastread(io::IO, ::Type{Int8})    = signed(fastread(io))
fastread(io::IO, ::Type{Float16}) = Base.reinterpret(Float16, fastread(io, Int16))
fastread(io::IO, ::Type{Float32}) = Base.reinterpret(Float32, fastread(io, Int32))
fastread(io::IO, ::Type{Float64}) = Base.reinterpret(Float64, fastread(io, Int64))

"""
    fastread_i32(io, n::Integer; b::Bool=false, s::Bool=true)

Read an `n`-byte integer from `io` into an Int32 (s=true) or UInt32 (s=false). Specify `b=true` for big-Endian byte order.

Useful for things like Int24. Maybe faster than bswap(fastread(io, Int32)); in testing.

    fastread_i64(io, n::Integer; b::Bool=false, s::Bool=true)

Read an `n`-byte integer from `io` into an Int64 (s=true) or UInt64 (s=false). Specify `b=true` for big-Endian byte order.
"""
function fastread_i32(io::IO, n::Integer; b::Bool=false)
  x = UInt32(fastread(io))
  if b
    N = 0x08*(UInt8(n)-0x01)
    x <<= N
    for i in 2:n
      N -= 0x08
      x |= UInt32(fastread(io)) << N
    end
  else
    N = 0x08
    for i in 2:n
      x |= UInt32(fastread(io)) << N
      N += 0x08
    end
  end
  return signed(x)
end
fastread_i8(io::IO) = fastread(io) % Int32
fastread_i16(io::IO; b::Bool=false) = fastread_i32(io, 2, b=b)
fastread_i24(io::IO; b::Bool=false) = fastread_i32(io, 3, b=b)
fastread_i32(io::IO; b::Bool=false) = fastread_i32(io, 4, b=b)
fastread_f16(io::IO; b::Bool=false) = Float32(fastread(io, Float16))
fastread_f32(io::IO; b::Bool=false) = fastread(io, Float32)
fastread_f64(io::IOStream; b::Bool=false) = Float32(fastread(io, Float64))
function fastread_i64(io::IOStream, n::Integer; b::Bool=false, s::Bool=true)
  x = UInt64(fastread(io))
  if b
    N = 0x08*(UInt8(n)-0x01)
    x <<= N
    for i in 2:n
      N -= 0x08
      x |= UInt64(fastread(io)) << N
    end
  else
    N = 0x08
    for i in 2:n
      x |= UInt64(fastread(io)) << N
      N += 0x08
    end
  end
  return s ? signed(x) : x
end

# use if creating a new array during the call; I have yet to read anything but a 1d array in any format
function fastread(io::IO, T::Type, n::Integer)
  a = Array{T, 1}(undef, n)
  fastread!(io, a)
  return a
end

# TO DO
fastread(io::IO, ::Type{Char}) = read(io, Char)

# =====================================================================
# fast_readbytes!
fast_readbytes!(io::IO, buf::Array{UInt8,1}, nb::Integer) = readbytes!(io, buf, nb)
function fast_readbytes!(io::IOStream, buf::Array{UInt8,1}, nb::Integer)
    olb = lb = length(buf)
    nr = 0
    GC.@preserve buf while nr < nb
        if lb < nr+1
            lb = max(65536, (nr+1) * 2)
            resize!(buf, lb)
        end
        nr += Int(ccall(:ios_readall, Csize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),
                        io.ios, pointer(buf, nr+1), min(lb-nr, nb-nr)))
        fasteof(io) && break
    end
    if lb > olb && lb > nr
        resize!(buf, nr) # shrink to just contain input data if was resized
    end
    return nr
end
# was (and crashed with)
# = @GC.preserve buf ccall(:ios_readall, Csize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), io.ios, pointer(buf, 1), nb)

# fast_readline
fast_readline(io::IO) = readline(io)
fast_readline(io::IOStream) = ccall(:jl_readuntil, Ref{String}, (Ptr{Cvoid}, UInt8, UInt8, UInt8), io.ios, '\n', 1, 2)

# fast_unsafe_read
fast_unsafe_read(io::IO, p::Ptr{UInt8}, nb::Integer) = unsafe_read(io, p, nb)
fast_unsafe_read(io::IOStream, p::Ptr{UInt8}, nb::Integer) = ccall(:ios_readall, Csize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), io, p, nb)

export
  FastReadInt,
  FastReads,
  fast_readbytes!,
  fast_readline,
  fast_unsafe_read,
  fasteof,
  fastpos,
  fastread!,
  fastread,
  fastread_f16,
  fastread_f32,
  fastread_f64,
  fastread_i8,
  fastread_i16,
  fastread_i24,
  fastread_i32,
  fastread_i64,
  fastseek,
  fastseekend,
  fastskip
end
