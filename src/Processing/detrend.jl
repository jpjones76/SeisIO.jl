import Polynomials:polyfit, polyval
export demean!, demean, detrend!, detrend

"""
    demean!(S::SeisData)

Remove the mean from all channels `i` with `S.fs[i] > 0.0`. Specify `irr=true`
to also remove the mean from irregularly sampled channels (with S.fs[i] == 0.0)

Ignores NaNs.
"""
function demean!(S::SeisData; irr::Bool=false)
  @inbounds for i = 1:S.n
    (irr==false && S.fs[i]<=0.0) && continue
    K = findall(isnan.(S.x[i]))
    if isempty(K)
      L = length(S.x[i])
      μ = sum(S.x[i])/Float64(L)
      for j = 1:L
        S.x[i][j] -= μ
      end
    else
      J = findall(isnan.(S.x[i]) .== false)
      L = length(J)
      μ = sum(S.x[i][J])/Float64(L)
      for j in J
        S.x[i][j] -= μ
      end
    end
    note!(S, i, "demean! removed mean of S.x.")
  end
  return nothing
end
demean(S::SeisData) = (U = deepcopy(S); demean!(U); return U)

"""
    detrend!(S::SeisData)

Remove the linear trend from all channels `i` with `S.fs[i] > 0.0`. Ignores NaNs.

Channels of irregularly-sampled data are not (and cannot be) detrended.

**Warning**: detrend! does *not* check for data gaps; if this is problematic,
call ungap!(S, m=true) first!
"""
function detrend!(S::SeisData; n::Int64=1)
  @inbounds for i = 1:S.n
    S.fs[i] ≤ 0.0 && continue
    L = length(S.x[i])
    t = findall((isnan.(S.x[i])).==false)
    if L == length(t)
      p = polyfit(t, S.x[i], n)
      broadcast!(-, S.x[i], S.x[i], polyval(p, 1:L))
    else
      x = S.x[i][t]
      p = polyfit(t, x, n)
      broadcast!(-, x, x, polyval(p, 1:length(x)))
      S.x[i][t] = x
    end
    note!(S, i, string("detrend! removed polynomial trend of degree ", n))
  end
  return nothing
end
detrend(S::SeisData; n::Int64=1) = (U = deepcopy(S); detrend!(U, n=n); return U)
