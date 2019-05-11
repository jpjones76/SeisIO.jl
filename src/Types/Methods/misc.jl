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

function EventTraceData(U...)
  TD = EventTraceData()
  for i = 1:length(U)
    Y = getindex(U,i)
    if typeof(Y) == SeisChannel
      push!(TD, convert(EventChannel, Y))
    elseif typeof(Y) == EventChannel
      push!(TD, Y)
    elseif typeof(Y) == SeisData
      append!(TD, convert(EventTraceData, Y))
    elseif typeof(Y) == SeisEvent
      append!(TD, getfield(Y, :data))
    elseif typeof(Y) == EventTraceData
      append!(TD, Y)
    else
      @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
    end
  end
  return TD
end
