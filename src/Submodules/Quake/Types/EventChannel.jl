export EventChannel

@doc (@doc EventChannel)
mutable struct EventChannel <: GphysChannel
  id    ::String                # id
  name  ::String                # name
  loc   ::InstrumentPosition    # loc
  fs    ::Float64               # fs
  gain  ::Float64               # gain
  resp  ::InstrumentResponse    # resp
  units ::String                # units
  az    ::Float64               # source azimuth
  baz   ::Float64               # backazimuth
  dist  ::Float64               # distance
  pha   ::PhaseCat              # phase catalog
  src   ::String                # src
  misc  ::Dict{String,Any}      # misc
  notes ::Array{String,1}       # notes
  t     ::Array{Int64,2}        # time
  x     ::FloatArray            # data

  function EventChannel(
                        id    ::String,               # id
                        name  ::String,               # name
                        loc   ::InstrumentPosition,   # loc
                        fs    ::Float64,              # fs
                        gain  ::Float64,              # gain
                        resp  ::InstrumentResponse,   # resp
                        units ::String,               # units
                        az    ::Float64,              # source azimuth
                        baz   ::Float64,              # backazimuth
                        dist  ::Float64,              # distance
                        pha   ::PhaseCat,             # phase catalog
                        src   ::String,               # src
                        misc  ::Dict{String,Any},     # misc
                        notes ::Array{String,1},      # notes
                        t     ::Array{Int64,2},       # time
                        x     ::FloatArray            # data
                        )
      return new(id, name, loc, fs, gain, resp, units, az, baz, dist, pha, src, misc, notes, t, x)
    end
end

EventChannel(;
  id    ::String                = "",
  name  ::String                = "",
  loc   ::InstrumentPosition    = GeoLoc(),
  fs    ::Float64               = zero(Float64),
  gain  ::Float64               = one(Float64),
  resp  ::InstrumentResponse    = PZResp(),
  units ::String                = "",
  az    ::Float64               = zero(Float64),    # source azimuth
  baz   ::Float64               = zero(Float64),    # backazimuth
  dist  ::Float64               = zero(Float64),    # distance
  pha   ::PhaseCat              = PhaseCat(),
  src   ::String                = "",
  misc  ::Dict{String,Any}      = Dict{String,Any}(),
  notes ::Array{String,1}       = Array{String,1}(undef, 0),
  t     ::Array{Int64,2}        = Array{Int64,2}(undef, 0, 2),
  x     ::FloatArray            = Array{Float32,1}(undef, 0)
  ) = EventChannel(id, name, loc, fs, gain, resp, units, az, baz, dist, pha, src, misc, notes, t, x)

function getindex(S::EventTraceData, j::Int)
  C = EventChannel()
  [setfield!(C, f, getfield(S,f)[j]) for f in tracefields]
  return C
end
setindex!(S::EventTraceData, C::EventChannel, j::Int) = (
  [(getfield(S, f))[j] = getfield(C, f) for f in tracefields];
  return S)

function isempty(Ch::EventChannel)
  q::Bool = Ch.gain == 1.0
  for f in (:az, :baz, :dist, :fs)
    q = min(q, getfield(Ch, f) == 0.0)
    (q == false) && return q
  end
  for f in (:id, :loc, :misc, :name, :notes, :pha, :resp, :src, :t, :units, :x)
    q = min(q, isempty(getfield(Ch, f)))
    (q == false) && return q
  end
  return q
end

# ============================================================================
# Conversion and push to EventTraceData
function EventTraceData(C::EventChannel)
 S = EventTraceData(1)
 for f in tracefields
   setindex!(getfield(S, f), getfield(C, f), 1)
 end
 return S
end

function push!(S::EventTraceData, C::EventChannel)
 for i in tracefields
   push!(getfield(S,i), getfield(C,i))
 end
 S.n += 1
 return nothing
end

function sizeof(C::EventChannel)
  s = 136
  for f in tracefields
    v = getfield(C,f)
    s += sizeof(v)
    if f == :notes
      if !isempty(v)
        s += sum([sizeof(j) for j in v])
      end
    elseif f == :misc || f == :pha
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

function write(io::IO, S::EventChannel)
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
  write(io, S.az)                                                     # az
  write(io, S.baz)                                                    # baz
  write(io, S.dist)                                                   # dist
  write(io, S.pha)                                                    # pha
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

read(io::IO, ::Type{EventChannel}) = EventChannel(
  String(read(io, read(io, Int64))),                                    # id
  String(read(io, read(io, Int64))),                                    # name
  read(io, code2loctyp(read(io, UInt8))),                              # loc
  read(io, Float64),                                                    # fs
  read(io, Float64),                                                    # gain
  read(io, code2resptyp(read(io, UInt8))),                              # resp
  String(read(io, read(io, Int64))),                                    # units
  read(io, Float64),                                                    # az
  read(io, Float64),                                                    # baz
  read(io, Float64),                                                    # dist
  read(io, PhaseCat),                                                   # pha
  String(read(io, read(io, Int64))),                                    # src
  read_misc(io, getfield(BUF, :buf)),                                   # misc
  read_string_vec(io, getfield(BUF, :buf)),                             # notes
  read!(io, Array{Int64, 2}(undef, read(io, Int64), 2)),                # t
  read!(io, Array{code2typ(read(io,UInt8)),1}(undef, read(io, Int64))), # x
  )
