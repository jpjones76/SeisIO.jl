export EQLoc

abstract type ComputedLoc end

function show(io::IO, Loc::T) where {T <: ComputedLoc}
  if get(io, :compact, false) == false
    println(io, T, " with fields:")
    for f in fieldnames(T)
      fn = lpad(String(f), 5, " ")
      if f == :flags
        println(io, fn, ": ", bitstring(getfield(Loc, f)))
      else
        println(io, fn, ": ", getfield(Loc, f))
      end
    end
  else
    c = :compact => true
    print(io, repr(getfield(Loc, :lat), context=c), " N, ",
              repr(getfield(Loc, :lon), context=c), " E, ",
              repr(getfield(Loc, :dep), context=c), " km")
  end
  return nothing
end

isequal(Loc1::T, Loc2::T) where {T <: ComputedLoc} = minimum(
  [isequal(getfield(Loc1, f), getfield(Loc2, f)) for f in fieldnames(T)] )
==(Loc1::T, Loc2::T) where {T <: ComputedLoc} = isequal(Loc1, Loc2)

function hash(Loc::T) where {T<:ComputedLoc}
  h = hash(zero(UInt64))
  for f in fieldnames(T)
    h = hash(getfield(Loc, f), h)
  end
  return h
end


"""
    EQLoc

QuakeML-compliant earthquake location

Field     | Type    | Meaning       | SeisIO conventions/behavior
--------: |:------- |:--------------| :----------
 lat      | Float64 | latitude      | °N = +
 lon      | Float64 | longitude     | °E = +
 dep      | Float64 | depth         | km; down = +
 dx       | Float64 | x error       | uses units of data source (typically km)
 dy       | Float64 | y error       | uses units of data source (typically km)
 dz       | Float64 | z error       | uses units of data source (typically km)
 dt       | Float64 | ot error      | uses units of data source (typically s)
 se       | Float64 | std error     | uses units of data source (typically s)
 rms      | Float64 | rms pick err  | uses units of data source (typically s)
 gap      | Float64 | azimuthal gap | uses units of data source (typically °)
 dmin     | Float64 | min sta dist  | uses units of data source (typically km)
 dmax     | Float64 | max sta dist  | uses units of data source (typically km)
 nst      | Int64   | # of stations |
 flags    | UInt8   | boolean flags | access flag[n] with >>(<<(flags,n-1),7)
 datum    | String  | geog. datum   |
 typ      | String  | location type | freeform (e.g. "centroid", "hypocenter")
 sig      | String  | significance  | freeform (e.g. "95%", "2σ")
          |         | / confidence  |
 src      | String  | source        | freeform (e.g. "HYPOELLIPSE", "HypoDD")

flags (0x01 = true, 0x00 = false)
1. x fixed?
2. y fixed?
3. z fixed?
4. t fixed?
"""
mutable struct EQLoc <: ComputedLoc
  lat   ::Float64
  lon   ::Float64
  dep   ::Float64
  dx    ::Float64
  dy    ::Float64
  dz    ::Float64
  dt    ::Float64
  se    ::Float64
  rms   ::Float64
  gap   ::Float64
  dmin  ::Float64
  dmax  ::Float64
  nst   ::Int64
  flags ::UInt8
  datum ::String
  typ   ::String
  sig   ::String
  src   ::String

  function EQLoc(
                  lat   ::Float64,
                  lon   ::Float64,
                  dep   ::Float64,
                  dx    ::Float64,
                  dy    ::Float64,
                  dz    ::Float64,
                  dt    ::Float64,
                  se    ::Float64,
                  rms   ::Float64,
                  gap   ::Float64,
                  dmin  ::Float64,
                  dmax  ::Float64,
                  nst   ::Int64,
                  flags ::UInt8,
                  datum ::String,
                  typ   ::String,
                  sig   ::String,
                  src   ::String,
                  )
    return new(lat, lon, dep, dx, dy, dz, dt, se, rms, gap, dmin, dmax, nst, flags, datum, typ, sig, src)
  end
end

EQLoc(;
        lat   ::Float64                   = zero(Float64),
        lon   ::Float64                   = zero(Float64),
        dep   ::Float64                   = zero(Float64),
        dx    ::Float64                   = zero(Float64),
        dy    ::Float64                   = zero(Float64),
        dz    ::Float64                   = zero(Float64),
        dt    ::Float64                   = zero(Float64),
        se    ::Float64                   = zero(Float64),
        rms   ::Float64                   = zero(Float64),
        gap   ::Float64                   = zero(Float64),
        dmin  ::Float64                   = zero(Float64),
        dmax  ::Float64                   = zero(Float64),
        nst   ::Int64                     = zero(Int64),
        flags ::UInt8                     = 0x00,
        datum ::String                    = "",
        typ   ::String                    = "",
        sig   ::String                    = "",
        src   ::String                    = "",
        ) = EQLoc(lat, lon, dep, dx, dy, dz, dt, se, rms, gap, dmin, dmax, nst, flags, datum, typ, sig, src)

function write(io::IO, Loc::EQLoc)
  for f in (:lat, :lon, :dep, :dx, :dy, :dz, :dt, :se, :rms, :gap, :dmin, :dmax, :nst, :flags)
    write(io, getfield(Loc, f))
  end
  write(io, sizeof(Loc.datum))
  write(io, Loc.datum)
  write(io, sizeof(Loc.typ))
  write(io, Loc.typ)
  write(io, sizeof(Loc.sig))
  write(io, Loc.sig)
  write(io, sizeof(Loc.src))
  write(io, Loc.src)
  return nothing
end

read(io::IO, ::Type{EQLoc}) = EQLoc(read!(io, Array{Float64,1}(undef, 12))...,
  read(io, Int64),
  read(io, UInt8),
  String(read(io, read(io, Int64))),
  String(read(io, read(io, Int64))),
  String(read(io, read(io, Int64))),
  String(read(io, read(io, Int64)))
  )

function isempty(Loc::EQLoc)
  q::Bool = min(isempty(getfield(Loc, :datum)),
                isempty(getfield(Loc, :typ)),
                isempty(getfield(Loc, :sig)),
                isempty(getfield(Loc, :src)),
                getfield(Loc, :nst) == zero(Int64),
                getfield(Loc, :flags) == 0x00)
  for f in (:lat, :lon, :dep, :dx, :dy, :dz, :dt, :se, :rms, :gap, :dmin, :dmax)
    q = min(q, getfield(Loc, f) == zero(Float64))
  end
  return q
end

sizeof(Loc::EQLoc) = 233 +
                      sizeof(getfield(Loc, :datum)) +
                      sizeof(getfield(Loc, :typ)) +
                      sizeof(getfield(Loc, :sig)) +
                      sizeof(getfield(Loc, :src))
