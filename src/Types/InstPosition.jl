export InstrumentPosition, EQLoc, GenLoc, GeoLoc, UTMLoc, XYLoc

@doc """
**InstrumentPosition**

An abstract type whose subtypes (GenLoc, GeoLoc, UTMLoc, XYLoc)
  describe instrument positions in different ways.

Additional structures can be added for custom types.

Matrix of structure fields and rough equivalencies:

| **GenLoc** | **GeoLoc** | **UTMLoc** | **XYLoc** | **EQLoc** |
|:---|:---|:---|:---|:---|
| datum | datum | datum | datum | datum |
| loc | | | | |
| | zone | orig | |
| | lon | E | x | lon |
| | lat | N | y | lat |
| | el | el | z | |
| | dep | dep | | dep |
| | az | az | az | |
| | inc | inc | inc | |

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

function loctyp2code(Loc::InstrumentPosition)
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

function code2loctyp(c::UInt8)
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
* loc::Array{Float64,1}
"""
mutable struct GenLoc <: InstrumentPosition
  datum::String
  loc::Array{Float64,1}

  GenLoc(datum::String, loc::Array{Float64,1}) = new(datum, loc)
end
GenLoc(; datum::String = "", loc::Array{Float64,1} = Float64[]) = GenLoc(datum, loc)
GenLoc(X::Array{Float64,1}) = GenLoc("", X)
getindex(x::GenLoc, i::Int64) = getindex(getfield(x, :loc), i)
setindex!(x::GenLoc, y::Float64, i::Int64) = setindex!(getfield(x, :loc), y, i)

function show(io::IO, Loc::GenLoc)
  if get(io, :compact, false) == false
    showloc_full(io, Loc)
  else
    print(io, repr(getfield(Loc, :loc), context=:compact => true))
  end
  return nothing
end

function write(io::IO, Loc::GenLoc)
  write(io, Int64(sizeof(Loc.datum)))
  write(io, Loc.datum)
  write(io, Int64(length(Loc.loc)))
  write(io, Loc.loc)
  return nothing
end

read(io::IO, ::Type{GenLoc}) = GenLoc(String(read(io, read(io, Int64))),
  read!(io, Array{Float64, 1}(undef, read(io, Int64))))

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
* dep::Float64
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

function write(io::IO, Loc::GeoLoc)
  datum = codeunits(getfield(Loc, :datum))
  L = Int64(length(datum))
  write(io, L)
  write(io, datum)
  write(io, Loc.lat)
  write(io, Loc.lon)
  write(io, Loc.el)
  write(io, Loc.dep)
  write(io, Loc.az)
  write(io, Loc.inc)
  return nothing
end

read(io::IO, ::Type{GeoLoc}) = GeoLoc(
  String(read(io, read(io, Int64))),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64)
)

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

  UTMLoc(
          datum::String,
          zone::Int8,
          hemi::Char,
          E::UInt64,
          N::UInt64,
          el::Float64,
          dep::Float64,
          az::Float64,
          inc::Float64
          ) = new(datum, zone, hemi, E, N, el, dep, az, inc)
end
UTMLoc(;  datum ::String  = "",
          zone  ::Int8    = zero(Int8),
          hemi  ::Char    = ' ',
          E     ::UInt64  = zero(UInt64),
          N     ::UInt64  = zero(UInt64),
          el    ::Float64 = zero(Float64),
          dep   ::Float64 = zero(Float64),
          az    ::Float64 = zero(Float64),
          inc   ::Float64 = zero(Float64)
          ) = UTMLoc(datum, zone, hemi, E, N, el, dep, az, inc)

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

function write(io::IO, Loc::UTMLoc)
  write(io, sizeof(Loc.datum))
  write(io, Loc.datum)
  write(io, Loc.zone)
  write(io, Loc.hemi)
  write(io, Loc.E)
  write(io, Loc.N)
  write(io, Loc.el)
  write(io, Loc.dep)
  write(io, Loc.az)
  write(io, Loc.inc)
  return nothing
end

read(io::IO, ::Type{UTMLoc}) = UTMLoc(
  String(read(io, read(io, Int64))),
  read(io, Int8),
  read(io, Char),
  read(io, UInt64),
  read(io, UInt64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64)
  )

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
  XYLoc(
          datum ::String,
          x     ::Float64,
          y     ::Float64,
          z     ::Float64,
          az    ::Float64,
          inc   ::Float64,
          ox    ::Float64,
          oy    ::Float64,
          oz    ::Float64
          ) = new(datum, x, y, z, az, inc, ox, oy, oz)
end
XYLoc(; datum ::String  = "",
        x     ::Float64 = zero(Float64),
        y     ::Float64 = zero(Float64),
        z     ::Float64 = zero(Float64),
        az    ::Float64 = zero(Float64),
        inc   ::Float64 = zero(Float64),
        ox    ::Float64 = zero(Float64),
        oy    ::Float64 = zero(Float64),
        oz    ::Float64 = zero(Float64)
      ) = XYLoc(datum, x, y, z, az, inc, ox, oy, oz)

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

function write(io::IO, Loc::XYLoc)
  write(io, sizeof(Loc.datum))
  write(io, Loc.datum)
  write(io, Loc.x)
  write(io, Loc.y)
  write(io, Loc.z)
  write(io, Loc.az)
  write(io, Loc.inc)
  write(io, Loc.ox)
  write(io, Loc.oy)
  write(io, Loc.oz)
  return nothing
end

read(io::IO, ::Type{XYLoc}) = XYLoc(
  String(read(io, read(io, Int64))),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64),
  read(io, Float64)
  )

function isempty(Loc::XYLoc)
  q::Bool = isempty(getfield(Loc, :datum))
  for f in (:x, :y, :z, :az, :inc, :ox, :oy, :oz)
    q = min(q, getfield(Loc, f) == 0.0)
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
