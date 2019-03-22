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
    T = eltype(S.x[i])
    K = findall(isnan.(S.x[i]))
    if isempty(K)
      L = length(S.x[i])
      μ = T(sum(S.x[i]) / T(L))
      for j = 1:L
        S.x[i][j] -= μ
      end
    else
      J = findall(isnan.(S.x[i]) .== false)
      L = length(J)
      μ = T(sum(S.x[i][J])/T(L))
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
    T = eltype(S.x[i])
    τ = T.(t_expand(S.t[i], S.fs[i])) .- S.t[i][1,2]
    j = findall((isnan.(S.x[i])).==false)
    if L == length(j)
      p = polyfit(τ, S.x[i], n)
      broadcast!(-, S.x[i], S.x[i], polyval(p, τ))
    else
      x = S.x[i][j]
      p = polyfit(τ[j], x, n)
      broadcast!(-, x, x, polyval(p, τ[j]))
      S.x[i][j] = x
    end
    note!(S, i, string("detrend! removed polynomial trend of degree ", n))
  end
  return nothing
end
detrend(S::SeisData; n::Int64=1) = (U = deepcopy(S); detrend!(U, n=n); return U)
