export EQLoc, SeisHdr

"""
    EQLoc

Standard earthquake location description:
* datum::String
* lat::Float64 (North is positive)
* lon::Float64 (East is positive)
* depth::Float64 (in km; down is positive)
"""
mutable struct EQLoc
  datum::String
  lat::Float64
  lon::Float64
  dep::Float64

  function EQLoc(
                  datum ::String ,
                  lat   ::Float64,
                  lon   ::Float64,
                  dep   ::Float64
                  )
    return new(datum, lat, lon, dep)
  end
end

EQLoc(;
        datum ::String                    = "",
        lat   ::Float64                   = zero(Float64),
        lon   ::Float64                   = zero(Float64),
        dep   ::Float64                   = zero(Float64)
        ) = EQLoc(datum, lat, lon, dep)

function show(io::IO, Loc::EQLoc)
  if get(io, :compact, false) == false
    println(io, "EQLoc with fields:")
    for f in (:datum, :lat, :lon, :dep)
      fn = lpad(String(f), 5, " ")
      println(io, fn, ": ", getfield(Loc, f))
    end
  else
    c = :compact => true
    print(io, repr(getfield(Loc, :lat), context=c), " N, ",
              repr(getfield(Loc, :lon), context=c), " E, ",
              repr(getfield(Loc, :dep), context=c), " km")
  end
  return nothing
end

function writeloc(io::IO, Loc::EQLoc)
  datum = codeunits(getfield(Loc, :datum))
  L = Int64(length(datum))
  write(io, L)
  write(io, datum)
  for f in (:lat, :lon, :dep)
    write(io, getfield(Loc, f))
  end
  return nothing
end

function readloc!(io::IO, Loc::EQLoc)
  L = read(io, Int64)
  setfield!(Loc, :datum, String(read(io, L)))
  for f in (:lat, :lon, :dep)
    setfield!(Loc, f, read(io, Float64))
  end
  return nothing
end

function isempty(Loc::EQLoc)
  q::Bool = isempty(getfield(Loc, :datum))
  for f in (:lat, :lon, :dep)
    q = min(q, getfield(Loc, f) == 0.0)
  end
  return q
end

function hash(Loc::EQLoc)
  h = hash(getfield(Loc, :datum))
  for f in (:lat, :lon, :dep)
    h = hash(getfield(Loc, f), h)
  end
  return h
end

function isequal(S::EQLoc, U::EQLoc)
  q::Bool = isequal(getfield(S, :datum), getfield(U, :datum))
  if q == false
    return q
  else
    for f in (:lat, :lon, :dep)
      q = min(q, getfield(S,f) == getfield(U,f))
    end
    return q
  end
end
==(S::EQLoc, U::EQLoc) = isequal(S, U)

sizeof(Loc::EQLoc) = 56 + sizeof(getfield(Loc, :datum))

"""
SeisHdr: minimalist structure for event header information

    S = SeisHdr()

Initialize an empty SeisHdr object. Fields can be initialized at creation with keywords; for example,

    S = SeisHdr(mag=(1.1f0,'l',' '), loc=[45.37, -121.69, 6.8])

Fields not specified at creation are initialized to SeisIO defaults.

| kw    | Default             | Meaning                           |
|:----  |:-----               |:--------                          |
| axes  | []                  | Focal axes                        |
| id    | 0                   | Event ID                          |
| int   | (0x00, "MMI")       | (Intensity, Intensity Scale)      |
| loc   | (0.0, 0.0, 0.0)     | Hypocenter                        |
| mag   | (-5.0f0, "Ml")      | (Magnitude, Magnitude Scale)      |
| misc  | Dict{String,Any}()  | Dictionary for inessential info   |
| mt    | []                  | Moment tensor                     |
| notes | []                  | Timestamped notes, autologging    |
| ot    | 1970-01-01T00:00:00 | Origin time                       |
| src   | ""                  | Data source (URL/filename)        |

See also: GeoLoc
"""
mutable struct SeisHdr
  axes  ::Array{NTuple{3,Float64},1}
  id    ::Int64
  int   ::Tuple{UInt8,String}
  loc   ::EQLoc
  mag   ::Tuple{Float32,String}
  misc  ::Dict{String,Any}
  mt    ::Array{Float64,1}
  notes ::Array{String,1}
  ot    ::DateTime
  src   ::String

  function SeisHdr(
    axes  ::Array{NTuple{3,Float64},1},
    id    ::Int64,
    int   ::Tuple{UInt8,String},
    loc   ::EQLoc,
    mag   ::Tuple{Float32,String},
    misc  ::Dict{String,Any},
    mt    ::Array{Float64,1},
    notes ::Array{String,1},
    ot    ::DateTime,
    src   ::String
    )

    return new(axes, id, int, loc, mag, misc, mt, notes, ot, src)
  end
end
SeisHdr(;
          axes  ::Array{NTuple{3,Float64},1}  = Array{NTuple{3,Float64},1}(undef, 0),
          id    ::Int64                       = zero(Int64),
          int   ::Tuple{UInt8,String}         = (0x00, "MMI"),
          loc   ::EQLoc                       = EQLoc(),
          mag   ::Tuple{Float32,String}       = (-5.0f0, "Ml"),
          misc  ::Dict{String,Any}            = Dict{String,Any}(),
          mt    ::Array{Float64,1}            = Array{Float64,1}(undef, 0),
          notes ::Array{String,1}             = Array{String,1}(undef, 0),
          ot    ::DateTime                    = u2d(0),
          src   ::String                      = ""
        ) = SeisHdr(axes, id, int, loc, mag, misc, mt, notes, ot, src)

# =============================================================================
# Methods from Base
sizeof(S::SeisHdr) = sum([sizeof(getfield(S,i)) for i in fieldnames(SeisHdr)])

function isempty(H::SeisHdr)
  q = min(getfield(H, :id)  == zero(Int64),
          getfield(H, :ot)  == u2d(0),
          getfield(H, :int) == (0x00, "MMI"),
          getfield(H, :mag) == (-5.0f0, "Ml"))
  if q == true
    for f in (:axes, :loc, :misc, :mt, :src)
      q = min(q, isempty(getfield(H, f)))
    end
  end
  return q
end

function isequal(H::SeisHdr, K::SeisHdr)
  q::Bool = true
  for i in fieldnames(SeisHdr)
    if i != :notes && i != :loc
      q = min(q, hash(getfield(H,i))==hash(getfield(K,i)))
    end
  end
  q = min(q, getfield(H, :loc) == getfield(K, :loc))
  return q
end
==(S::SeisHdr, T::SeisHdr) = isequal(S,T)
