function SeisData(U...)
  S = SeisData()
  for i = 1:length(U)
    Y = getindex(U,i)
    if typeof(Y) == SeisChannel
      push!(S, Y)
    elseif typeof(Y) == SeisData
      append!(S, Y)
    elseif typeof(Y) == SeisEvent
      append!(S, convert(SeisData, getfield(Y, :data)))
    else
      @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
    end
  end
  return S
end
