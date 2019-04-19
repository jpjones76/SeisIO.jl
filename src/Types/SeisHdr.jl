import Base:isequal, isempty, sizeof, ==
export SeisHdr

unset_3tup = tuple(0.0, 0.0, 0.0)

"""
SeisHdr structures contain event header data for use with SeisIO.

    S = SeisHdr()

Initialize an empty seismic header structure. Fields can also be initialized at creation with keywords. For example:

    S = SeisHdr(mag=(1.1f0,'l',' '), loc=[45.37, -121.69, 6.8])

Create a SeisHdr structure with magnitude 1.1 (Ml) and location 45.37N, 121.69W, z=6.8 km. Fields not specified at creation are initialized to SeisIO defaults.

| kw  | Type                        | Meaning                       |
|:----|:-----                       |:--------                      |
| id  | Int64                       | Event ID                      |
| ot  | DateTime                    | Origin time                   |
| loc | Array{Float64, 1}           | Hypocenter                    |
| mag | Tuple{Float32, String}      | (Magnitude, Scale)            |
| int | Tuple{UInt8, String}        | (Intensity, Scale)            |
| mt  | Array{Float64,1}            | Moment tensor: (1-6) tensor,  |
|     |                             | (7) scalar moment, (8) %DC    |
| np  | Array{Tuple{3xFloat64}, 1}  | Nodal planes                  |
| pax | Array{Tuple{3xFloat64}, 1}  | Principal axes                |
| src | String                      | Data source (URL/filename)    |

Designate magnitude scale with an appropriate subscript, e.g. 'w', 'b' for M_wb. Use '?' for unknown.
"""
mutable struct SeisHdr
  id::Int64
  ot::DateTime
  loc::Array{Float64,1}
  mag::Tuple{Float32,String}
  int::Tuple{UInt8,String}
  mt::Array{Float64,1}
  np::Array{Tuple{Float64,Float64,Float64},1}
  pax::Array{Tuple{Float64,Float64,Float64},1}
  src::String
  notes::Array{String,1}
  misc::Dict{String,Any}
  # mag_auth::String
  # auth::String
  # cat::String
  # contrib::String
  # contrib_id::Int64

  function SeisHdr(id::Int64,
    ot::DateTime,
    loc::Array{Float64,1},
    mag::Tuple{Float32,String},
    int::Tuple{UInt8,String},
    mt::Array{Float64,1},
    np::Array{Tuple{Float64,Float64,Float64},1},
    pax::Array{Tuple{Float64,Float64,Float64},1},
    src::String,
    notes::Array{String,1},
    misc::Dict{String,Any})

    return new(id, ot, loc, mag, int, mt, np, pax, src, notes, misc)
  end
end
SeisHdr(; id=0::Int64,
          ot=u2d(0)::DateTime,
          loc=zeros(Float64, 3)::Array{Float64,1},
          mag=(-5.0f0, "Ml")::Tuple{Float32, String},
          int=(0x00, "MMI")::Tuple{UInt8, String},
          mt=zeros(Float64, 8)::Array{Float64, 1},
          np=[unset_3tup, unset_3tup]::Array{Tuple{Float64, Float64, Float64}, 1},
          pax=[unset_3tup, unset_3tup, unset_3tup]::Array{Tuple{Float64, Float64, Float64},1},
          src=""::String,
          notes=Array{String,1}()::Array{String,1},
          misc=Dict{String,Any}()::Dict{String,Any}) = SeisHdr(id, ot, loc, mag, int, mt, np, pax, src, notes, misc)

# =============================================================================
# Methods from Base
sizeof(S::SeisHdr) = sum([sizeof(getfield(S,i)) for i in hdrfields]::Array{Int,1})

function isequal(H::SeisHdr, K::SeisHdr)
  q::Bool = true
  for i in hdrfields
    if i != :notes
      q = min(q, hash(getfield(H,i))==hash(getfield(K,i)))
    end
  end
  return q
end
==(S::SeisHdr, T::SeisHdr) = isequal(S,T)
