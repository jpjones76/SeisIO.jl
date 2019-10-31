# extensions of merge methods

# Home of all extended merge! methods
merge(S::EventTraceData; v::Int64=KW.v) = (U = deepcopy(S); merge!(U, v=v); return U)
merge!(S::EventTraceData, U::EventTraceData; v::Int64=KW.v) = ([append!(getfield(S, f), getfield(U, f)) for f in tracefields]; S.n += U.n; merge!(S; v=v))
merge!(S::EventTraceData, C::EventChannel; v::Int64=KW.v) = merge!(S, EventTraceData(C), v=v)

function merge(A::Array{EventTraceData,1}; v::Int64=KW.v)
  L::Int64 = length(A)
  n = sum([A[i].n for i = 1:L])
  T = EventTraceData(n)
  [setfield!(T, f, vcat([getfield(A[i],f) for i = 1:L]...)) for f in SeisIO.datafields]
  merge!(T, v=v)
  return T
end
merge(S::EventTraceData, U::EventTraceData; v::Int64=KW.v) = merge(Array{EventTraceData,1}([S,U]), v=v)
merge(S::EventTraceData, C::EventChannel; v::Int64=KW.v) = merge(S, EventTraceData(C), v=v)
merge(C::EventChannel, S::EventTraceData; v::Int64=KW.v) = merge(EventTraceData(C), S, v=v)
merge(C::EventChannel, D::EventChannel; v::Int64=KW.v) = (S = EventTraceData(C,D); merge!(S, v=v); return S)

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
