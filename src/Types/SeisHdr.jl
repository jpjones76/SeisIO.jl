export SeisHdr

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
