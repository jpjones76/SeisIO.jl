# extensions of merge methods

# Home of all extended merge! methods
merge(S::EventTraceData; v::Int64=KW.v) = (U = deepcopy(S); merge!(U, v=v); return U)
merge!(S::EventTraceData, U::EventTraceData; v::Int64=KW.v) = ([append!(getfield(S, f), getfield(U, f)) for f in SeisIO.datafields]; S.n += U.n; merge!(S; v=v))
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
merge(C::EventChannel, D::EventChannel; v::Int64=KW.v) = (S = EventTraceData(C,D); merge!(S, v=v))

function mseis!(S...)
  U = Union{SeisData, SeisChannel, SeisEvent, EventTraceData, EventChannel}
  L = Int64(length(S))
  (L < 2) && return
  S1 = getindex(S, 1)
  (typeof(S1) == SeisData) || error("Target must be type SeisData!")
  for i = 2:L
    T = typeof(getindex(S, i))
    if (T <: U) == false
      @warn(string("Object of incompatible type passed to wseis at ", i+1, "; skipped!"))
      continue
    end
    if T == SeisData
      append!(S1, getindex(S, i))
    elseif T == EventTraceData
      append!(S1, convert(SeisData, getindex(S, i)))
    elseif T == SeisChannel
      append!(S1, SeisData(getindex(S, i)))
    elseif T == EventChannel
      append!(S1, SeisData(convert(SeisChannel, getindex(S, i))))
    elseif T == SeisEvent
      append!(S1, convert(SeisData, getfield(getindex(S, i), :data)))
    end
  end
  merge!(S1)
  return S1
end

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
