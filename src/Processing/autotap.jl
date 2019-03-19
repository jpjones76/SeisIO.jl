export autotap!

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
