export demean!, demean, detrend!, detrend

@doc """
    demean!(S::SeisData[; chans=CC, irr=false])

Remove the mean from all channels `i` with `S.fs[i] > 0.0`. Specify `irr=true`
to also remove the mean from irregularly sampled channels (with S.fs[i] == 0.0).
Specifying a channel list with `chans=CC` restricts processing to channels CC.

    demean!(C::SeisChannel)

Remove the mean from data in `C`.

Ignores NaNs.
""" demean!
function demean!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  irr::Bool=false)

  if chans == Int64[]
    chans = 1:S.n
  end

  @inbounds for i = 1:S.n
    if i in chans
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
  end
  return nothing
end

function demean!(C::GphysChannel)
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

@doc (@doc demean!)
demean(S::GphysData,
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  irr::Bool=false) = (U = deepcopy(S); demean!(U, chans=chans, irr=irr); return U)
demean(C::GphysChannel) = (U = deepcopy(C); demean!(U); return U)

@doc """
    detrend!(S::SeisData[; chans=CC, n=1]))

Remove the linear trend from channels `CC`. Ignores NaNs.

To remove a higher-order polynomial fit than a linear trend, choose `n` >1.

    detrend!(C::SeisChanel[; n=1]))

Remove the linear trend from data in `C`. Ignores NaNs.

To remove a higher-order polynomial fit than a linear trend, choose n>1.

!!! warning

    detrend! does *not* check for data gaps; if this is problematic, call ungap!(S, m=true) first!
""" detrend!
function detrend!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  n::Int64=1)

  if chans == Int64[]
    chans = 1:S.n
  end

  @inbounds for i = 1:S.n
    if i in chans
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
  end
  return nothing
end

function detrend!(C::GphysChannel; n::Int64=1)
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

@doc (@doc detrend!)
detrend(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  n::Int64=1) = (U = deepcopy(S); detrend!(U, chans=chans, n=n); return U)
detrend(C::GphysChannel; n::Int64=1) = (U = deepcopy(C); detrend!(U, n=n); return U)
