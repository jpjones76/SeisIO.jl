export SeisChannel

@doc (@doc SeisData)
mutable struct SeisChannel <: GphysChannel
  name  ::String
  id    ::String
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
      name  ::String,
      id    ::String,
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

      return new(name, id, loc, fs, gain, resp, units, src, misc, notes, t, x)
    end
end

# Are keywords type-stable now?
SeisChannel(;
            name  ::String              = "",
            id    ::String              = "",
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
            ) = SeisChannel(name, id, loc, fs, gain, resp, units, src, misc, notes, t, x)

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

isempty(Ch::SeisChannel) = minimum([isempty(getfield(Ch,f)) for f in datafields])

function pull(S::SeisData, i::Integer)
  T = deepcopy(getindex(S, i))
  deleteat!(S,i)
  return T
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
+(S::SeisData, C::SeisChannel) = (deepcopy(S) + SeisData(C))
+(C::SeisChannel, S::SeisData) = (SeisData(C) + deepcopy(S))
+(C::SeisChannel, D::SeisChannel) = SeisData(C,D)

function push!(S::SeisData, C::SeisChannel)
  for i in datafields
    push!(getfield(S,i), getfield(C,i))
  end
  S.n += 1
  return nothing
end

function sizeof(Ch::SeisChannel)
  s = 0
  for f in datafields
    targ = getfield(Ch, f)
    s += sizeof(targ)
    if !isempty(targ)
      if f == :notes
        for i in targ
          s += sizeof(i)
        end
      elseif f == :misc
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
namestrip!(C::SeisChannel) = namestrip(C.name)

findid(C::SeisChannel, S::SeisData) = findid(C.id, S)
findid(S::SeisData, C::SeisChannel) = findid(C, S)
