mutable struct EventChannel <: GphysChannel
  az    ::Float64               # source azimuth
  baz   ::Float64               # backazimuth
  dist  ::Float64               # distance
  id    ::String                # id
  loc   ::InstrumentPosition    # loc
  fs    ::Float64               # fs
  gain  ::Float64               # gain
  misc  ::Dict{String,Any}      # misc
  name  ::String                # name
  notes ::Array{String,1}       # notes
  pha   ::PhaseCat              # phase catalog
  resp  ::InstrumentResponse    # resp
  src   ::String                # src
  t     ::Array{Int64,2}        # time
  units ::String                # units
  x     ::FloatArray            # data

  function EventChannel(
                        az    ::Float64,              # source azimuth
                        baz   ::Float64,              # backazimuth
                        dist  ::Float64,              # distance
                        id    ::String,               # id
                        loc   ::InstrumentPosition,   # loc
                        fs    ::Float64,              # fs
                        gain  ::Float64,              # gain
                        misc  ::Dict{String,Any},     # misc
                        name  ::String,               # name
                        notes ::Array{String,1},      # notes
                        pha   ::PhaseCat,             # phase catalog
                        resp  ::InstrumentResponse,   # resp
                        src   ::String,               # src
                        t     ::Array{Int64,2},       # time
                        units ::String,               # units
                        x     ::FloatArray            # data
                        )
      return new(az, baz, dist, id, loc, fs, gain, misc, name, notes, pha, resp, src, t, units, x)
    end
end

EventChannel(;
  az    ::Float64               = zero(Float64),    # source azimuth
  baz   ::Float64               = zero(Float64),    # backazimuth
  dist  ::Float64               = zero(Float64),    # distance
  fs    ::Float64               = zero(Float64),
  gain  ::Float64               = one(Float64),
  id    ::String                = "",
  loc   ::InstrumentPosition    = GeoLoc(),
  misc  ::Dict{String,Any}      = Dict{String,Any}(),
  name  ::String                = "",
  notes ::Array{String,1}       = Array{String,1}(undef, 0),
  pha   ::PhaseCat              = PhaseCat(),
  resp  ::InstrumentResponse    = PZResp(),
  src   ::String                = "",
  t     ::Array{Int64,2}        = Array{Int64,2}(undef, 0, 2),
  units ::String                = "",
  x     ::FloatArray            = Array{Float32,1}(undef, 0)
  ) = EventChannel(az, baz, dist, id, loc, fs, gain, misc, name, notes, pha, resp, src, t, units, x)

function getindex(S::EventTraceData, j::Int)
  C = EventChannel()
  [setfield!(C, f, getfield(S,f)[j]) for f in datafields]
  return C
end
setindex!(S::EventTraceData, C::EventChannel, j::Int) = (
  [(getfield(S, f))[j] = getfield(C, f) for f in datafields];
  return S)

isempty(Ch::EventChannel) = minimum([isempty(getfield(Ch,f)) for f in datafields])

function pull(S::EventTraceData, i::Integer)
  T = deepcopy(getindex(S, i))
  deleteat!(S,i)
  return T
end

# ============================================================================
# Conversion and push to EventTraceData
function EventTraceData(C::EventChannel)
 S = EventTraceData(1)
 for f in datafields
   setindex!(getfield(S, f), getfield(C, f), 1)
 end
 return S
end

+(S::EventTraceData, C::EventChannel) = (deepcopy(S) + EventTraceData(C))
+(C::EventChannel, S::EventTraceData) = (EventTraceData(C) + deepcopy(S))
+(C::EventChannel, D::EventChannel) = EventTraceData(C,D)

function push!(S::EventTraceData, C::EventChannel)
 for i in datafields
   push!(getfield(S,i), getfield(C,i))
 end
 S.n += 1
 return nothing
end

"""
   findid(C::EventChannel, S::EventTraceData)
   findid(S::EventTraceData, C::EventChannel)

Get the index to the first channel `c` in S where `S.id[c]==C.id`.
"""
findid(C::EventChannel, S::EventTraceData) = findid(C.id, S)
findid(S::EventTraceData, C::EventChannel) = findid(C, S)

function sizeof(Ch::EventChannel)
 s = 0
 for f in (:az, :baz, :dist, :id, :loc, :fs, :gain, :misc, :name, :notes, :pha, :resp, :src, :t, :units, :x)
   targ = getfield(Ch, f)
   s += sizeof(targ)
   if !isempty(targ)
     if f == :notes
       for i in targ
         s += sizeof(i)
       end
     elseif f == :misc || f == :pha
       for i in values(targ)
         s += sizeof(i)
       end
       s += sizeof(collect(keys(targ)))
     end
   end
 end
 return s
end

@doc (@doc namestrip)
namestrip!(C::EventChannel) = namestrip(getfield(C, :name))
