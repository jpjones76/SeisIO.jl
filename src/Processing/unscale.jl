export unscale, unscale!

@doc """
    unscale!(S::SeisData)

Divide out the gains of all channels `i` : `S.fs[i] > 0.0`. Specify `all=true`
to also remove the gain of irregularly-sampled channels (i.e., channels `i` : `S.fs[i] == 0.0`)

""" unscale!
function unscale!(S::SeisData; irr::Bool=false)
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
unscale!(C::SeisChannel) = (C.x .= C.x.*(1.0/C.gain); C.gain = 1.0)
unscale!(V::SeisEvent; irr::Bool=false) = unscale!(V.data, irr=irr)

@doc (@doc unscale!)
function unscale(S::SeisData; irr::Bool=false)
  U = deepcopy(S)
  unscale!(U, irr=irr)
  return U
end
function unscale(C::SeisChannel; irr::Bool=false)
  U = deepcopy(C)
  U.x .= U.x.*(1.0/U.gain)
  U.gain = 1.0
  return U
end
function unscale(V::SeisEvent; irr::Bool=false)
  U = deepcopy(V)
  unscale!(U.data, irr=irr)
  return U
end
