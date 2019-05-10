# import Base:getindex, setindex!, show, read, write, isequal, ==, isempty, sizeof, hash
export InstrumentPosition, GenLoc, GeoLoc, UTMLoc, XYLoc

@doc """
**InstrumentPosition**

An abstract type whose subtypes (GenLoc, GeoLoc, UTMLoc, XYLoc)
  describe instrument positions in different ways.

Additional structures can be added for custom types.

Matrix of structure fields and rough equivalencies:

| **GenLoc** | **GeoLoc** | **UTMLoc** | **XYLoc** |
|:---|:---|:---|:---|
| datum | datum | datum | datum |
| loc | | | |
| | zone | orig |
| | lon | E | x |
| | lat | N | y |
| | el | el | z |
| | dep | dep | |
| | az | az | az |
| | inc | inc | inc |

""" InstrumentPosition
abstract type InstrumentPosition end


function showloc_full(io::IO, Loc::T) where {T<:InstrumentPosition}
  F = fieldnames(T)
  println(io, T, " with fields:")
  for f in F
    fn = lpad(String(f), 5, " ")
    println(io, fn, ": ", getfield(Loc,f))
  end
  return nothing
end

function loctype2code(Loc::InstrumentPosition)
  T = typeof(Loc)
  c = UInt8(
  if T == GeoLoc
    0x01
  elseif T == UTMLoc
    0x02
  elseif T == XYLoc
    0x03
  else
    0x00
  end
  )
  return c
end

function code2loctype(c::UInt8)
  T::Type = (
  if c == 0x01
    GeoLoc
  elseif c == 0x02
    UTMLoc
  elseif c == 0x03
    XYLoc
  else
    GenLoc
  end
  )
  return T
end

"""
    GenLoc

Generic instrument location with two fields:
* datum::String
* loc::Array{T,1} where {T<:AbstractFloat}
"""
mutable struct GenLoc{T} <: InstrumentPosition where T<:AbstractFloat
  datum::String
  loc::Array{T,1}
  function GenLoc{T}() where {T<:AbstractFloat}
    return new("", Array{Float64,1}(undef, 0))
  end
  function GenLoc{T}(S::String, X::Array{T,1}) where {T<:AbstractFloat}
    return new(S, X)
  end
end
GenLoc() = GenLoc{Float64}("", Array{Float64,1}(undef, 0))
GenLoc(X::Array{T,1}) where {T <: AbstractFloat} = GenLoc{T}("", [X...])
getindex(x::GenLoc{T}, i::Int64) where {T<:AbstractFloat} =
  getindex(getfield(x, :loc), i)
setindex!(x::GenLoc{T}, y, i::Int64) where {T<:AbstractFloat} =
  setindex!(getfield(x, :loc), y, i)

function show(io::IO, Loc::GenLoc)
  if get(io, :compact, false) == false
    showloc_full(io, Loc)
  else
    print(io, repr(getfield(Loc, :loc), context=:compact => true))
  end
  return nothing
end

function writeloc(io::IO, Loc::GenLoc)
  datum = codeunits(getfield(Loc, :datum))
  loc = getfield(Loc, :loc)
  L1 = Int64(length(datum))
  L2 = Int64(length(loc))
  write(io, L1)
  write(io, L2)
  write(io, datum)
  write(io, loc)
  return nothing
end

function readloc!(io::IO, Loc::GenLoc)
  L1 = read(io, Int64)
  L2 = read(io, Int64)
  setfield!(Loc, :datum, String(read(io, L1)))
  loc = Array{Float64, 1}(undef, L2)
  read!(io, loc)
  setfield!(Loc, :loc, loc)
  return nothing
end

isempty(Loc::GenLoc) = min(isempty(Loc.datum), isempty(Loc.loc))
hash(Loc::GenLoc) = hash(Loc.datum, hash(Loc.loc))
isequal(S::GenLoc, U::GenLoc) = min(isequal(S.datum, U.datum), isequal(S.loc, U.loc))
==(S::GenLoc, U::GenLoc) = isequal(S, U)

sizeof(Loc::GenLoc) = 16 + sizeof(Loc.datum) + sizeof(Loc.loc)

"""
    GeoLoc

Standard instrument location description:
* datum::String
* lat::Float64 (North is positive)
* lon::Float64 (East is positive)
* el::Float64 (above sea level is positive)
* depth::Float64
* az::Float64 (clockwise from north)
* inc::Float64 (downward from +z = 0°)
"""
mutable struct GeoLoc <: InstrumentPosition
  datum::String
  lat::Float64
  lon::Float64
  el::Float64
  dep::Float64
  az::Float64
  inc::Float64

  function GeoLoc(
                  datum ::String ,
                  lat   ::Float64,
                  lon   ::Float64,
                  el    ::Float64,
                  dep   ::Float64,
                  az    ::Float64,
                  inc   ::Float64
                  )
    return new(datum, lat, lon, el, dep, az, inc)
  end
end

GeoLoc(;
        datum ::String                    = "",
        lat   ::Float64                   = zero(Float64),
        lon   ::Float64                   = zero(Float64),
        el    ::Float64                   = zero(Float64),
        dep   ::Float64                   = zero(Float64),
        az    ::Float64                   = zero(Float64),
        inc   ::Float64                   = zero(Float64)
        ) = GeoLoc(datum, lat, lon, el, dep, az, inc)

function show(io::IO, loc::GeoLoc)
  if get(io, :compact, false) == false
    showloc_full(io, loc)
  else
    c = :compact => true
    print(io, repr(getfield(loc, :lat), context=c), " N, ",
              repr(getfield(loc, :lon), context=c), " E, ",
              repr(getfield(loc, :el), context=c), " m")
  end
  return nothing
end

function writeloc(io::IO, Loc::GeoLoc)
  datum = codeunits(getfield(Loc, :datum))
  L = Int64(length(datum))
  write(io, L)
  write(io, datum)
  for f in (:lat, :lon, :el, :dep, :az, :inc)
    write(io, getfield(Loc, f))
  end
  return nothing
end

function readloc!(io::IO, Loc::GeoLoc)
  L = read(io, Int64)
  setfield!(Loc, :datum, String(read(io, L)))
  for f in (:lat, :lon, :el, :dep, :az, :inc)
    setfield!(Loc, f, read(io, Float64))
  end
  return nothing
end

function isempty(Loc::GeoLoc)
  q::Bool = isempty(getfield(Loc, :datum))
  for f in (:lat, :lon, :el, :dep, :az, :inc)
    q = min(q, getfield(Loc, f) == 0.0)
  end
  return q
end

function hash(Loc::GeoLoc)
  h = hash(getfield(Loc, :datum))
  for f in (:lat, :lon, :el, :dep, :az, :inc)
    h = hash(getfield(Loc, f), h)
  end
  return h
end

function isequal(S::GeoLoc, U::GeoLoc)
  q::Bool = isequal(getfield(S, :datum), getfield(U, :datum))
  if q == false
    return q
  else
    for f in (:lat, :lon, :el, :dep, :az, :inc)
      q = min(q, getfield(S,f) == getfield(U,f))
    end
    return q
  end
end
==(S::GeoLoc, U::GeoLoc) = isequal(S, U)

sizeof(Loc::GeoLoc) = 104 + sizeof(getfield(Loc, :datum))

"""
    UTMLoc

UTM instrument location
* datum::String
* zone::Int8
* hemi:: Char (hemisphere)
* E::UInt64 (Easting, in meters)
* N::UInt64 (Northing, in meters)
* el::Float64
* dep::Float64
* az::Float64 (clockwise from north)
* inc::Float64 (downward from +z = 0°)
"""
mutable struct UTMLoc <: InstrumentPosition
  datum::String
  zone::Int8
  hemi::Char
  E::UInt64
  N::UInt64
  el::Float64
  dep::Float64
  az::Float64
  inc::Float64
  function UTMLoc()
    z = zero(Float64)
    uz = zero(UInt64)
    return new("", zero(Int8), ' ', uz, uz, z, z, z, z)
  end
end

function show(io::IO, loc::UTMLoc)
  if get(io, :compact, false) == false
    showloc_full(io, loc)
  else
    print(io, getfield(loc, :zone), " ",
              getfield(loc, :hemi), " ",
              getfield(loc, :E), " ",
              getfield(loc, :N))
  end
  return nothing
end

function writeloc(io::IO, Loc::UTMLoc)
  datum = codeunits(getfield(Loc, :datum))
  L = Int64(length(datum))
  write(io, L)
  write(io, datum)
  for f in (:zone, :hemi, :E, :N, :el, :dep, :az, :inc)
    write(io, getfield(Loc, f))
  end
  return nothing
end

function readloc!(io::IO, Loc::UTMLoc)
  L = read(io, Int64)
  setfield!(Loc, :datum, String(read(io, L)))
  setfield!(Loc, :zone, read(io, Int8))
  setfield!(Loc, :hemi, read(io, Char))
  setfield!(Loc, :E, read(io, UInt64))
  setfield!(Loc, :N, read(io, UInt64))
  for f in (:el, :dep, :az, :inc)
    setfield!(Loc, f, read(io, Float64))
  end
  return nothing
end

function isempty(Loc::UTMLoc)
  q::Bool = isempty(getfield(Loc, :datum))
  q = min(q, getfield(Loc, :zone) == zero(Int8))
  q = min(q, getfield(Loc, :hemi) == ' ')
  q = min(q, getfield(Loc, :E) == zero(UInt64))
  q = min(q, getfield(Loc, :N) == zero(UInt64))
  for f in (:el, :dep, :az, :inc)
    q = min(q, getfield(Loc, f) == zero(Float64))
  end
  return q
end

function hash(Loc::UTMLoc)
  h = hash(getfield(Loc, :datum))
  for f in (:zone, :hemi, :E, :N, :el, :dep, :az, :inc)
    h = hash(getfield(Loc, f), h)
  end
  return h
end

function isequal(S::UTMLoc, U::UTMLoc)
  q::Bool = isequal(getfield(S, :datum), getfield(U, :datum))
  if q == false
    return q
  else
    for f in (:zone, :hemi, :E, :N, :el, :dep, :az, :inc)
      q = min(q, getfield(S,f) == getfield(U,f))
    end
    return q
  end
end
==(S::UTMLoc, U::UTMLoc) = isequal(S, U)

sizeof(Loc::UTMLoc) = 114 + sizeof(Loc.datum)


"""
    XYLoc

Locally defined instrument position:
* datum::String
* x::Float64 (meters)
* y::Float64 (meters)
* z::Float64 (meters)
* az::Float64 (clockwise from north)
* inc::Float64 (downward from +z = 0°)
* ox::Float64 (origin, typically geographic)
* oy::Float64
* oz::Float64
"""
mutable struct XYLoc <: InstrumentPosition
  datum::String
  x::Float64
  y::Float64
  z::Float64
  az::Float64
  inc::Float64
  ox::Float64
  oy::Float64
  oz::Float64
  function XYLoc()
    z = zero(Float64)
    return new("", z, z, z, z, z, z, z, z)
  end
end

function show(io::IO, loc::XYLoc)
  if get(io, :compact, false) == false
    showloc_full(io, loc)
  else
    c = :compact => true
    print(io, "x ", repr(getfield(loc, :x), context=c),
              ", y ", repr(getfield(loc, :x), context=c),
              ", z ", repr(getfield(loc, :x), context=c))
  end
  return nothing
end

function writeloc(io::IO, Loc::XYLoc)
  datum = codeunits(getfield(Loc, :datum))
  L = Int64(length(datum))
  write(io, L)
  write(io, datum)
  for f in (:x, :y, :z, :az, :inc, :ox, :oy, :oz)
    write(io, getfield(Loc, f))
  end
  return nothing
end

function readloc!(io::IO, Loc::XYLoc)
  L = read(io, Int64)
  setfield!(Loc, :datum, String(read(io, L)))
  for f in (:x, :y, :z, :az, :inc, :ox, :oy, :oz)
    setfield!(Loc, f, read(io, Float64))
  end
  return nothing
end

function isempty(Loc::XYLoc)
  z = zero(Float64)
  q::Bool = isempty(getfield(Loc, :datum))
  q = min(q, getfield(Loc, :datum) == (z, z, z))
  for f in (:x, :y, :z, :az, :inc)
    q = min(q, getfield(Loc, f) == z)
  end
  return q
end

function hash(Loc::XYLoc)
  h = hash(getfield(Loc, :datum))
  for f in (:x, :y, :z, :az, :inc, :ox, :oy, :oz)
    h = hash(getfield(Loc, f), h)
  end
  return h
end

function isequal(S::XYLoc, U::XYLoc)
  q::Bool = isequal(getfield(S, :datum), getfield(U, :datum))
  if q == false
    return q
  else
    for f in (:x, :y, :z, :az, :inc, :ox, :oy, :oz)
      q = min(q, getfield(S,f) == getfield(U,f))
    end
    return q
  end
end
==(S::XYLoc, U::XYLoc) = isequal(S, U)

sizeof(Loc::XYLoc) = 136 + sizeof(getfield(Loc, :datum))
