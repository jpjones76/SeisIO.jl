# The cumbersome manual rewrite (incl. lifted code from Julia DSP) reduces memory
# consumption by an order of magnitude.

"""
    env!(S::SeisData)

In-place conversion to smoothed envelopes of S.x[i], ∀i : S.fs[i]>0.0. See `?env` for keyword list.

*Warnings*
* Overwrites existing S.x.
* Currently always calls ungap!(S); avoid use on data with long time gaps.
"""
function env!(S::SeisData; sync::Bool=false, edge::Float64=1.0, fl::Float64=1.0, fh::Float64=15.0, smooth::Bool=true, nk::Int64=25)
    if sync
        sync!(S)
    else
        ungap!(S)
    end

    # Build an array of indices to traces, sorted by trace length in descending order
    λ = Array{Int64,1}(S.n)
    for i=1:1:S.n
        λ[i] = length(S.x[i])
    end
    L = unique(λ)
    sort!(L, rev=true)
    nL = length(L)

    # Start with arrays initialized to the largest size we need; downscale from here
    nx = L[1]
    m = div(nx, 2) + (isodd(nx) ? 1 : 0)

    # Arrays to hold data and windows
    X = Array{Float64,1}(nx)
    H = Array{Complex{Float64},1}(nx)
    U = Array{Float64,1}(nx)
    P = plan_rfft(X)

    # Trackers for changes
    fs = maximum(S.fs[find(λ.==L[1])])
    fs_last = fs
    nx_last = nx

    # Filter and window alpha
    b, a, zi, p = SeisIO.update_filt(fl, fh, fs)
    Y = Array{Float64,1}(nx+2*p)
    α = 2.0*edge*fs_last/L[1]
    if edge > 0.0
        tuk!(U, α)
    end

    # Create Hanning window
    if smooth
        hf = DSP.hanning(nk)
        scale!(hf, 0.5/sum(hf))
        kf = DSP.ZeroPoleGain(Float64[], hf, 1.0)
        pr = DSP.PolynomialRatio(kf)
        ka = coefa(pr)
        kb = coefb(pr)
        lp, kz = my_stepstate(kb, ka)
        kp = 3*(lp-1)
        YS = Array{Float64,1}(nx+2*kp)
    end

    for i = 1:nL
        # Skip channels that are uninitialized or contain irregularly sampled data
        isapprox(L[i], 0.0) && continue

        J = find(λ.==L[i])
        F = S.fs[J]
        k = sortperm(F)
        J = J[k]
        if i > 1
            nx = L[i]
            m = div(nx, 2) + (isodd(nx) ? 1 : 0)
            resize!(X, nx)
            resize!(H, nx)
            P = plan_rfft(X)
        end

        for j in J
            # Remove mean
            fs = S.fs[j]
            unsafe_copy!(X, 1, S.x[j], 1, nx)
            μ = mean(X)
            broadcast!(-, X, X, μ)

            # Update Hilbert vector, filter, Tukey window
            if nx != nx_last || fs == fs_last
                # Tukey
                if edge > 0.0
                    resize!(U, nx)
                    α = 2.0*edge*fs/nx
                    tuk!(U, α)
                end

                # Filter
                if fs != fs_last
                    b, a, zi, p = SeisIO.update_filt(fl, fh, fs)
                end
                resize!(Y, nx+2*p)

                if smooth
                    resize!(YS, nx+2*kp)
                end
            end

            # Tukey window if edge > 0.0
            if edge > 0.0
                broadcast!(*, X, X, U)
            end

            # Zero-phase filter
            SeisIO.filtfilt!(X, Y, b, a, zi, p)

            #  Compute envelope → adapted from DSP.hilbert for recycled H
            A_mul_B!(view(H, 1:(nx >> 1)+1), P, X)
            @inbounds for n = 2:m
                H[n] *= 2.0
            end
            @inbounds for n = m+1:nx
                H[n] = zero(Complex{Float64})
            end
            ifft!(H)
            broadcast!(abs, X, H)

            # Smooth if flagged
            if smooth
                SeisIO.filtfilt!(X, YS, kb, ka, kz, kp)
            end
            unsafe_copy!(S.x[j], 1, X, 1, nx)

            # Update fs_last
            fs_last = fs
        end
        # Update nx_last
        nx_last = nx
    end
    return nothing
end

"""
    T = env(S::SeisData)

Convert time-series data in S.x[i]. T.x[i] contains the envelope of S.x[i].

| kw    | Type      | Default       | Meaning                               |
|:----  |:-----     | :-----        |:--------                              |
| smooth| Bool      | true          | Smooth envelopes with Kalman filter?  |
| sync  | Bool      | False         | Call sync! before conversion?         |
| edge  | Float64   | 1.0           | Window `edge` seconds at edge of S.x  |
|       |           |               |   Set edge=0.0 for no windowing       |
| fl    | Float64   | 1.0           | Low corner frequency (Hz)             |
| fh    | Float64   | 1.0           | High corner frequency (Hz)            |
| nk    | Int64     | 25            | Length of Kalman filter (samples)     |

*Warning:* Always at least calls ungap! on S.
"""
function env(S::SeisData; sync::Bool=false, edge::Float64=1.0, fl::Float64=1.0, fh::Float64=15.0, smooth::Bool=true, nk::Int64=25)
    U = deepcopy(S)
    env!(U, sync=sync, edge=edge, fl=fl, fh=fh, smooth=smooth, nk=nk)
    return U
end

function tuk!(W::Array{Float64,1}, α::Float64)
    α = min(1.0, max(α, 0.0))
    fill!(W, 1.0)
    n = length(W)
    m = α*(n-1)/2.0
    if m > 0.0
        M = round(Int64, m)
        @inbounds for k = 0:M
            W[k+1] = 0.5*(1.0 + cos(pi*(k/m - 1.0)))
        end
        @inbounds for k = n-M-1:n-1
            W[k+1] = 0.5*(1.0 + cos(pi*(k/m - 2.0/α + 1.0)))
        end
    end
    return nothing
end

# ============================================================================
# Adapted from Julia DSP for how SeisIO stores data
# Takes advantage of the concept that X and its padded, interpolated version (Y) can be
# reused until S.fs[i] or length(S.x[i]) changes + always uses Float64
function filtfilt!(X::Array{Float64,1}, Y::Array{Float64,1}, b::Array{Float64,1}, a::Array{Float64,1}, zi::Array{Float64,1}, p::Int64)
    nx = length(X)
    zi0 = copy(zi)

    # Extrapolate X into Y
    unsafe_copy!(Y, p+1, X, 1, nx)
    y = 2*X[1]
    @inbounds for i = 1:p
        Y[i] = y - X[2+p-i]
    end
    y = 2*X[nx]
    @inbounds for i = 1:p
        Y[nx+p+i] = y - X[nx-i]
    end

    # Filtering
    reverse!(filt!(Y, b, a, Y, scale!(zi0, zi, Y[1])))
    filt!(Y, b, a, Y, scale!(zi0, zi, Y[1]))
    reverse!(Y)
    unsafe_copy!(X, 1, Y, p+1, nx)
    return nothing
end

# Only Float64! Only Khlav Khalash! (Nearly identical to DSP.Filters.filt_stepstate)
function my_stepstate(b::Vector{Float64}, a::Vector{Float64})
    scale_factor = a[1]
    if a[1] != 1.0
        r = 1.0/a[1]
        scale!(a, r)
        scale!(b, r)
    end

    bs = length(b)
    as = length(a)
    sz = max(bs, as)
    sz > 0 || error("a and b must have at least one element each")
    sz == 1 && return Float64[]

    # Pad the coefficients with zeros if needed
    bs<sz && (b = copy!(zeros(Float64, sz), b))
    as<sz && (a = copy!(zeros(Float64, sz), a))

    # construct the companion matrix A and vector B:
    A = [-a[2:sz] [eye(Float64, sz-2); zeros(Float64, 1, sz-2)]]
    B = b[2:sz] - a[2:sz] * b[1]
    # Solve si = A*si + B
    # (I - A)*si = B
    return sz, scale_factor \ (I - A) \ B
 end

# Recalculate filtering variables
function update_filt(fl::Float64, fh::Float64, fs::Float64)
    pr = convert(PolynomialRatio, DSP.digitalfilter(DSP.Filters.Bandpass(fl, fh; fs=fs), DSP.Filters.Butterworth(4)))
    a = coefa(pr)
    b = coefb(pr)
    (L, Z) = SeisIO.my_stepstate(b, a)
    p = 3*(L-1)
    return (b, a, Z, p)
end

 # ***
 # Here, S is a SeisData container with 90s of 100 Hz data on 21 channels
 # U = deepcopy(S)
 # @allocated ugly_env!(U): 13894384
 # @allocated env!(S): 634112
 #
 # function ugly_env!(S::SeisData; sync::Bool=false, edge::Float64=1.0, fl::Float64=1.0, fh::Float64=15.0, smooth::Bool=true, nk::Int64=25)
 #     if sync
 #         sync!(S)
 #     end
 #
 #     if smooth
 #         hf = DSP.hanning(nk)
 #         scale!(hf, 0.5/sum(hf))
 #         kf = DSP.ZeroPoleGain(Float64[], hf, 1.0)
 #     end
 #
 #     for i = 1:S.n
 #         # Skip channels that are uninitialized or contain irregularly sampled data
 #         S.fs[i] == 0.0 && continue
 #         nx = length(S.x[i])
 #         nx == 0.0 && continue
 #
 #         # Remove mean
 #         broadcast!(-, S.x[i], S.x[i], mean(S.x[i]))
 #
 #         # Tukey window
 #         if edge > 0.0
 #             broadcast!(*, S.x[i], S.x[i], DSP.tukey(nx, 2.0*edge*S.fs[i]/nx))
 #         end
 #
 #         # Zero-phase filter
 #         ff = digitalfilter(Bandpass(fl, fh; fs=S.fs[i]), Butterworth(4))
 #         X = filtfilt(ff, S.x[i])
 #
 #         # Envelope
 #         X = abs.(DSP.hilbert(X))
 #
 #         # Smoothing
 #         if smooth
 #             S.x[i] = DSP.filtfilt(kf, X)
 #         else
 #             unsafe_copy!(S.x[i], 1, X, 1, nx)
 #         end
 #     end
 #     return nothing
 # end
