export autotap!, unscale!

"""
    unscale!(S::SeisData)

Divide out the gains of all channels `i` : `S.fs[i] > 0.0`. Specify `all=true`
to also remove the gain of irregularly-sampled channels (i.e., channels `i` : `S.fs[i] == 0.0`)

"""
function unscale!(S::SeisData; all::Bool=false)
  @inbounds for i = 1:S.n
    (all==false && S.fs[i]<=0.0) && continue
    if S.gain[i] != 1.0
      rmul!(S.x[i], 1.0/S.gain[i])
      note!(S, i, @sprintf("unscale! divided S.x by old gain %.3e", S.gain[i]))
      S.gain[i] = 1.0
    end
  end
  return nothing
end

"""
    autotap!(S::SeisData)

Cosine taper data in channel `S.x[i]` around time gaps in `S.t[i]` and fill all gaps with the mean of `S.x[i]`.
"""
function autotap!(U::SeisData)
  # Fill gaps with NaNs
  ungap!(U, m=false, w=false)

  for i = 1:U.n
    (U.fs[i] == 0 || isempty(U.x[i])) && continue
    J = findall((isnan.(U.x[i])).==false)
    μ = mean(U.x[i][J])
    u = max(20, round(Int64, 0.2*U.fs[i]))

    # Check for NaNs and window around them
    autotuk!(U.x[i], J, u)

    # Then replace NaNs with the mean
    J = findall(isnan.(U.x[i]))
    if !isempty(J)
      U.x[i][J] .= μ
      note!(U, i, "autotap! tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
    else
      note!(U, i, "autotap! tapered and ungapped data.")
    end
  end
  return nothing
end

"""
    !autotap(U::SeisChannel)

Automatically cosine taper (Tukey window) all segments in `U` around time gaps, and fill all gaps with `mean(U.x)`.
"""
function autotap!(U::SeisChannel)
  (U.fs == 0 || isempty(U.x)) && return

  # Fill time gaps with NaNs
  ungap!(U, m=false, w=false)

  j = findall(isnan.(U.x).==false)
  μ = mean(U.x[j])
  u = max(20, round(Int64, 0.2*U.fs))

  # Then check for NaNs
  autotuk!(U.x, j, u)

  # Then replace NaNs with the mean
  U.x[isnan.(U.x)] .= μ
  note!(U, "autotap! tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
  return nothing
end
