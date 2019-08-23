export EQMag

"""
    EQMag

Earthquake magnitude container object

Field     | Type    | Meaning
--------: |:------- |:--------------
 val      | Float32 | numeric magnitude value (note: Float32!)
scale     | String  | magnitude scale (freeform)
 gap      | Float64 | azimuthal gap (°)
 nst      | Int64   | number of stations used in magnitude calculation
 src      | String  | magnitude source
"""
mutable struct EQMag
  val     ::Float32
  scale   ::String
  nst     ::Int64
  gap     ::Float64
  src     ::String

  function EQMag( val     ::Float32,
                  scale   ::String,
                  nst     ::Int64,
                  gap     ::Float64,
                  src     ::String
                )
    return new(val, scale, nst, gap, src)
  end
end
EQMag(;
      val     ::Float32   =   -5.0f0,
      scale   ::String    =   "",
      nst     ::Int64     =   zero(Int64),
      gap     ::Float64   =   zero(Float64),
      src     ::String    =   ""
      ) = EQMag(val, scale, nst, gap, src)

isempty(Mag::EQMag) = min(getfield(Mag, :val) == -5.0f0,
                          getfield(Mag, :gap) == zero(Float64),
                          getfield(Mag, :nst) == zero(Int64),
                          isempty(getfield(Mag, :scale)),
                          isempty(getfield(Mag, :src)))

function hash(Mag::EQMag)
  h = hash(getfield(Mag, :val))
  for f in (:scale, :nst, :gap, :src)
    h = hash(getfield(Mag, f), h)
  end
  return h
end

function isequal(S::EQMag, U::EQMag)
  q::Bool = isequal(getfield(S, :val), getfield(U, :val))
  for f in (:scale, :nst, :gap, :src)
    q = min(q, getfield(S,f) == getfield(U,f))
  end
  return q
end
==(S::EQMag, U::EQMag) = isequal(S, U)

sizeof(Mag::EQMag) = 52 + sizeof(Mag.src) + sizeof(Mag.scale)

function write(io::IO, M::EQMag)
  write(io, getfield(M, :val))
  write(io, getfield(M, :gap))
  write(io, getfield(M, :nst))

  scale = codeunits(getfield(M, :scale))
  write(io, Int64(length(scale)))
  write(io, scale)

  src = codeunits(getfield(M, :src))
  write(io, Int64(length(src)))
  write(io, src)
  return nothing
end

function read(io::IO, ::Type{EQMag})
  M = EQMag()
  setfield!(M, :val, read(io, Float32))
  setfield!(M, :gap, read(io, Float64))
  setfield!(M, :nst, read(io, Int64))

  L = read(io, Int64)
  setfield!(M, :scale, String(read(io, L)))

  L = read(io, Int64)
  setfield!(M, :src, String(read(io, L)))
  return M
end

function show(io::IO, Mag::EQMag)
  if get(io, :compact, false) == false
    println(io, "EQMag with fields:")
    for f in (:val, :scale, :nst, :gap, :src)
      fn = lpad(String(f), 5, " ")
      println(io, fn, ": ", getfield(Mag, f))
    end
  else
    c = :compact => true
    print(io, getfield(Mag, :scale), " ",
              repr(getfield(Mag, :val), context=c), " ",
              "(g ", repr(getfield(Mag, :gap), context=c), "°, ",
              "n ", getfield(Mag, :nst), ")")
  end
  return nothing
end
