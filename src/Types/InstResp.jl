import Base:getindex, setindex!, show, read, write, isequal, ==, isempty, sizeof, copy, hash
export InstrumentResponse, GenResp, PZResp, PZResp64

@doc """
**InstrumentResponse**

An abstract type whose subtypes (PZResp) describe instrument frequency responses.

Additional structures can be added for custom types.

""" InstrumentResponse
abstract type InstrumentResponse end

function showresp_full(io::IO, Resp::T) where {T<:InstrumentResponse}
  F = fieldnames(T)
  println(io, T, " with fields:")
  for f in F
    fn = lpad(String(f), 5, " ")
    println(io, fn, ": ", getfield(Resp,f))
  end
  return nothing
end

function resptype2code(Resp::InstrumentResponse)
  T = typeof(Resp)
  # println(T)
  c = UInt8(
  if T == PZResp
    0x01
  elseif T == PZResp64
    0x02
  else
    0x00
  end
  )
  return c
end

copy(R::T) where {T<:InstrumentResponse} = deepcopy(R)

"""
    GenResp

Generic instrument response with two fields:
* desc::String (descriptive string)
* resp::Array{Complex{Float64},2}
"""
mutable struct GenResp <: InstrumentResponse
  desc::String
  resp::Array{Complex{Float64},2}
  function GenResp(S::String, X::Array{Complex{Float64},2}) where {T<:Complex}
    return new(S, X)
  end
end

# GenResp default
GenResp(;
          desc::String              = "",
          resp::Array{Complex{Float64},2} = Array{Complex{Float64},2}(undef, 0, 0)
        ) = GenResp(desc, resp)
GenResp(X::Array{Complex{Float64},2}) = GenResp(desc = "", resp = X)

# How we read from file
GenResp(s::String, X::Array{T,2}, Y::Array{T,2}) where {T <: Real} = GenResp(s, complex.(Float64.(X), Float64.(Y)))

getindex(x::GenResp, i::Int64) = getindex(getfield(x, :resp), i)
getindex(x::GenResp, i::Int64, j::Int64) = getindex(getfield(x, :resp), i, j)
setindex!(x::GenResp, y::Number, i::Int64) = setindex!(getfield(x, :resp), complex(y), i)
setindex!(x::GenResp, y::Number, i::Int64, j::Int64) = setindex!(getfield(x, :resp), complex(y), i, j)

function show(io::IO, Resp::GenResp)
  if get(io, :compact, false) == false
    showresp_full(io, Resp)
  else
    resp = getfield(Resp, :resp)
    M,N = size(resp)
    M1 = min(M,2)
    N1 = min(N,2)
    print(io, "[")
    for i = 1:M1
      for j = 1:N1
        print(io, repr(resp[i,j], context=:compact=>true))
        if j == N1 && i < M1
          if N > N1
            print(io, " … ")
          end
          print(io, "; ")
        elseif j == N1 && i == M1
          if N > N1
            print(io, " … ;")
          end
          if M > M1
            print(io, " … ")
          end
          print(io, "]")
        else
          print(io, ", ")
        end
      end
    end
    print(io, " (")
    print(io, getfield(Resp, :desc))
    print(io, ")")
  end
  return nothing
end

function write_resp(io::IO, R::GenResp)
  s = codeunits(getfield(R, :desc))
  nu = Int64(length(s))

  r = getfield(R, :resp)
  tc = typ2code(real(eltype(r)))
  nr, nc = size(r)

  write(io, tc)
  write(io, nu)
  write(io, Int64(nr))
  write(io, Int64(nc))
  write(io, s)
  write(io, real(r))
  write(io, imag(r))
  return nothing
end

function readGenResp(io::IO)
  T = code2typ(read(io, UInt8))
  nu = read(io, Int64)
  nr = read(io, Int64)
  nc = read(io, Int64)

  s = String(read(io, nu))
  rr = read!(io, Array{T,2}(undef, nr, nc))
  ri = read!(io, Array{T,2}(undef, nr, nc))
  return GenResp(s, rr, ri)
end

isempty(R::GenResp) = min(isempty(R.desc), isempty(R.resp))
isequal(R1::GenResp, R2::GenResp) = min(isequal(R1.desc, R2.desc), isequal(R1.resp, R2.resp))
==(R1::GenResp, R2::GenResp) = isequal(R1, R2)

hash(R::GenResp) = hash(R.desc, hash(R.resp))

sizeof(R::GenResp) = 16 + sizeof(getfield(R, :desc)) + sizeof(getfield(R, :resp))

@doc """
    PZResp

Instrument response with three fields:

|:---|:---|:---- |
| c  | Float32  | damping constant         |
| p  | Array{Complex{Float32},1} | poles                    |
| z  | Array{Complex{Float32},1} | zeroes                   |

    PZResp64

As PZResp, but all fields use Float64.

    PZResp(X::Array{Complex{T},2} [, rev=true])

Convert X to a PZResp64 (if `T == Float64`) or PZResp32 object. Assumes poles are
in X[:,1] and zeros in X[:,2]; specify `rev=true` to reverse the sense of the
column assignments.
""" PZResp
mutable struct PZResp <: InstrumentResponse
  c::Float32
  p::Array{Complex{Float32},1}
  z::Array{Complex{Float32},1}

  function PZResp(  c::Float32,
                    p::Array{Complex{Float32},1},
                    z::Array{Complex{Float32},1} )
    return new(c, p, z)
  end
end

@doc (@doc PZResp)
mutable struct PZResp64 <: InstrumentResponse
  c::Float64
  p::Array{Complex{Float64},1}
  z::Array{Complex{Float64},1}

  function PZResp64( c::Float64,
                    p::Array{Complex{Float64},1},
                    z::Array{Complex{Float64},1} )
    return new(c, p, z)
  end

end

# PZResp default
PZResp( ;
        c::Float32                    = 0.0f0,
        p::Array{Complex{Float32},1}  = Array{Complex{Float32},1}(undef, 0),
        z::Array{Complex{Float32},1}  = Array{Complex{Float32},1}(undef, 0)
        ) = PZResp(c, p, z)
PZResp64( ;
          c::Float64                    = 0.0,
          p::Array{Complex{Float64},1}  = Array{Complex{Float64},1}(undef, 0),
          z::Array{Complex{Float64},1}  = Array{Complex{Float64},1}(undef, 0)
          ) = PZResp64(c, p, z)

# How we read from file
PZResp(c::Float32, pr::Array{Float32,1}, pi::Array{Float32,1},
  zr::Array{Float32,1}, zi::Array{Float32,1}) = PZResp(c, complex.(pr, pi), complex.(zr, zi))
PZResp64(c::Float64, pr::Array{Float64,1}, pi::Array{Float64,1},
    zr::Array{Float64,1}, zi::Array{Float64,1}) = PZResp64(c, complex.(pr, pi), complex.(zr, zi))


# Convert from a 2-column complex response
function PZResp(X::Array{Complex{T},2}; rev::Bool=false) where {T <: AbstractFloat}
  @assert size(X,2) == 2
  if rev
    p = X[:,2]
    z = X[:,1]
  else
    p = X[:,1]
    z = X[:,2]
  end
  if T == Float64
    return PZResp64(1.0, p, z)
  else
    return PZResp(1.0f0, p, z)
  end
end

function show(io::IO, Resp::Union{PZResp,PZResp64})
  if get(io, :compact, false) == false
    showresp_full(io, Resp)
  else
    c = :compact => true
    print(io, "c = ", repr(getfield(Resp, :c), context=c), ", ",
              length(getfield(Resp, :z)), " zeros, ",
              length(getfield(Resp, :p)), " poles")
  end
  return nothing
end

function write_resp(io::IO, R::Union{PZResp,PZResp64})
  c = getfield(R, :c)
  z = getfield(R, :z)
  p = getfield(R, :p)
  write(io, typ2code(typeof(c)))
  write(io, Int64(lastindex(p)))
  write(io, Int64(lastindex(z)))
  write(io, c)
  write(io, real(p))
  write(io, imag(p))
  write(io, real(z))
  write(io, imag(z))
  return nothing
end

function readPZResp(io::IO)
  T = code2typ(read(io, UInt8))
  np = read(io, Int64)
  nz = read(io, Int64)
  c = read(io, T)
  pr = read!(io, Array{T,1}(undef, np))
  pi = read!(io, Array{T,1}(undef, np))
  zr = read!(io, Array{T,1}(undef, nz))
  zi = read!(io, Array{T,1}(undef, nz))
  if T == Float64
    return PZResp64(c, pr, pi, zr, zi)
  else
    return PZResp(c, pr, pi, zr, zi)
  end
end

isempty(R::Union{PZResp,PZResp64}) = min(R.c == zero(typeof(R.c)), isempty(getfield(R, :p)), isempty(getfield(R, :z)))

function isequal(R1::Union{PZResp,PZResp64}, R2::Union{PZResp,PZResp64})
  q = isequal(getfield(R1, :c), getfield(R2, :c))
  if q == true
    q = min(q, isequal(getfield(R1, :z), getfield(R2, :z)))
    q = min(q, isequal(getfield(R1, :p), getfield(R2, :p)))
  end
  return q
end
==(R1::Union{PZResp,PZResp64}, R2::Union{PZResp,PZResp64}) = isequal(R1, R2)

function hash(R::Union{PZResp,PZResp64})
  h = hash(R.c)
  h = hash(R.p, h)
  return hash(R.z, h)
end

sizeof(R::Union{PZResp,PZResp64}) = 24 + sizeof(getfield(R, :c)) + sizeof(getfield(R, :z)) + sizeof(getfield(R, :p))
