export autotap!

"""
    autotap!(S::SeisData)

Cosine taper data in channel `S.x[i]` around time gaps in `S.t[i]` and fill all gaps with the mean of `S.x[i]`.
"""
function autotap!(S::SeisData)
  # Fill gaps with NaNs
  ungap!(S, m=false, w=false)

  for i = 1:S.n
    (S.fs[i] == 0 || isempty(S.x[i])) && continue
    T = eltype(S.x[i])
    J = findall((isnan.(S.x[i])).==false)
    μ = T(mean(S.x[i][J]))
    u = max(20, round(Int64, 0.2*S.fs[i]))

    # Check for NaNs and window around them
    autotuk!(S.x[i], J, u)

    # Then replace NaNs with the mean
    J = findall(isnan.(S.x[i]))
    if !isempty(J)
      S.x[i][J] .= μ
      note!(S, i, "autotap! tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
    else
      note!(S, i, "autotap! tapered and ungapped data.")
    end
  end
  return nothing
end

"""
    !autotap(U::SeisChannel)

Automatically cosine taper (Tukey window) all segments in `U` around time gaps, and fill all gaps with `mean(U.x)`.
"""
function autotap!(Ch::SeisChannel)
  (Ch.fs == 0 || isempty(Ch.x)) && return
  T = eltype(Ch.x)

  # Fill time gaps with NaNs
  ungap!(Ch, m=false, w=false)

  j = findall(isnan.(Ch.x).==false)
  μ = T(mean(Ch.x[j]))
  u = max(20, round(Int64, 0.2*Ch.fs))

  # Then check for NaNs
  autotuk!(Ch.x, j, u)

  # Then replace NaNs with the mean
  Ch.x[isnan.(Ch.x)] .= μ
  note!(Ch, "autotap! tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
  return nothing
end
