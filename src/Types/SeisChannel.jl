export SeisChannel

@doc (@doc SeisData)
mutable struct SeisChannel <: GphysChannel
  id    ::String
  name  ::String
  loc   ::InstrumentPosition
  fs    ::Float64
  gain  ::Float64
  resp  ::InstrumentResponse
  units ::String
  src   ::String
  misc  ::Dict{String,Any}
  notes ::Array{String,1}
  t     ::Array{Int64,2}
  x     ::FloatArray

  function SeisChannel(
      id    ::String,
      name  ::String,
      loc   ::InstrumentPosition,
      fs    ::Float64,
      gain  ::Float64,
      resp  ::InstrumentResponse,
      units ::String,
      src   ::String,
      misc  ::Dict{String,Any},
      notes ::Array{String,1},
      t     ::Array{Int64,2},
      x     ::FloatArray
      )

      return new(id, name, loc, fs, gain, resp, units, src, misc, notes, t, x)
    end
end

# Are keywords type-stable now?
SeisChannel(;
            id    ::String              = "",
            name  ::String              = "",
            loc   ::InstrumentPosition  = GeoLoc(),
            fs    ::Float64             = zero(Float64),
            gain  ::Float64             = one(Float64),
            resp  ::InstrumentResponse  = PZResp(),
            units ::String              = "",
            src   ::String              = "",
            misc  ::Dict{String,Any}    = Dict{String,Any}(),
            notes ::Array{String,1}     = Array{String,1}(undef, 0),
            t     ::Array{Int64,2}      = Array{Int64,2}(undef, 0, 2),
            x     ::FloatArray          = Array{Float32,1}(undef, 0)
            ) = SeisChannel(id, name, loc, fs, gain, resp, units, src, misc, notes, t, x)

function getindex(S::SeisData, j::Int)
  C = SeisChannel()
  for f in datafields
    setfield!(C, f, getindex(getfield(S,f), j))
  end
  return C
end
setindex!(S::SeisData, C::SeisChannel, j::Int) = (
  [(getfield(S, f))[j] = getfield(C, f) for f in datafields];
  return S)

function isempty(Ch::SeisChannel)
  q::Bool = min(Ch.gain == 1.0, Ch.fs == 0.0)
  if q == true
    for f in (:id, :loc, :misc, :name, :notes, :resp, :src, :t, :units, :x)
      q = min(q, isempty(getfield(Ch, f)))
    end
  end
  return q
end

# ============================================================================
# Conversion and push to SeisData
function SeisData(C::SeisChannel)
  S = SeisData(1)
  for f in datafields
    setindex!(getfield(S, f), getfield(C, f), 1)
  end
  return S
end

function push!(S::SeisData, C::SeisChannel)
  for i in datafields
    push!(getfield(S,i), getfield(C,i))
  end
  S.n += 1
  return nothing
end

# This intentionally undercounts exotic objects in :misc (e.g. a nested Dict)
# because those objects aren't written to disk or created by SeisIO
function sizeof(C::SeisChannel)
  s = 96
  for f in datafields
    v = getfield(C,f)
    s += sizeof(v)
    if f == :notes
      if !isempty(v)
        s += sum([sizeof(j) for j in v])
      end
    elseif f == :misc
      k = collect(keys(v))
      s += sizeof(k) + 64 + sum([sizeof(j) for j in k])
      for p in values(v)
        s += sizeof(p)
        if typeof(p) == Array{String,1}
          s += sum([sizeof(j) for j in p])
        end
      end
    end
  end
  return s
end

function write(io::IO, S::SeisChannel)
  write(io, Int64(sizeof(S.id)))
  write(io, S.id)                                                     # id
  write(io, Int64(sizeof(S.name)))
  write(io, S.name)                                                   # name
  write(io, loctyp2code(S.loc))
  write(io, S.loc)                                                    # loc
  write(io, S.fs)                                                     # fs
  write(io, S.gain)                                                   # gain
  write(io, resptyp2code(S.resp))
  write(io, S.resp)                                                   # resp
  write(io, Int64(sizeof(S.units)))
  write(io, S.units)                                                  # units
  write(io, Int64(sizeof(S.src)))
  write(io, S.src)                                                    # src
  write_misc(io, S.misc)                                              # misc
  write_string_vec(io, S.notes)                                       # notes
  write(io, Int64(size(S.t,1)))
  write(io, S.t)                                                      # t
  write(io, typ2code(eltype(S.x)))
  write(io, Int64(length(S.x)))
  write(io, S.x)                                                      # x
  return nothing
end

read(io::IO, ::Type{SeisChannel}) = SeisChannel(
  String(read(io, read(io, Int64))),                                    # id
  String(read(io, read(io, Int64))),                                    # name
  read(io, code2loctyp(read(io, UInt8))),                              # loc
  read(io, Float64),                                                    # fs
  read(io, Float64),                                                    # gain
  read(io, code2resptyp(read(io, UInt8))),                              # resp
  String(read(io, read(io, Int64))),                                    # units
  String(read(io, read(io, Int64))),                                    # src
  read_misc(io, getfield(BUF, :buf)),                                   # misc
  read_string_vec(io, getfield(BUF, :buf)),                             # notes
  read!(io, Array{Int64, 2}(undef, read(io, Int64), 2)),                # t
  read!(io, Array{code2typ(read(io,UInt8)),1}(undef, read(io, Int64))), # x
  )

convert(::Type{SeisData}, C::SeisChannel) = SeisData(C)
