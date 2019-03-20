import Base:in, +, -, *, convert, isempty, isequal, length, push!, sizeof
export SeisChannel

mutable struct SeisChannel
  name  ::String
  id    ::String
  loc   ::Array{Float64,1}
  fs    ::Float64
  gain  ::Float64
  resp  ::Array{Complex{Float64},2}
  units ::String
  src   ::String
  misc  ::Dict{String,Any}
  notes ::Array{String,1}
  t     ::Array{Int64,2}
  x     ::Union{Array{Float64,1},Array{Float32,1}}

  function SeisChannel(
      name  ::String,
      id    ::String,
      loc   ::Array{Float64,1},
      fs    ::Float64,
      gain  ::Float64,
      resp  ::Array{Complex{Float64},2},
      units ::String,
      src   ::String,
      misc  ::Dict{String,Any},
      notes ::Array{String,1},
      t     ::Array{Int64,2},
      x     ::Union{Array{Float64,1}, Array{Float32,1}}
      )

      return new(name, id, loc, fs, gain, resp, units, src, misc, notes, t, x)
    end
end

# Are keywords type-stable now?
SeisChannel(;
            name  ::String                    = "",
            id    ::String                    = "",
            loc   ::Array{Float64,1}          = Array{Float64,1}(undef, 0),
            fs    ::Float64                   = zero(Float64),
            gain  ::Float64                   = one(Float64),
            resp  ::Array{Complex{Float64},2} = Array{Complex{Float64},2}(undef, 0, 2),
            units ::String                    = "",
            src   ::String                    = "",
            misc  ::Dict{String,Any}          = Dict{String,Any}(),
            notes ::Array{String,1}           = Array{String,1}(undef, 0),
            t     ::Array{Int64,2}            = Array{Int64,2}(undef, 0, 2),
            x     ::Union{Array{Float64,1}, Array{Float32,1}}          = Array{Float32,1}(undef, 0)
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

isempty(Ch::SeisChannel) = minimum([isempty(getfield(Ch,f)) for f in datafields])

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
+(S::SeisData, C::SeisChannel) = (deepcopy(S) + SeisData(C))
+(C::SeisChannel, S::SeisData) = (SeisData(C) + deepcopy(S))
+(C::SeisChannel, D::SeisChannel) = SeisData(C,D)

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
findid(C::SeisChannel, S::SeisData) = findid(C.id, S)
findid(S::SeisData, C::SeisChannel) = findid(C, S)

function sizeof(Ch::SeisChannel)
  s = sum([sizeof(getfield(Ch,f)) for f in datafields])
  if !isempty(Ch.notes)
    s += sum([sizeof(i) for i in Ch.notes])
  end
  if !isempty(Ch.misc)
    s += sum([sizeof(i) for i in values(Ch.misc)])
  end
  return s
end

namestrip!(C::SeisChannel) = namestrip(C.name)
