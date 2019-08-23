export SeisHdr

"""
SeisHdr: header information for seismic events

    S = SeisHdr()

Initialize an empty SeisHdr object. Fields can be initialized at creation with
keywords, e.g., SeisHdr(ot=DateTime("2012-01-03T03:49:45"), int=(0x02, "MMI")).

| Field | Default       | Type               | Meaning                        |
|:----  |:-----         |:-----              |:--------                       |
| id    | ""            | String             | Event ID                       |
| int   | (0x00, "")    | Tuple              | (Intensity, Intensity Scale)   |
| loc   | ()            | EQLoc              | Hypocenter data                |
| mag   | ()            | EQMag              | Magnitude data                 |
| misc  | ()            | Dict{String,Any}() | Non-essential info             |
| ot    | (unix epoch)  | DateTime           | Origin time                    |
| notes | []            | Array{String,1}    | Timestamped notes, logging     |
| src   | ""            | String             | Data source (URL/filename)     |
| typ   | ""            | String             | Event type                     |

See also: EQLoc, EQMag
"""
mutable struct SeisHdr
  id    ::String
  int   ::Tuple{UInt8,String}
  loc   ::EQLoc
  mag   ::EQMag
  misc  ::Dict{String,Any}
  notes ::Array{String,1}
  ot    ::DateTime
  src   ::String
  typ   ::String

  function SeisHdr(
    id    ::String,
    int   ::Tuple{UInt8,String},
    loc   ::EQLoc,
    mag   ::EQMag,
    misc  ::Dict{String,Any},
    notes ::Array{String,1},
    ot    ::DateTime,
    src   ::String,
    typ   ::String
    )

    return new(id, int, loc, mag, misc, notes, ot, src, typ)
  end
end
SeisHdr(;
          id    ::String                      = "",
          int   ::Tuple{UInt8,String}         = (0x00, ""),
          loc   ::EQLoc                       = EQLoc(),
          mag   ::EQMag                       = EQMag(),
          misc  ::Dict{String,Any}            = Dict{String,Any}(),
          notes ::Array{String,1}             = Array{String,1}(undef, 0),
          ot    ::DateTime                    = u2d(0),
          src   ::String                      = "",
          typ   ::String                      = "",
          ) = SeisHdr(id, int, loc, mag, misc, notes, ot, src, typ)

# =============================================================================
# Methods from Base
sizeof(H::SeisHdr) = sum([sizeof(getfield(H,i)) for i in fieldnames(SeisHdr)])

function isempty(H::SeisHdr)
  q = min(getfield(H, :ot)  == u2d(0),
          getfield(H, :int) == (0x00, ""))
  if q == true
    for f in (:id, :loc, :mag, :misc, :notes, :src, :typ)
      q = min(q, isempty(getfield(H, f)))
    end
  end
  return q
end

function isequal(H::SeisHdr, K::SeisHdr)
  q::Bool = true
  for i in fieldnames(SeisHdr)
    if i != :notes
      q = min(q, isequal(getfield(H,i), getfield(K,i)))
    end
  end
  return q
end
==(H1::SeisHdr, H2::SeisHdr) = isequal(H1, H2)

function write(io::IO, H::SeisHdr)
  write(io, Int64(sizeof(H.id)))
  write(io, H.id)
  write(io, H.int[1])
  write(io, Int64(sizeof(H.int[2])))
  write(io, H.int[2])
  write(io, H.loc)
  write(io, H.mag)
  write_misc(io, H.misc)
  write_string_vec(io, H.notes)
  write(io, round(Int64, d2u(getfield(H, :ot))*1.0e6))
  write(io, Int64(sizeof(H.src)))
  write(io, H.src)
  write(io, Int64(sizeof(H.typ)))
  write(io, H.typ)
  return nothing
end

read(io::IO, ::Type{SeisHdr}) = SeisHdr(
  String(read(io, read(io, Int64))),
  (read(io, UInt8), String(read(io, read(io, Int64)))),
  read(io, EQLoc),
  read(io, EQMag),
  read_misc(io, BUF.buf),
  read_string_vec(io, BUF.buf),
  u2d(read(io, Int64)*μs),
  String(read(io, read(io, Int64))),
  String(read(io, read(io, Int64)))
  )

summary(H::SeisHdr) = string(typeof(H), ", ",
  repr("text/plain", H.loc, context=:compact=>true), ", ",
  repr("text/plain", H.mag, context=:compact=>true), ", ",
  H.int[2], " ", H.int[1])

function show(io::IO, H::SeisHdr)
  W = max(80, displaysize(io)[2]-2)-show_os
  println(io, "    ID: ", H.id)
  println(io, "   INT: ", H.int[2], " ", H.int[1])
  println(io, "   LOC: ", repr("text/plain", H.loc, context=:compact=>true))
  println(io, "   MAG: ", repr("text/plain", H.mag, context=:compact=>true))
  println(io, "    OT: ", H.ot)
  println(io, "   SRC: ", str_trunc(H.src, W))
  println(io, "   TYP: ", str_trunc(H.typ, W))
  println(io, "  MISC: ", length(H.misc), " items")
  println(io, " NOTES: ", length(H.notes), " entries")
  return nothing
end
show(S::SeisHdr) = show(stdout, S)
