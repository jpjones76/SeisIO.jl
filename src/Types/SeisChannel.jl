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
+(S::SeisData, C::SeisChannel) = +(S, SeisData(C))
+(C::SeisChannel, S::SeisData) = +(S, SeisData(C))
+(C::SeisChannel, D::SeisChannel) = +(SeisData(C), SeisData(D))

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
