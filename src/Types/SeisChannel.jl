import Base:in, +, -, *, convert, isequal, length, push!, sizeof

mutable struct SeisChannel
  name::String
  id::String
  loc::Array{Float64,1}
  fs::Float64
  gain::Float64
  resp::Array{Complex{Float64},2}
  units::String
  src::String
  misc::Dict{String,Any}
  notes::Array{String,1}
  t::Array{Int64,2}
  x::Array{Float64,1}

  function SeisChannel(
    name::String,
    id::String,
    loc::Array{Float64,1},
    fs::Float64,
    gain::Float64,
    resp::Array{Complex{Float64},2},
    units::String,
    src::String,
    misc::Dict{String,Any},
    notes::Array{String,1},
    t::Array{Int64,2},
    x::Array{Float64,1})

    new(name, id, loc, fs, gain, resp, units, src, misc, notes, t, x)
  end
end

# Use of keywords is (extremely) non-type-stable and not recommended
SeisChannel(;
            name="New Channel"::String,
            id="...YYY"::String,
            loc=zeros(Float64,5)::Array{Float64,1},
            fs=0.0::Float64,
            gain=1.0::Float64,
            resp=Array{Complex{Float64},2}(undef,0,2)::Array{Complex{Float64},2},
            units=""::String,
            src=""::String,
            misc=Dict{String,Any}()::Dict{String,Any},
            notes=Array{String,1}([tnote("Channel initialized")])::Array{String,1},
            t=Array{Int64,2}(undef,0,2)::Array{Int64,2},
            x=Array{Float64,1}(undef,0)::Array{Float64,1}
            ) = SeisChannel(name, id, loc, fs, gain, resp, units, src, misc, notes, t, x)

in(s::String, C::SeisChannel) = C.id==s

function getindex(S::SeisData, j::Int)
  C = SeisChannel()
  [setfield!(C, f, getfield(S,f)[j]) for f in datafields]
  return C
end
setindex!(S::SeisData, C::SeisChannel, j::Int) = (
  [(getfield(S, f))[j] = getfield(C, f) for f in datafields];
  return S)

function pull(S::SeisData, i::Integer)
  T = deepcopy(getindex(S, i))
  deleteat!(S,i)
  return T
end


# ============================================================================
# Conversion to and merge with SeisData
function SeisData(C::SeisChannel)
  S = SeisData(1)
  [setfield!(S, f, Array{fieldtype(SeisChannel,f),1}([getfield(C,f)])) for f in datafields]
  return S
end
convert(::Type{SeisData}, C::SeisChannel) = SeisData(C)
+(S::SeisData, C::SeisChannel) = (T = deepcopy(S); return T + SeisData(C))
+(C::SeisChannel, D::SeisChannel) = SeisData(C,D)

# push!(S::SeisData, C::SeisChannel)  = (
#   [setfield!(S, i, push!(getfield(S,i), getfield(C,i))) for i in datafields];
#   S.n += 1;
#   return S)
function push!(S::SeisData, C::SeisChannel)
  for i in datafields
    setfield!(S, i, push!(getfield(S,i), getfield(C,i)))
  end
  S.n += 1
  return
end

isequal(S::SeisChannel, U::SeisChannel) = minimum([hash(getfield(S,i))==hash(getfield(U,i)) for i in datafields]::Array{Bool,1})
==(S::SeisChannel, U::SeisChannel) = isequal(S,U)::Bool

"""
    findid(C::SeisChannel, S::SeisData)
    findid(S::SeisData, C::SeisChannel)

Get the index to the first channel `c` in S where `S.id[c]==C.id`.
"""
function findid(C::SeisChannel, S::SeisData)
  c = 0
  for i = 1:S.n
    if S.id[i] == C.id
      c = i
      break
    end
  end
  return c
end
findid(S::SeisData, C::SeisChannel) = findid(C, S)

sizeof(S::SeisChannel) = sum([sizeof(getfield(S,f)) for f in enumerate(datafields)]) + sizeof(getfield(S, :notes))
