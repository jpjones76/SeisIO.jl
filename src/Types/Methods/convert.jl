convert(::Type{EventTraceData}, C::EventChannel) = EventTraceData(C)
convert(::Type{SeisData}, C::SeisChannel) = SeisData(C)

function convert(::Type{EventTraceData}, S::SeisData)
  TD = EventTraceData(getfield(S, :n))
  F = fieldnames(SeisData)
  for f in F
    if (f in unindexed_fields) == false
      setfield!(TD, f, deepcopy(getfield(S, f)))
    end
  end
  return TD
end

function convert(::Type{SeisData}, TD::EventTraceData)
  S = SeisData(getfield(TD, :n))
  F = fieldnames(SeisData)
  for f in F
    if (f in unindexed_fields) == false
      setfield!(S, f, deepcopy(getfield(TD, f)))
    end
  end
  return S
end
