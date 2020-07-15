function convert(::Type{NodalData}, S::SeisData)
  @assert minimum(S.fs) == maximum(S.fs)
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
  TD = NodalData(data, TDMS.hdr, ts)
  for f in convertible_fields
    setfield!(TD, f, deepcopy(getfield(S, f)))
  end
  return TD
end

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

function convert(::Type{NodalChannel}, C::SeisChannel)
  D = NodalChannel()
  for f in datafields
    setfield!(D, f, deepcopy(getfield(C, f)))
  end
  return D
end

push!(TD::NodalData, C::SeisChannel) = push!(TD, convert(NodalChannel, C))
