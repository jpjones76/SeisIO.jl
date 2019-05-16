convert(::Type{EventTraceData}, C::EventChannel) = EventTraceData(C)
convert(::Type{SeisData}, C::SeisChannel) = SeisData(C)

function convert(::Type{EventTraceData}, S::SeisData)
  TD = EventTraceData(getfield(S, :n))
  for f in datafields
    if (f in unindexed_fields) == false
      setfield!(TD, f, deepcopy(getfield(S, f)))
    end
  end
  return TD
end

function convert(::Type{SeisData}, TD::EventTraceData)
  S = SeisData(getfield(TD, :n))
  for f in datafields
    if (f in unindexed_fields) == false
      setfield!(S, f, deepcopy(getfield(TD, f)))
    end
  end
  return S
end

function convert(::Type{SeisChannel}, D::EventChannel)
  C = SeisChannel()
  for f in datafields
    setfield!(C, f, deepcopy(getfield(D, f)))
  end
  return C
end

function convert(::Type{EventChannel}, C::SeisChannel)
  D = EventChannel()
  for f in datafields
    setfield!(D, f, deepcopy(getfield(C, f)))
  end
  return D
end
