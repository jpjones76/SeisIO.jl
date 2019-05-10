export taper, taper!

# Create increasing part of a cosine taper
function mktaper!(W::Array{T,1}, L::Int64) where T<:Real
  LL = 2*L
  pp = 2.0*pi
  @inbounds for i = 1:L
    W[i] = 0.5*(1.0 - cos(pp*((i-1)/LL)))
  end
  return nothing
end

# Apply taper W to both ends of X
function taper_seg!(X::AbstractVector, W::Array{T,1}, L::Int64, μ::T; rev::Bool=false) where T<:Real
  if rev == true
    j = L
    @inbounds for i = 1:L
      X[j] = (X[j]-μ)*W[i] + μ
      j -= 1
    end
  else
    @inbounds for i = 1:L
      X[i] = (X[i]-μ)*W[i] + μ
    end
  end
  return nothing
end

# Taper a GphysChannel
@doc """
    taper!(C[; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10])

Cosine taper all time-series data in C. Tapers each segment of each channel
that contains at least `N_min` total samples.

    taper!(S[; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10])

Cosine taper all time-series data in S. Tapers each segment of each channel
that contains at least `N_min` total samples.

Does not modify irregularly-sampled data channels.

Keywords:
* `N_min`: Data segments with N < N_min total samples are not tapered.
* `t_max`: Maximum taper edge in seconds.
* `α``: Taper edge area; as for a Tukey window, the first and last 100*α% of
samples in each window are tapered, up to `t_max` seconds of data.

See also: DSP.Windows.tukey
""" taper!
function taper!(C::GphysChannel; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10)
  if !(C.fs > 0.0)
    return nothing
  end
  N_min = max(div(N_min,2), 0)
  # detrend!(C)

  # Reserve a window of length t_max*C.fs for the taper
  L = round(Int, t_max*C.fs)
  T = eltype(C.x)
  W = Array{T,1}(undef, L)

  # Determine window lengths of all segments
  window_lengths = diff(C.t[:,1])
  window_lengths[end] += 1
  n_seg = length(window_lengths)
  N_max = maximum(window_lengths)

  # Sanity check, with requirement α ≤ 0.5
  L_max = round(Int, t_max*C.fs)
  α = min(α, 0.5)
  L = min(L, round(Int, N_max*α))
  mktaper!(W, L)
  μ = T(mean(C.x))

  # Begin tapering by segment
  if n_seg == 1
    Nx = length(C.x)
    Xl = view(C.x, 1:L)
    Xr = view(C.x, Nx-L+1:Nx)
    taper_seg!(Xl, W, L, μ)
    taper_seg!(Xr, W, L, μ, rev=true)

  else
    # Get taper lengths and segment indices
    si = copy(C.t[1:n_seg, 1])
    ei = copy(C.t[2:n_seg, 1]).-1
    push!(ei, C.t[end,1])

    ii = sortperm(window_lengths, rev=true)
    si = si[ii]
    ei = ei[ii]
    Lw = window_lengths[ii]

    for i = 1:n_seg
      s = si[i]
      t = ei[i]
      L_tap = Lw[i]
      L_tap < N_min && break

      if L_tap < L
        L = min(L_max, round(Int, L_tap*α))
        resize!(W, L)
        mktaper!(W, L)
      end

      X = view(C.x, s:t)
      μ = T(sum(X)/(t-s+1))
      Xl = view(C.x, s:s+L-1)
      Xr = view(C.x, t-L+1:t)
      taper_seg!(Xl, W, L, μ)
      taper_seg!(Xr, W, L, μ, rev=true)
    end
  end
  note!(C,  string( "taper!, ",
                    "t_max = ", t_max, ", ",
                    "α = ", α,  ", ",
                    "N_min = ", N_min ) )
  return nothing
end

# This approach leads to heinous-looking code but uses virtually no memory.
# I could probably clean it up by creating one master taper
# and passing/editing views into the taper.

function taper!(S::GphysData; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10)
  if !any(getfield(S, :fs) .> 0.0)
    return nothing
  end

  α = min(α, 0.5)
  N_min = max(div(N_min,2), 0)
  T = unique([eltype(i) for i in S.x])
  nT = length(T)
  N_max = zeros(Int64, nT)

  # Arrays of views for each data type; we'll store these and lengths L_taps
  means = Array{Union{[Array{ty,1} for ty in T]...},1}(undef, nT)
  L_taps = Array{Array{Int64,1},1}(undef, nT)
  Xl = Array{Array{SubArray,1},1}(undef, nT)
  Xr = similar(Xl)
  for j = 1:nT
    Xl[j] = Array{SubArray{T[j],1,Array{T[j],1},Tuple{StepRange{Int64,Int64}},true},1}(undef,0)
    Xr[j] = similar(Xl[j])
    L_taps[j] = Array{Int64,1}(undef, 0)
    means[j] = Array{T[j],1}(undef, 0)
  end

  # Loop over channels, pushing views to the appropriate view array for eltype(S.x[i])
  for i = 1:S.n
    S.fs[i] <= 0.0 && continue
    j = findfirst(T.==eltype(S.x[i]))

    # Compute length
    window_lengths = diff(S.t[i][:,1])
    window_lengths[end] += 1
    n_seg = length(window_lengths)

    # Get taper lengths and segment indices
    L_max = round(Int, t_max*S.fs[i])
    L_seg = min.(L_max, round.(Int, window_lengths*α))
    si = copy(S.t[i][1:n_seg, 1])
    ei = copy(S.t[i][2:n_seg, 1]).-1
    push!(ei, S.t[i][end,1])
    μ = T[j](mean(S.x[i]))

    for k = 1:length(L_seg)
      push!(Xl[j], view(S.x[i], si[k]:si[k]+L_seg[k]-1))
      push!(Xr[j], view(S.x[i], ei[k]-L_seg[k]+1:ei[k]))
      push!(means[j], μ)
      N_max[j] = max(N_max[j], L_seg[k])
    end
    append!(L_taps[j], L_seg)
  end

  # Loop over data type
  for j = 1:nT
    L = N_max[j]
    W = Array{T[j],1}(undef, L)
    mktaper!(W, L)

    ii = sortperm(L_taps[j], rev=true)
    Nw = L_taps[j][ii]
    Xl[j] = Xl[j][ii]
    Xr[j] = Xr[j][ii]
    means[j] = means[j][ii]

    # Loop over left & right X-views
    for k = 1:length(Nw)
      Nw[k] < N_min && break
      # Note here: "break", not "continue", because we've sorted in reverse
      # order; once our taper regions become shorter than N_min, we're done.
      if Nw[k] < L
        L = Nw[k]
        resize!(W, L)
        mktaper!(W, L)
      end
      taper_seg!(Xl[j][k], W, L, means[j][k])
      taper_seg!(Xr[j][k], W, L, means[j][k], rev=true)
    end
  end

  # Annotate
  for i = 1:S.n
    S.fs[i] == 0.0 && continue
    note!(S, i, string( "taper!, ",
                        "t_max = ", t_max, ", ",
                        "α = ", α,  ", ",
                        "N_min = ", N_min ) )
  end
  return nothing
end
taper!(V::SeisEvent;
        t_max::Real=10.0,
        α::Real=0.05,
        N_min::Int64=10) = taper!(V.data, t_max = t_max, α=α, N_min=N_min)

@doc (@doc taper!)
function taper(C::GphysChannel; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10)
  U = deepcopy(C)
  taper!(U, t_max = t_max, α=α, N_min=N_min)
  return U
end
function taper(S::GphysData; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10)
  U = deepcopy(S)
  taper!(U, t_max = t_max, α=α, N_min=N_min)
  return U
end
function taper(V::SeisEvent; t_max::Real=10.0, α::Real=0.05, N_min::Int64=10)
  U = deepcopy(V)
  taper!(U.data, t_max = t_max, α=α, N_min=N_min)
  return U
end
