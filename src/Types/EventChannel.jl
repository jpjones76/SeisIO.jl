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
