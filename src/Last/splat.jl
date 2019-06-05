function SeisData(U...)
  S = SeisData()
  for i = 1:length(U)
    Y = getindex(U,i)
    if typeof(Y) == SeisChannel
      push!(S, Y)
    elseif typeof(Y) == EventChannel
        push!(S, convert(SeisChannel, Y))
    elseif typeof(Y) == SeisData
      append!(S, Y)
    elseif typeof(Y) == EventTraceData
      append!(S, convert(SeisData, Y))
    elseif typeof(Y) == SeisEvent
      append!(S, convert(SeisData, getfield(Y, :data)))
    else
      @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
    end
  end
  return S
end

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
