convert(::Type{EventTraceData}, C::EventChannel) = EventTraceData(C)

function convert(::Type{EventTraceData}, S::T) where T <:  GphysData
  (T == EventTraceData) && (return deepcopy(S))
  if T != SeisData
    S = convert(SeisData, S)
  end
  TD = EventTraceData(getfield(S, :n))
  for f in datafields
    if (f in unindexed_fields) == false
      setfield!(TD, f, deepcopy(getfield(S, f)))
    end
  end
  return TD
end
EventTraceData(S::T) where T <: GphysData = convert(EventTraceData, S)

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

function convert(::Type{EventChannel}, C::T) where T <: GphysChannel
  (T == EventChannel) && (return deepcopy(C))
  if T != SeisChannel
    S = convert(SeisChannel, S)
  end
  D = EventChannel()
  for f in datafields
    setfield!(D, f, deepcopy(getfield(C, f)))
  end
  return D
end
EventChannel(C::T) where T <: GphysChannel = convert(EventChannel, C)

function unsafe_convert(::Type{SeisData}, TD::EventTraceData)
  S = SeisData(getfield(TD, :n))
  for f in datafields
    if (f in unindexed_fields) == false
      setfield!(S, f, getfield(TD, f))
    end
  end
  return S
end

function unsafe_convert(::Type{EventTraceData}, S::SeisData)
  TD = EventTraceData(getfield(S, :n))
  for f in datafields
    if (f in unindexed_fields) == false
      setfield!(TD, f, getfield(S, f))
    end
  end
  return TD
end

push!(TD::EventTraceData, C::SeisChannel) = push!(TD, convert(EventChannel, C))
