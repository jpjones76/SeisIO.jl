export SourceTime

"""
    SourceTime()

QuakeML-compliant seismic source-time parameterization.

Field     | Type    | Meaning         | SeisIO conventions/behavior
--------: |:------- |:--------------  | :----------
 desc     | String  | description     |
 dur      | Float64 | duration        |
 rise     | Float64 | rise time       |
 decay    | Float64 | decay time      |

"""
mutable struct SourceTime
  desc  ::String    # description
  dur   ::Real      # duration
  rise  ::Real      # rise time
  decay ::Real      # decay time

  function SourceTime(
                      desc  ::String,    # description
                      dur   ::Real,      # duration
                      rise  ::Real,      # rise time
                      decay ::Real,      # decay time
                    )
    return new(desc, dur, rise, decay)
  end
end

SourceTime(;
          desc    ::String            = "",
          dur     ::Real              = zero(Float64),
          rise    ::Real              = zero(Float64),
          decay   ::Real              = zero(Float64),
          ) = SourceTime(desc, dur, rise, decay)

isempty(ST::SourceTime) = min(getfield(ST, :dur) == zero(Float64),
                              getfield(ST, :rise) == zero(Float64),
                              getfield(ST, :decay) == zero(Float64),
                              isempty(getfield(ST, :desc)))

function hash(ST::SourceTime)
  h = hash(getfield(ST, :desc))
  for f in (:dur, :rise, :decay)
    h = hash(getfield(ST, f), h)
  end
  return h
end

function isequal(S::SourceTime, U::SourceTime)
  q::Bool = isequal(getfield(S, :desc), getfield(U, :desc))
  for f in (:dur, :rise, :decay)
    q = min(q, getfield(S,f) == getfield(U,f))
  end
  return q
end
==(S::SourceTime, U::SourceTime) = isequal(S, U)

sizeof(ST::SourceTime) = 56 + sizeof(getfield(ST, :desc))

function write(io::IO, ST::SourceTime)
  desc = getfield(ST, :desc)
  write(io, Int64(sizeof(desc)))
  write(io, desc)
  for f in (:dur, :rise, :decay)
    write(io, getfield(ST, f))
  end
  return nothing
end

function read(io::IO, ::Type{SourceTime})
  ST = SourceTime()
  L = read(io, Int64)
  setfield!(ST, :desc, String(read(io, L)))
  for f in (:dur, :rise, :decay)
    setfield!(ST, f, read(io, Float64))
  end
  return ST
end

function show(io::IO, ST::SourceTime)
  if get(io, :compact, false) == false
    println(io, "SourceTime with fields:")
    for f in (:desc, :dur, :rise, :decay)
      fn = lpad(String(f), 5, " ")
      println(io, fn, ": ", getfield(ST, f))
    end
  else
    c = :compact => true
    st_str = string("dur ", repr(getfield(ST, :dur), context=c),
                    ", rise ", repr(getfield(ST, :rise), context=c),
                    ", decay ", repr(getfield(ST, :decay), context=c))

    print(io, str_trunc(st_str, max(80, displaysize(io)[2]-2) - show_os))
  end
  return nothing
end
