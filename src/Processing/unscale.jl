export unscale, unscale!

@doc """
    unscale!(S::GphysData)

Divide out the gains of all channels `i` : `S.fs[i] > 0.0`. Specify `all=true`
to also remove the gain of irregularly-sampled channels (i.e., channels `i` : `S.fs[i] == 0.0`)

""" unscale!
function unscale!(S::GphysData; irr::Bool=false)
  @inbounds for i = 1:S.n
    (irr==false && S.fs[i]<=0.0) && continue
    if S.gain[i] != 1.0
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
function unscale(S::GphysData; irr::Bool=false)
  U = deepcopy(S)
  unscale!(U, irr=irr)
  return U
end
function unscale(C::GphysChannel; irr::Bool=false)
  U = deepcopy(C)
  rmul!(U.x, eltype(C.x)(1.0/U.gain))
  U.gain = 1.0
  return U
end
