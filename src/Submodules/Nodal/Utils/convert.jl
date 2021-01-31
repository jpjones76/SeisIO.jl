function convert(::Type{NodalData}, S::T) where T <: GphysData
  (T == NodalData) && (return deepcopy(S))
  @assert minimum(S.fs) == maximum(S.fs)
  if T != SeisData
    S = convert(SeisData, S)
  end
  sync!(S, s="last", t="first")

  L = [length(i) for i in S.x]
  L0 = minimum(L)
  @assert L0 == maximum(L)

  # clear everything from buffer TDMS
  reset_tdms()

  ts = S.t[1][1,2]
  data = Array{Float32, 2}(undef, L0, S.n)
  for i in 1:S.n
    data[:, i] .= S.x[i]
  end
  TD = NodalData(data, TDMS.hdr, 1:S.n, ts)
  for f in convertible_fields
    setfield!(TD, f, deepcopy(getfield(S, f)))
  end
  return TD
end
NodalData(S::T) where T <: GphysData = convert(NodalData, S)

function convert(::Type{SeisData}, TD::NodalData)
  S = SeisData(getfield(TD, :n))
  nx = size(TD.data, 1)

  # convertible_fields plus :t are directly copied
  for f in convertible_fields
    setfield!(S, f, deepcopy(getfield(TD, f)))
  end
  setfield!(S, :t, deepcopy(getfield(TD, :t)))

  # :x is set by copying from :data, to prevent GC problems if TD is cleared
  for i in 1:S.n
    S.x[i] = copy(TD.data[:, i])
  end
  return S
end

function convert(::Type{SeisChannel}, D::NodalChannel)
  C = SeisChannel()
  for f in datafields
    setfield!(C, f, deepcopy(getfield(D, f)))
  end
  return C
end

function convert(::Type{NodalChannel}, C::T) where T<:GphysChannel
  (T == NodalChannel) && (return deepcopy(C))
  if T != SeisChannel
    C = convert(SeisChannel, C)
  end

  D = NodalChannel()
  for f in datafields
    setfield!(D, f, deepcopy(getfield(C, f)))
  end
  return D
end
NodalChannel(C::T) where T <: GphysChannel = convert(NodalChannel, C)

push!(TD::NodalData, C::SeisChannel) = push!(TD, convert(NodalChannel, C))
