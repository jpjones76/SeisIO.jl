export SeisSrc

"""
SeisSrc: container for descriptions of a seismic source process

    S = SeisSrc()

Initialize an empty SeisSrc object. Fields can be initialized at creation with keywords; for example, S = SeisSrc(m0 = 1.6e22).

| Field   | Type                | Meaning                                 |
|:----    |:-----               |:--------                                |
| id      | String              | source process ID                       |
| eid     | String              | event ID (note, generally :id != :eid)  |
| m0      | Float64             | scalar seismic moment                   |
| mt      | Array{Float64,1}    | seismic moment tensor                   |
| dm      | Array{Float64,1}    | seismic moment tensor misfit            |
| npol    | Int64               | number of polarities in focal mechanism |
| gap     | Float64             | max azimuthal gap in focal mechanism    |
| pax     | Array{Float64,2}    | principal axes                          |
| planes  | Array{Float64,2}    | nodal planes                            |
| src     | String              | data source string (filename or URL)    |
| st      | SourceTime          | source-time subfield                    |
| misc    | Dict{String,Any}    | dictionary of non-essential information |
| notes   | Array{String,1}     | notes and automated logging             |
See also: EQLoc, EQMag
"""
mutable struct SeisSrc
  id      ::String
  eid     ::String
  m0      ::Float64
  mt      ::Array{Float64,1}
  dm      ::Array{Float64,1}
  npol    ::Int64
  gap     ::Float64
  pax     ::Array{Float64,2}
  planes  ::Array{Float64,2}
  src     ::String
  st      ::SourceTime
  misc    ::Dict{String,Any}
  notes   ::Array{String,1}

  function SeisSrc(
                    id      ::String,
                    eid     ::String,
                    m0      ::Float64,
                    mt      ::Array{Float64,1},
                    dm      ::Array{Float64,1},
                    npol    ::Int64,
                    gap     ::Float64,
                    pax     ::Array{Float64,2},
                    planes  ::Array{Float64,2},
                    src     ::String,
                    st      ::SourceTime,
                    misc    ::Dict{String,Any},
                    notes   ::Array{String,1},
                    )
    return new(id, eid, m0, mt, dm, npol, gap, pax, planes, src, st, misc, notes)
  end
end
SeisSrc(;
          id     ::String             = "",
          eid     ::String            = "",
          m0      ::Float64           = zero(Float64),
          mt      ::Array{Float64,1}  = Float64[],
          dm      ::Array{Float64,1}  = Float64[],
          npol    ::Int64             = zero(Int64),
          gap     ::Float64           = zero(Float64),
          pax     ::Array{Float64,2}  = Array{Float64, 2}(undef, 0, 0),
          planes  ::Array{Float64,2}  = Array{Float64, 2}(undef, 0, 0),
          src     ::String            = "",
          st      ::SourceTime        = SourceTime(),
          misc    ::Dict{String,Any}  = Dict{String,Any}(),
          notes   ::Array{String,1}   = String[],
          ) = SeisSrc(id, eid, m0, mt, dm, npol, gap, pax, planes, src, st, misc, notes)

function isempty(S::SeisSrc)
  q::Bool = min((getfield(S, :m0) == zero(Float64)),
                (getfield(S, :gap) == zero(Float64)),
                (getfield(S, :npol) == zero(Int64)))
  for f in (:id, :eid, :misc, :mt, :dm, :notes, :pax, :planes, :src, :st)
    q = min(q, isempty(getfield(S, f)))
  end
  return q
end

function hash(S::SeisSrc)
  h = hash(getfield(S, :id))
  for f in (:eid, :m0, :mt, :dm, :npol, :gap, :pax, :planes, :src, :st, :misc, :notes)
    h = hash(getfield(S, f), h)
  end
  return h
end

function isequal(S::SeisSrc, U::SeisSrc)
  q::Bool = true
  for f in fieldnames(SeisSrc)
    if f != :notes
      q = min(q, getfield(S,f) == getfield(U,f))
    end
  end
  return q
end
==(S::SeisSrc, U::SeisSrc) = isequal(S, U)

sizeof(S::SeisSrc) = 136 +
  sum([sizeof(getfield(S, f)) for f in (:id, :eid, :mt, :dm, :pax, :planes, :src, :st, :misc, :notes)])

function show(io::IO, S::SeisSrc)
  if get(io, :compact, false) == false
    for f in fieldnames(SeisSrc)
      fn = lpad(uppercase(String(f)), 6, " ")
      if f == :misc
        println(io, fn, ": ", length(getfield(S, :misc)), " items")
      elseif f == :notes
        println(io, fn, ": ", length(getfield(S, :notes)), " entries")
      elseif f == :id || f == :src
        println(io, fn, ": ", getfield(S, f))
      else
        println(io, fn, ": ", repr(getfield(S, f), context=:compact=>true))
      end
    end
  else
    c = :compact => true

    # Order of preference: mt, np, pax
    mech_str = string("m₀ = ", repr(getfield(S, :m0), context=c), "; S = ",
                      repr(getfield(S, :mt), context=c), "; ",
                      "NP = ", repr(getfield(S, :planes), context=c), "; ",
                      "PAX = ", repr(getfield(S, :pax), context=c))

    L = length(mech_str)
    L_max = displaysize(io)[2]
    if L > L_max
      print(io, mech_str[1:L_max-1], "…")
    else
      print(io, mech_str)
    end
  end
  return nothing
end
show(S::SeisSrc) = show(stdout, S)

# SeisSrc
function write(io::IO, S::SeisSrc)
  id  = codeunits(getfield(S, :id))
  eid = codeunits(getfield(S, :eid))
  src = codeunits(getfield(S, :src))

  # Write begins ------------------------------------------------------
  write(io, Int64(length(id)))
  write(io, id)                                             # id
  write(io, Int64(length(eid)))
  write(io, eid)                                            # eid
  write(io, S.m0)                                           # m0
  write(io, Int64(length(S.mt)))
  write(io, S.mt)                                           # mt
  write(io, Int64(length(S.dm)))
  write(io, S.dm)                                           # dm
  write(io, S.npol)                                         # npol
  write(io, S.gap)                                          # gap
  r, c = size(S.pax)
  write(io, Int64(r), Int64(c)),
  write(io, S.pax)                                          # pax
  r, c = size(S.planes)
  write(io, Int64(r), Int64(c)),
  write(io, S.planes)                                       # planes
  write(io, Int64(length(src)))
  write(io, src)                                            # src
  write(io, getfield(S, :st))                               # st
  write_misc(io, getfield(S, :misc))                        # misc
  write_string_vec(io, getfield(S, :notes))                 # notes

  # Write ends --------------------------------------------------------
  return nothing
end

function read(io::IO, ::Type{SeisSrc})
  u = getfield(BUF, :buf)
  return SeisSrc( String(read(io, read(io, Int64))),                    # :id
                  String(read(io, read(io, Int64))),                    # :eid
                  read(io, Float64),                                    # :m0
                  read!(io, Array{Float64, 1}(undef, read(io, Int64))), # :mt
                  read!(io, Array{Float64, 1}(undef, read(io, Int64))), # :dm
                  read(io, Int64),                                      # :npol
                  read(io, Float64),                                    # :gap
                  read!(io, Array{Float64, 2}(undef,
                    read(io, Int64), read(io, Int64))),                 # :pax
                  read!(io, Array{Float64, 2}(undef,
                    read(io, Int64), read(io, Int64))),                 # :planes
                  String(read(io, read(io, Int64))),                    # :src
                  read(io, SourceTime),                                 # :st
                  read_misc(io, u),                                     # :misc
                  read_string_vec(io, u) )                              # :notes
end
