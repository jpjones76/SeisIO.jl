export demean!, demean, detrend!, detrend

@doc """
    demean!(S::SeisData[; irr=false])

Remove the mean from all channels `i` with `S.fs[i] > 0.0`. Specify `irr=true`
to also remove the mean from irregularly sampled channels (with S.fs[i] == 0.0)

    demean!(C::SeisChannel)

Remove the mean from data in `C`.

Ignores NaNs.
""" demean!
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
    note!(S, i, "demean!")
  end
  return nothing
end

function demean!(C::SeisChannel)
  T = eltype(C.x)
  K = findall(isnan.(C.x))
  if isempty(K)
    L = length(C.x)
    μ = T(sum(C.x) / T(L))
    for j = 1:L
      C.x[j] -= μ
    end
  else
    J = findall(isnan.(C.x) .== false)
    L = length(J)
    μ = T(sum(C.x[J])/T(L))
    for j in J
      C.x[j] -= μ
    end
  end
  note!(C, "demean!")
  return nothing
end

demean!(Ev::SeisEvent) = demean!(Ev.data)

@doc (@doc demean!)
demean(S::SeisData) = (U = deepcopy(S); demean!(U); return U)
demean(C::SeisChannel) = (U = deepcopy(C); demean!(U); return U)
demean(Ev::SeisEvent) = (U = deepcopy(Ev); demean!(U.data); return U)

@doc """
    detrend!(S::SeisData[; n=1, irr=false]))

Remove the linear trend from all channels `i` with `S.fs[i] > 0.0`. Ignores NaNs.

Specify `irr=true` to also remove the trend from irregularly sampled channels.

To remove a higher-order polynomial fit than a linear trend, choose n>1.

    detrend!(C::SeisChanel[; n=1]))

Remove the linear trend from data in `C`. Ignores NaNs.

To remove a higher-order polynomial fit than a linear trend, choose n>1.

!!! warning

    detrend! does *not* check for data gaps; if this is problematic,
call ungap!(S, m=true) first!
""" detrend!
function detrend!(S::SeisData; n::Int64=1, irr::Bool=false)
  @inbounds for i = 1:S.n
    (irr==false && S.fs[i]<=0.0) && continue
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
    note!(S, i, string("detrend!, n = ", n))
  end
  return nothing
end

function detrend!(C::SeisChannel; n::Int64=1)
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
  note!(C, string("detrend!, n = ", n))
  return nothing
end

detrend!(Ev::SeisEvent; n::Int64=1) = detrend!(Ev.data, n=n)

@doc (@doc detrend!)
detrend(S::SeisData; n::Int64=1) = (U = deepcopy(S); detrend!(U, n=n); return U)
detrend(C::SeisChannel; n::Int64=1) = (U = deepcopy(C); detrend!(U, n=n); return U)
detrend(Ev::SeisEvent; n::Int64=1) = (U = deepcopy(Ev); detrend!(U.data, n=n); return U)
