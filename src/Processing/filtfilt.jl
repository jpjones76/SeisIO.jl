import DSP:filtfilt
export filtfilt, filtfilt!

#=  Regenerate filter; largely identical to DSP.Filters.filt_stepstate with
    some optimization for SeisIO data handling =#
function update_filt(fl::T, fh::T, fs::T, np::Int64, rp::Int, rs::Int, rt::String, dm::String) where T<:Real

  # response type
  if rt == "Highpass"
    ff = Highpass(fl, fs=fs)
  elseif rt == "Lowpass"
    ff = Lowpass(fh, fs=fs)
  else
    ff = getfield(DSP.Filters, Symbol(rt))(fl, fh, fs=fs)
  end

  # design method
  if dm == "Elliptic"
    zp = Elliptic(np, rp, rs)
  elseif dm == "Chebyshev1"
    zp = Chebyshev1(np, rp)
  elseif dm == "Chebyshev2"
    zp = Chebyshev2(np, rs)
  else
    zp = Butterworth(np)
  end

  # polynomial ratio
  pr = convert(PolynomialRatio, digitalfilter(ff, zp))

  # create and scale coeffs
  a = T.(coefa(pr))
  b = T.(coefb(pr))
  scale_factor = a[1]
  (scale_factor == 1.0) || (r = T(1.0/scale_factor); rmul!(a, r); rmul!(b, r))

  # size
  bs = length(b)
  as = length(a)
  sz = max(bs, as)

  # Pad the coefficients with zeros if needed
  bs < sz && (b = copyto!(zeros(T, sz), b))
  as < sz && (a = copyto!(zeros(T, sz), a))

  # construct the companion matrix A and vector B:
  A = [-a[2:sz] [I; zeros(T, 1, sz-2)]]
  B = b[2:sz] - a[2:sz] * b[1]

  # Solve for Z: (I - A)*si = B
  Z = scale_factor \ (I - A) \ B

  p = 3*(sz-1)
  return (b, a, Z, p)
end

#=  Adapted from Julia DSP filtfilt for how SeisIO stores data; X and its
    padded, interpolated version (Y) can be reused until fs or length(x)
    changes =#
function zero_phase_filt!(X::AbstractArray,
                          Y::AbstractArray,
                          b::Array{T,1},
                          a::Array{T,1},
                          zi::Array{T,1},
                          p::Int64) where T<:Real
    nx = length(X)
    z_copy = copy(zi)

    # Extrapolate X into Y
    j = p
    @inbounds for i = 1:nx
      j += 1
      Y[j] = X[i]
    end

    y = 2*first(X)
    j = 2+p
    @inbounds for i = 1:p
      j -= 1
      Y[i] = y - X[j]
    end

    y = 2*X[nx]
    j = nx
    k = nx+p
    @inbounds for i = 1:p
      j -= 1
      k += 1
      Y[k] = y - X[j]
    end

    # Filtering
    reverse!(filt!(Y, b, a, Y, mul!(z_copy, zi, first(Y))))
    filt!(Y, b, a, Y, mul!(z_copy, zi, first(Y)))
    j = length(Y)-p+1
    @inbounds for i = 1:nx
      j -= 1
      X[i] = Y[j]
    end
    return nothing
end

function do_filtfilt!(X::AbstractArray,
                      Y::AbstractArray,
                      yview::AbstractArray,
                      L::Int64,
                      last_L::Int64,
                      b::Array{T,1},
                      a::Array{T,1},
                      zi::Array{T,1},
                      p::Int64) where T<:Real

  too_short::Bool = false
  if L < 3*(2*p) # effecive filter order doubles for a zero-phase filter
    L₀ = L
    L = 6*p
    x = copyto!(zeros(eltype(X), L), X)
    X₀ = X
    X = view(x, :)
    too_short = true
  end

  if L != last_L
    # condition to update filter
    yview = view(Y, 1 : L+2*p)
    last_L = L
  end

  # Zero-phase filter in X using Y
  zero_phase_filt!(X, yview, b, a, zi, p)

  if too_short
    copyto!(X₀, 1, X, 1, L₀)
  end
  return nothing
end

@doc """
  filtfilt!(S::GphysData[; KWs])

Apply zero-phase filter to S.x.

  filtfilt!(C::GphysChannel[; KWs])

Apply zero-phase filter to C.x

Keywords control filtering behavior; specify as e.g. filtfilt!(S, fl=0.1, np=2, rt="Lowpass").

### Keywords

| Name  | Default       | Type    | Description                         |
|:------|:--------------|:--------|:------------------------------------|
| chans | (all)         | [^1]    | channel numbers to filter           |
| fl    | 1.0           | Float64 | lower corner frequency [Hz] [^2]    |
| fh    | 15.0          | Float64 | upper corner frequency [Hz] [^2]    |
| np    | 4             | Int64   | number of poles                     |
| rp    | 10            | Int64   | pass-band ripple (dB)               |
| rs    | 30            | Int64   | stop-band ripple (dB)               |
| rt    | "Bandpass"    | String  | response type (type of filter)      |
| dm    | "Butterworth" | String  | design mode (name of filter)        |

[^1]: Allowed types are Integer, UnitRange, and Array{Int64, 1}.
[^2]: By convention, the lower corner frequency (fl) is used in a Highpass
filter, and fh is used in a Lowpass filter.

See also: DSP.jl documentation
""" filtfilt!
function filtfilt!(S::GphysData;
    chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
    fl::Float64=KW.Filt.fl,
    fh::Float64=KW.Filt.fh,
    np::Int=KW.Filt.np,
    rp::Int=KW.Filt.rp,
    rs::Int=KW.Filt.rs,
    rt::String=KW.Filt.rt,
    dm::String=KW.Filt.dm
    )

  isempty(S) && return nothing
  if chans == Int64[]
    chans = 1:S.n
  end

  N = nx_max(S, chans)

  # Determine array structures
  T = unique([eltype(i) for i in S.x])
  nT = length(T)

  sz = 0
  yy = Any
  for i = 1:nT
    zz = sizeof(T[i])
    if zz > sz
      yy = T[i]
      sz = zz
    end
  end
  b, a, zi, p = update_filt(yy(fl), yy(fh), yy(maximum(S.fs)), np, rp, rs, rt, dm)
  Y = Array{yy,1}(undef, max(N, 6*p) + 2*p) # right value for Butterworth

  # Get groups
  GRPS = get_unique(S, ["fs", "eltype"], chans)

  for grp in GRPS

    # get fs, eltype
    c = grp[1]
    ty = eltype(S.x[c])
    fs = ty(S.fs[c])

    # reinterpret Y if needed
    if ty != eltype(Y)
      Y = reinterpret(ty, isa(Y, Base.ReinterpretArray) ? Y.parent : Y)
    end

    # Get views and window lengths of each segment
    (L,X) = get_views(S, grp)
    nL = length(L)

    # Initialize filter
    b, a, zi, p = update_filt(ty(fl), ty(fh), fs, np, rp, rs, rt, dm)

    # Place the first copy outside the loop as we expect many cases where nL=1
    nx = first(L)
    yview = view(Y, 1 : nx+2*p)

    # Use nx_last to track changes
    nx_last = nx

    # Loop over (rest of) views
    for i = 1:nL
      do_filtfilt!(X[i], Y, yview, L[i], nx_last, b, a, zi, p)
    end

    notestr = string("filtfilt!, fl = ", fl,
                              ", fh = ", fh,
                              ", np = ", np,
                              ", rp = ", rp,
                              ", rs = ", rs,
                              ", rt = ", rt,
                              ", dm = ", dm)
    note!(S, grp, notestr)
  end
  return nothing
end

function filtfilt!(C::GphysChannel;
  fl::Float64=KW.Filt.fl,
  fh::Float64=KW.Filt.fh,
  np::Int=KW.Filt.np,
  rp::Int=KW.Filt.rp,
  rs::Int=KW.Filt.rs,
  rt::String=KW.Filt.rt,
  dm::String=KW.Filt.dm
  )

  N = nx_max(C)

  # Determine array structures
  ty = eltype(C.x)

  # Initialize filter
  b, a, zi, p = update_filt(ty(fl), ty(fh), ty(C.fs), np, rp, rs, rt, dm)
  Y = Array{ty,1}(undef, max(N, 6*p) + 2*p)

  # Get views
  if size(C.t,1) == 2
    L = length(C.x)
    do_filtfilt!(C.x, Y, view(Y,1:L+2*p), L, L, b, a, zi, p)
  else
    (L,X) = get_views(C)
    nL = length(L)
    nx = first(L)
    yview = view(Y, 1 : nx+2*p)

    # Use nx_last to track changes
    nx_last = nx

    # Loop over (rest of) views
    for i = 1:nL
      do_filtfilt!(X[i], Y, yview, L[i], nx_last, b, a, zi, p)
    end
  end
  notestr = string("filtfilt!, fl = ", fl,
                            ", fh = ", fh,
                            ", np = ", np,
                            ", rp = ", rp,
                            ", rs = ", rs,
                            ", rt = ", rt,
                            ", dm = ", dm)
  note!(C, notestr)
  return nothing
end

@doc (@doc filtfilt!)
filtfilt(S::GphysData;
  fl::Float64=KW.Filt.fl,
  fh::Float64=KW.Filt.fh,
  np::Int=KW.Filt.np,
  rp::Int=KW.Filt.rp,
  rs::Int=KW.Filt.rs,
  rt::String=KW.Filt.rt,
  dm::String=KW.Filt.dm
  ) = (
        U = deepcopy(S);
        filtfilt!(U, fl=fl, fh=fh, np=np, rp=rp, rs=rs, rt=rt, dm=dm);
        return U
       )

filtfilt(C::GphysChannel;
  fl::Float64=KW.Filt.fl,
  fh::Float64=KW.Filt.fh,
  np::Int=KW.Filt.np,
  rp::Int=KW.Filt.rp,
  rs::Int=KW.Filt.rs,
  rt::String=KW.Filt.rt,
  dm::String=KW.Filt.dm
  ) = (
        D = deepcopy(C);
        filtfilt!(D, fl=fl, fh=fh, np=np, rp=rp, rs=rs, rt=rt, dm=dm);
        return D
       )
