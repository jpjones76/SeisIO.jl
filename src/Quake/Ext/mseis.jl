"""
    mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures at once.

See also: merge!
"""
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

+(C::EventChannel, D::EventChannel) = +(EventTraceData(C), EventTraceData(D))
+(S::EventTraceData, C::EventChannel) = +(S, EventTraceData(C))
+(C::EventChannel, S::EventTraceData) = +(S, EventTraceData(C))

# Multiplication
# distributivity: (S1+S2)*S3) == (S1*S3 + S2*S3)
*(S::EventTraceData, U::EventTraceData) = merge(Array{GphysData,1}([S,U]))
*(S::EventTraceData, C::EventChannel) = merge(S, EventTraceData(C))
function *(C::EventChannel, D::EventChannel)
  s1 = deepcopy(C)
  s2 = deepcopy(D)
  S = merge(EventTraceData(s1),EventTraceData(s2))
  return S
end
