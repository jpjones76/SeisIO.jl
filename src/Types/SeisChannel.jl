import Base:in, +, -, convert, isequal, length, merge!, merge, push!, sizeof

type SeisChannel
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
            name=""::String,
            id=""::String,
            loc=zeros(Float64,5)::Array{Float64,1},
            fs=0.0::Float64,
            gain=1.0::Float64,
            resp=Array{Complex{Float64},2}(0,2)::Array{Complex{Float64},2},
            units=""::String,
            src=""::String,
            misc=Dict{String,Any}()::Dict{String,Any},
            notes=Array{String,1}()::Array{String,1},
            t=Array{Int64,2}(0,2)::Array{Int64,2},
            x=Array{Float64,1}(0)::Array{Float64,1}
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
pull(S::SeisData, i::Integer) = (T = deepcopy(getindex(S, i)); deleteat!(S,i);
  note!(T,String("Extracted from a SeisData object")); return T)


# ============================================================================
# Annotation
note!(S::SeisChannel, s::String) = push!(S.notes, tnote(s))

# Conversion to and merge with SeisData
function SeisData(C::SeisChannel)
  S = SeisData(1)
  [setfield!(S, f, Array{fieldtype(SeisChannel,f),1}([getfield(C,f)])) for f in datafields]
  return S
end
convert(::Type{SeisData}, C::SeisChannel) = SeisData(C)
merge!(S::SeisData, C::SeisChannel) = merge!(S,SeisData(C))
merge!(C::SeisChannel, S::SeisData) = merge!(SeisData(C),S)
merge!(C::SeisChannel, D::SeisChannel) = (S = SeisData(C); merge!(S, SeisData(D)); return S);
push!(S::SeisData, C::SeisChannel) = merge!(S, SeisData(C))
+(S::SeisData, C::SeisChannel) = merge!(S,C)
+(C::SeisChannel, D::SeisChannel) = merge!(C,D)
findid(S::SeisData, C::SeisChannel) = findfirst(S.id .== C.id)
findid(C::SeisChannel, S::SeisData) = findfirst(S,C)

sizeof(S::SeisChannel) = sum([sizeof(getfield(S,f)) for f in enumerate(datafields)]) + sizeof(getfield(S, :notes))
