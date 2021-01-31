export rescale, rescale!

@doc """
  rescale!(S::GphysData, g::Float64; chans=CC)
  rescale(S, g; chans=CC)

Rescale all channels of S to gain `g`. By default, all channels are rescaled.

  rescale!(S::GphysData; c=c, chans=CC)
  rescale(S; c=c, chans=CC)

Change `S` to use `S.gain[c]` for all channels. Rescales data as needed. By default, `c=1`.

  rescale!(St::GphysData, Ss::GphysData)
  rescale(St, Ss)

Rescale data in `St.x` to `Ss.gain` using channel ID matching; also changes `St.gain`.

  rescale!(C::GphysChannel, g::Float64)
  rescale(C, g)

Rescale `C.x` to gain `g` and set `C.gain = g`.

  rescale!(Ct::GphysChannel, Cs::GphysChannel)
  rescale(Ct, Cs)

Rescale data in `Ct.x` to `Cs.gain` and change `Ct.gain`. ID fields must match.

"""
function rescale!(S::GphysData, gain::Float64; chans::ChanSpec=Int64[])
  CC    = mkchans(chans, S, keepirr=false)
  GAIN  = getfield(S, :gain)
  X     = getfield(S, :x)
  for i in CC
    T = eltype(X[i])
    scalefac = T(gain / getindex(GAIN, i))
    if scalefac != one(T)
      rmul!(getindex(X, i), scalefac)
    end
    GAIN[i] = gain
  end
  return nothing
end
function rescale!(S_targ::GphysData, S_src::GphysData)
  N   = getfield(S_targ, :n)
  IT  = getfield(S_targ, :id)
  IS  = getfield(S_src,  :id)
  GT  = getfield(S_targ, :gain)
  GS  = getfield(S_src,  :gain)
  X   = getfield(S_targ, :x)
  for i in 1:N
    id = getindex(IT, i)
    j  = findid(id, IS)
    (j == 0) && continue
    g_new = getindex(GS, j)
    g_old = getindex(GT, i)
    if isapprox(g_new, g_old) == false
      x = getindex(X, i)
      T = eltype(x)
      rmul!(x, T(g_new/g_old))
      GT[i] = g_new
    end
  end
  return nothing
end
rescale!(S::GphysData; c::Int=1, chans::ChanSpec=Int64[]) = rescale!(S, S.gain[c], chans=chans)
function rescale!(Ct::GphysChannel, Cs::GphysChannel)
  (Ct.id == Cs.id) || error("ID mismatch!")
  gt = Ct.gain
  gs = Cs.gain
  if gt != gs
    T = eltype(Ct.x)
    rmul!(Ct.x, T(gs/gt))
    Ct.gain = gs
  end
  return nothing
end
function rescale!(C::GphysChannel, gt::Float64)
  gs = C.gain
  if gs != gt
    T = eltype(C.x)
    rmul!(C.x, T(gs/gt))
    C.gain = gt
  end
  return nothing
end

@doc (@doc rescale!)
function rescale(S::GphysData, gain::Float64; chans::ChanSpec=Int64[])
  U = deepcopy(S)
  rescale!(U, gain, chans=chans)
  return U
end
function rescale(S_targ::GphysData, S_src::GphysData)
  U = deepcopy(S_targ)
  rescale!(U, S_src)
  return U
end
function rescale(S::GphysData; c::Int=1, chans::ChanSpec=Int64[])
  U = deepcopy(S)
  rescale!(U, U.gain[c], chans=chans)
  return U
end
function rescale(Ct::GphysChannel, Cs::GphysChannel)
  U = deepcopy(Ct)
  rescale!(U, Cs)
  return U
end
rescale(C::GphysChannel, g::Float64) = (U = deepcopy(C); rescale!(U, g); return U)
