export demean!, demean, detrend!, detrend

"""
    demean!(C::SeisChannel)

Remove the mean from channels `C` with `C.fs > 0.0`. Specify `irr=true`
to also remove the mean from irregularly sampled channels (with C.fs == 0.0)

Ignores NaNs.
"""
function demean!(C::SeisChannel; irr::Bool=false)
    (irr==false && C.fs<=0.0) && return Nothing
    T = eltype(C.x)
    K = findall(isnan.(C.x))
    if isempty(K)
      L = length(C.x)
      μ = T(sum(C.x) / T(L))
      for i = 1:L
        C.x[i] -= μ
      end
    else
      J = findall(isnan.(C.x) .== false)
      L = length(J)
      μ = T(sum(C.x[J])/T(L))
      for j in J
        C.x[j] -= μ
      end
    end
  return nothing
end
demean(C::SeisChannel) = (U = deepcopy(C); demean!(U); return U)

"""
    demean!(S::SeisData)

Remove the mean from all channels `i` with `S.fs[i] > 0.0`. Specify `irr=true`
to also remove the mean from irregularly sampled channels (with S.fs[i] == 0.0)

Ignores NaNs.
"""
function demean!(S::SeisData; irr::Bool=false)
  @inbounds for i = 1:S.n
    demean!(S[i])
    note!(S, i, "demean! removed mean of S.x.")
  end
  return nothing
end
demean(S::SeisData) = (U = deepcopy(S); demean!(U); return U)

"""
    detrend!(C::SeisChannel)

Remove the linear trend from channels `C` with `C.fs > 0.0`. Ignores NaNs.

Channels of irregularly-sampled data are not (and cannot be) detrended.
"""
function detrend!(C::SeisChannel; n::Int64=1)
  C.fs ≤ 0.0 && return nothing
  L = length(C.x)
  T = eltype(C.x)
  τ = T.(t_expand(C.t, C.fs)) .- C.t[1,2]
  j = findall((isnan.(C.x)).==false)
  if L == length(j)
    p = polyfit(τ, C.x, n)
    broadcast!(-, C.x, C.x, polyval(p, τ))
  else
    x = C.x[j]
    p = polyfit(τ[j], x, n)
    broadcast!(-, x, x, polyval(p, τ[j]))
    C.x[j] = x
  end
  return nothing
end
detrend(C::SeisChannel; n::Int64=1) = (U = deepcopy(C); detrend!(U, n=n); return U)

"""
    detrend!(S::SeisData)

Remove the linear trend from all channels `i` with `S.fs[i] > 0.0`. Ignores NaNs.

Channels of irregularly-sampled data are not (and cannot be) detrended.

**Warning**: detrend! does *not* check for data gaps; if this is problematic,
call ungap!(S, m=true) first!
"""
function detrend!(S::SeisData; n::Int64=1)
  @inbounds for i = 1:S.n
    detrend!(S[i], n=n)
    note!(S, i, string("detrend! removed polynomial trend of degree ", n))
  end
  return nothing
end
detrend(S::SeisData; n::Int64=1) = (U = deepcopy(S); detrend!(U, n=n); return U)
