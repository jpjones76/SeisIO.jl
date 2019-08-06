export unscale, unscale!

@doc """
    unscale!(S::GphysData[, chans=CC, irr=false])

Divide out the gains of all channels `i` where `S.fs[i] > 0.0`. Specify
`irr=true` to also remove the gains of irregularly-sampled channels. Use keyword
`chans=CC` to only resample channel numbers `CC`.

""" unscale!
function unscale!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  irr::Bool=false)

  if chans == Int64[]
    chans = 1:S.n
  end

  @inbounds for i = 1:S.n
    (irr==false && S.fs[i]<=0.0) && continue
    if (S.gain[i] != 1.0) && (i in chans)
      T = eltype(S.x[i])
      rmul!(S.x[i], T(1.0/S.gain[i]))
      note!(S, i, @sprintf("unscale!, gain = %.3e", S.gain[i]))
      S.gain[i] = 1.0
    end
  end
  return nothing
end
unscale!(C::GphysChannel) = (rmul!(C.x, eltype(C.x)(1.0/C.gain)); C.gain = 1.0)

@doc (@doc unscale!)
function unscale(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  irr::Bool=false)

  U = deepcopy(S)
  unscale!(U, chans=chans, irr=irr)
  return U
end
function unscale(C::GphysChannel; irr::Bool=false)
  U = deepcopy(C)
  rmul!(U.x, eltype(C.x)(1.0/U.gain))
  U.gain = 1.0
  return U
end
