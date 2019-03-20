export unscale!

"""
    unscale!(S::SeisData)

Divide out the gains of all channels `i` : `S.fs[i] > 0.0`. Specify `all=true`
to also remove the gain of irregularly-sampled channels (i.e., channels `i` : `S.fs[i] == 0.0`)

"""
function unscale!(S::SeisData; all::Bool=false)
  @inbounds for i = 1:S.n
    (all==false && S.fs[i]<=0.0) && continue
    if S.gain[i] != 1.0
      T = eltype(S.x[i])
      rmul!(S.x[i], T(1.0/S.gain[i]))
      note!(S, i, @sprintf("unscale! divided S.x by old gain %.3e", S.gain[i]))
      S.gain[i] = 1.0
    end
  end
  return nothing
end
