export unscale, unscale!

@doc """
    unscale!(S::GphysData[, chans=CC, irr=false])

Divide out the gains of all channels `i` where `S.fs[i] > 0.0`. Specify
`irr=true` to also remove the gains of irregularly-sampled channels. Use keyword
`chans=CC` to only resample channel numbers `CC`.

""" unscale!
function unscale!(S::GphysData;
  chans::ChanSpec=Int64[],
  irr::Bool=false)

  if chans == Int64[]
    chans = 1:S.n
  end

  proc_str = string("unscale!(S, chans=", chans, ")")

  @inbounds for i = 1:S.n
    (irr==false && S.fs[i]<=0.0) && continue
    if (S.gain[i] != 1.0) && (i in chans)
      T = eltype(S.x[i])
      rmul!(S.x[i], T(1.0/S.gain[i]))
      proc_note!(S, i, proc_str, string("divided out gain = ", repr(S.gain[i], context=:compact=>true)))
      S.gain[i] = 1.0
    end
  end
  return nothing
end
function unscale!(C::GphysChannel)
  rmul!(C.x, eltype(C.x)(1.0/C.gain))
  proc_note!(C, "unscale!(C)", string("divided out gain = ", repr(C.gain, context=:compact=>true)))
  C.gain = 1.0
  return nothing
end

@doc (@doc unscale!)
function unscale(S::GphysData;
  chans::ChanSpec=Int64[],
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
