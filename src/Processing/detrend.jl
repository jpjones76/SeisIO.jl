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

function dtr!(x::Array{T,1}, ti::Array{Int64,2}, fs::Float64, n::Int64) where T <: AbstractFloat
  L = length(x)

  # check for nans
  nf = false
  for i = 1:length(x)
    if isnan(x[i])
      nf = true
      break
    end
  end

  if nf
    t = tx_float(ti, fs)
    j = findall((isnan.(x)).==false)
    x1 = x[j]
    t1 = t[j]
    p = n == 1 ? linreg(t1, x1) : polyfit(t1, x1, n)
  else
    if n == 1 && size(ti,1) == 2 && fs > 0.0
      dt = 1.0/fs
      p = linreg(x, dt)
      v = zero(T)
      for i = 1:length(x)
        v = polyval(p, dt*i)
        x[i] -= v
      end
    else
      t = tx_float(ti, fs)
      p = n == 1 ? linreg(t, x) : polyfit(t, x, n)
      v = zero(T)
      for i = 1:length(x)
        v = polyval(p, t[i])
        x[i] -= v
      end
    end
  end
  return p
end

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

  @inbounds for i in chans
    p = dtr!(S.x[i], S.t[i], S.fs[i], n)
    note!(S, i, string("detrend!, n = ", n, ", polyfit result = ", p))
  end
  return nothing
end

function detrend!(C::GphysChannel; n::Int64=1)
  p = dtr!(C.x, C.t, C.fs, n)
  note!(C, string("detrend!, n = ", n, ", polyfit result = ", p))
  return nothing
end

@doc (@doc detrend!)
detrend(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  n::Int64=1) = (U = deepcopy(S); detrend!(U, chans=chans, n=n); return U)
detrend(C::GphysChannel; n::Int64=1) = (U = deepcopy(C); detrend!(U, n=n); return U)
