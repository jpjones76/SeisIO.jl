export env!, env

@doc """
    env!(S::GphysData[, chans=CC, smooth=false, v=V, nk=NK])
    env(S::GphysData)

In-place conversion of S.x[i] ==> Env(S.x[i]) (≡ |H(S.x[i])|, where H denotes
the Hilbert transform).

### Keywords
* chans=CC: only process channels in CC (with fs > 0.0).
* smooth=false: set to `true` to smooth the signal envelope by applying a zero-phase Kalman filter.
* v=V: verbosity.
* nk=NK: number of samples in Kalman filter.
""" env!
function env!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  smooth::Bool=false,
  v::Int64=KW.v,
  nk::Int64=32
  )

  # preprocess data channels
  chans = mkchans(chans, S.n)
  k = Int64[]
  for c in chans
    if S.fs[c] == 0.0
      push!(k, c)
    end
  end
  deleteat!(chans, k)

  # Get groups
  GRPS = get_unique(S, ["eltype"], chans=chans)

  # Initialize Y
  Y = Array{Float64,1}(undef, 2*nx_max(S))

  # Arrays to hold data and windows
  @inbounds for grp in GRPS
    c = grp[1]
    T = eltype(S.x[c])
    R = reinterpret(Complex{T}, Y)

    # Get views and window lengths of each segment
    c2 = T(2)
    (L, X) = get_views(S, grp)
    nL = length(L)
    nx = L[1]

    # Create Hanning window
    if smooth
      hf = T.(DSP.hanning(nk))
      rmul!(hf, T(0.5)/T(sum(hf)))
      ka = SeisIO.poly(hf)
      kb = [one(T)]
      scf = ka[1]
      if scf != one(T)
        c = one(T)/scf
        broadcast!(*, ka, ka, c)
        broadcast!(*, kb, kb, c)
      end

      # solve for kz
      as = length(ka)
      b = zeros(T, as)
      b[1] = kb[1]
      A = [-ka[2:as] [I; zeros(T, 1, as-2)]]
      B = b[2:as] - ka[2:as] * b[1]
      kz = scf \ (I - A) \ B

      # determine np
      np = 3*(as-1)

      # create "smoothed X" placeholder YS
      YS = Array{T,1}(undef, nx + 2*np)
    end

    n2 = div(nx, 2)
    H = view(R, 1:nx)
    v1 = view(R, 1:n2 + 1)
    v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
    v3 = view(R, n2+1:nx)
    P = plan_rfft(X[1])
    nx_last = nx
    np = 0

    for i = 1:nL
      nx = L[i]
      x = X[i]

      # determine whether to update P, YS
      too_short = false
      # update P, nx, YS
      if nx < 24 || nx != nx_last
        # very short segments
        if nx < 24
          y = zeros(eltype(x), 24)
          copyto!(y, 1, X[i], 1, nx)
          X₀ = y
          nx₀ = nx
          x = view(y, :)
          too_short = true
          nx = length(x)
        end
        if smooth
          resize!(YS, nx + 2*np)
        end
        P = plan_rfft(x)
        n2 = div(nx, 2)
        H = view(R, 1:nx)
        v1 = view(R, 1:n2 + 1)
        v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
        v3 = view(R, n2+1:nx)
      end

      #  Compute envelope → adapted from DSP.hilbert for recycled H
      fill!(v3, zero(Complex{T}))
      mul!(v1, P, x)
      broadcast!(*, v2, v2, c2)
      ifft!(H)

      # overwrite x
      if too_short
        copyto!(X[i], 1, x, 1, nx₀)
      else
        broadcast!(abs, x, H)
      end

      # Kalman filtering (smoothing)
      if smooth
        zero_phase_filt!(x, YS, kb, ka, kz, np)
      end

      # update nx_last
      nx_last = nx
    end
  end
  return nothing
end

function env!(C::GphysChannel;
  smooth::Bool=false,
  v::Int64=KW.v,
  nk::Int64=32
  )

  C.fs == 0.0 && return

  # Arrays to hold data and windows
  if size(C.t, 1) == 1
    C.x .= abs.(DSP.hilbert(C.x))
  else
    # Initialize R
    T = eltype(C.x)
    R = Array{Complex{T}, 1}(undef, nx_max(C))

    # Get views and window lengths of each segment
    c2 = T(2)
    (L, X) = get_views(C)
    nL = length(L)
    nx = L[1]
    n2 = div(nx, 2)
    H = view(R, 1:nx)
    v1 = view(R, 1:n2 + 1)
    v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
    v3 = view(R, n2+1:nx)
    P = plan_rfft(X[1])
    nx_last = nx
    np = 0

    # Create Hanning window
    if smooth == true
      hf = T.(DSP.hanning(nk))
      rmul!(hf, T(0.5)/T(sum(hf)))
      ka = SeisIO.poly(hf)
      kb = [one(T)]
      scf = ka[1]
      if scf != one(T)
        c = one(T)/scf
        broadcast!(*, ka, ka, c)
        broadcast!(*, kb, kb, c)
      end

      # solve for kz
      as = length(ka)
      b = zeros(T, as)
      b[1] = kb[1]
      A = [-ka[2:as] [I; zeros(T, 1, as-2)]]
      B = b[2:as] - ka[2:as] * b[1]
      kz = scf \ (I - A) \ B

      # determine np
      np = 3*(as-1)

      # create "smoothed X" placeholder YS
      YS = Array{T,1}(undef, nx + 2*np)
    end

    for i = 1:nL
      nx = L[i]
      x = X[i]

      # determine whether to update P, YS
      too_short = false
      # update P, nx, YS
      if nx < 24 || nx != nx_last
        # very short segments
        if nx < 24
          y = copyto!(zeros(eltype(x), 24), x)
          X₀ = y
          nx₀ = nx
          nx = 24
          x = view(y, :)
          too_short = true
        end
        P = plan_rfft(x)
        if smooth == true
          resize!(YS, nx + 2*np)
        end
        n2 = div(nx, 2)
        H = view(R, 1:nx)
        v1 = view(R, 1:n2 + 1)
        v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
        v3 = view(R, n2+1:nx)
      end

      #  Compute envelope → adapted from DSP.hilbert for recycled H
      fill!(v3, zero(Complex{T}))
      mul!(v1, P, x)
      broadcast!(*, v2, v2, c2)
      ifft!(H)

      # overwrite x
      if too_short
        copyto!(X[i], 1, x, 1, nx₀)
      else
        broadcast!(abs, x, H)
      end

      # Kalman filtering (smoothing)
      if smooth == true
        SeisIO.zero_phase_filt!(x, YS, kb, ka, kz, np)
      end

      # update nx_last
      nx_last = nx
    end
  end
  return nothing
end

@doc (@doc env!)
function env(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  smooth::Bool=false,
  v::Int64=KW.v,
  nk::Int64=32
  )

  U = deepcopy(S)
  env!(U, chans=chans, smooth=smooth, v=v, nk=nk)
  return U
end

function env(C::GphysChannel;
  smooth::Bool=false,
  v::Int64=KW.v,
  nk::Int64=32
  )

  U = deepcopy(C)
  env!(U, smooth=smooth, v=v, nk=nk)
  return U
end
