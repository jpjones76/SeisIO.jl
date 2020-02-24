# extension of merge to EventTraceData fields
function merge_ext!(S::EventTraceData, Ω::Int64, rest::Array{Int64, 1})
  pha   = PhaseCat()
  az    = getindex(getfield(S, :az), Ω)
  baz   = getindex(getfield(S, :baz), Ω)
  dist  = getindex(getfield(S, :dist), Ω)
  for i in rest
    if az == 0.0
      θ = getindex(getfield(S, :az), i)
      (θ != 0.0) && (az = θ)
    end
    if baz == 0.0
      β = getindex(getfield(S, :baz), i)
      (β != 0.0) && (baz = β)
    end
    if dist == 0.0
      # Δ is already in use, so...
      d = getindex(getfield(S, :dist), i)
      (d != 0.0) && (dist = d)
    end
    merge!(pha, getindex(getfield(S, :pha), i))
  end
  # This guarantees that the phase catalog of Ω overwrites others
  merge!(pha, getindex(getfield(S, :pha), Ω))
  setindex!(getfield(S, :az),     az, Ω)
  setindex!(getfield(S, :baz),   baz, Ω)
  setindex!(getfield(S, :dist), dist, Ω)
  setindex!(getfield(S, :pha),   pha, Ω)
  return nothing
end

# Home of all extended merge! methods
merge(S::EventTraceData; v::Integer=KW.v) = (U = deepcopy(S); merge!(U, v=v); return U)
merge!(S::EventTraceData, U::EventTraceData; v::Integer=KW.v) = ([append!(getfield(S, f), getfield(U, f)) for f in tracefields]; S.n += U.n; merge!(S; v=v))
merge!(S::EventTraceData, C::EventChannel; v::Integer=KW.v) = merge!(S, EventTraceData(C), v=v)

function merge(A::Array{EventTraceData,1}; v::Integer=KW.v)
  L::Int64 = length(A)
  n = sum([A[i].n for i = 1:L])
  T = EventTraceData(n)
  [setfield!(T, f, vcat([getfield(A[i],f) for i = 1:L]...)) for f in SeisIO.datafields]
  merge!(T, v=v)
  return T
end
merge(S::EventTraceData, U::EventTraceData; v::Integer=KW.v) = merge(Array{EventTraceData,1}([S,U]), v=v)
merge(S::EventTraceData, C::EventChannel; v::Integer=KW.v) = merge(S, EventTraceData(C), v=v)
merge(C::EventChannel, S::EventTraceData; v::Integer=KW.v) = merge(EventTraceData(C), S, v=v)
merge(C::EventChannel, D::EventChannel; v::Integer=KW.v) = (S = EventTraceData(C,D); merge!(S, v=v); return S)

+(S::EventTraceData, C::EventChannel) = +(S, EventTraceData(C))
+(C::EventChannel, S::EventTraceData) = +(S, EventTraceData(C))
+(C::EventChannel, D::EventChannel) = +(EventTraceData(C), EventTraceData(D))

# Multiplication
# distributivity: (S1+S2)*S3) == (S1*S3 + S2*S3)
*(S::EventTraceData, U::EventTraceData) = merge(Array{EventTraceData,1}([S,U]))
*(S::EventTraceData, C::EventChannel) = merge(S, EventTraceData(C))
function *(C::EventChannel, D::EventChannel)
  s1 = deepcopy(C)
  s2 = deepcopy(D)
  S = merge(EventTraceData(s1),EventTraceData(s2))
  return S
end
