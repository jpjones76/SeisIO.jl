import DSP.resample
export resample, resample!

function mkresample(rate::T) where T<:Real
  r = rationalize(rate)
  h = T.(resample_filter(r))
  ff = FIRFilter(h, r)
  τ = timedelay(ff)
  setphase!(ff, τ)
  return ff
end

@doc """
    resample!(S::SeisData [, chans=CC, fs=FS])
    resample(S::SeisData [, chans=CC, fs=FS])

Resample data in S to `FS`. If keyword `fs` is not specified, data are resampled
to the lowest non-zero value in `S.fs[CC]`.Note that a poor choice of `FS` can
lead to upsampling and other undesirable behavior.

Use keyword `chans=CC` to only resample channel numbers `CC`. By default, all
channels `i` with `S.fs[i] > 0.0` are resampled.

    resample!(C::SeisChannel, fs::Float64)
    resample(C::SeisChannel, fs::Float64)

Resample `C.x` to `fs`.
""" resample!
function resample!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  fs::Float64=0.0)

  if chans == Int64[]
    chans = 1:S.n
  end

  f0 = fs == 0.0 ? minimum(S.fs[chans[S.fs[chans] .> 0.0]]) : fs

  # This setup is very similar to filtfilt!
  N = nx_max(S)
  T = unique([eltype(i) for i in S.x[chans]])
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
  Y = Array{yy,1}(undef, N+1)
  Z = similar(Y)

  # Get groups
  GRPS = get_unique(S, ["fs", "eltype"], chans)
  i = GRPS[1][1]
  ty = eltype(S.x[i])
  fs = ty(S.fs[i])
  j = 1
  while isapprox(fs, f0)
    j += 1
    j > length(GRPS) && return nothing
    i = GRPS[j][1]
    fs = ty(S.fs[i])
  end
  ff = mkresample(ty(f0/fs))
  rate_old = f0/fs
  si::Int = 0
  ei::Int = 0

  for grp in GRPS
    # get fs, eltype
    c = grp[1]
    ty = eltype(S.x[c])
    fs = ty(S.fs[c])
    fs == f0 && continue
    rate = f0/fs

    # update rate, filter
    if rate != rate_old || ty != eltype(Y)
      ff = mkresample(ty(f0/fs))
      rate_old = rate
    end

    # reinterpret Y if needed
    if ty != eltype(Y)
      Y = reinterpret(ty, isa(Y, Base.ReinterpretArray) ? Y.parent : Y)
      Z = reinterpret(ty, isa(Z, Base.ReinterpretArray) ? Z.parent : Z)
    end

    # Here, things change. We loop in reverse over each segment in each
    # element of grp
    for i in grp
      n_seg = size(S.t[i],1)-1
      gap_inds = Array{Int64,1}(undef, n_seg+1)
      gap_inds[1] = 1
      for k = n_seg:-1:1
        si            = S.t[i][k,1]
        ei            = S.t[i][k+1,1] - (k == n_seg ? 0 : 1)

        # determine boundaries
        nx_in         = ei-si+1
        nx_out        = ceil(Int, nx_in*rate)
        nz_out        = inputlength(ff, nx_out)

        # create padded version of this segment of S.x[i]
        if nz_out > length(Z)
          append!(Z, zeros(ty, nz_out-length(Z)))
        end
        copyto!(Z, 1, S.x[i], si, nx_in)
        if nz_out > nx_in
          Z[nx_in+1:nz_out] = zeros(ty, nz_out-nx_in)
        end
        n_out          = outputlength(ff, nz_out)

        # basically the filt() call in DSP.jl/stream_filt.jl
        ybuf           = view(Y, 1 : n_out)
        ny             = filt!(ybuf, ff, Z[1:nz_out])
        copyto!(S.x[i], si, Y, 1, ny)
        deleteat!(S.x[i], si+ny:ei)
        gap_inds[k+1]  = ceil(Int, ei*rate)
      end
      copyto!(S.t[i], 1, gap_inds, 1, n_seg+1)
      setindex!(S.fs, f0, i)
      note!(S, i, string("resample!, fs=", repr("text/plain", f0, context=:compact=>true)))
    end
  end
  return nothing
end

function resample!(C::GphysChannel, f0::Float64)
  C.fs > 0.0 || error("Can't resample non-timeseries data!")
  (C.fs == f0) && return nothing
  @assert f0 > 0.0

  # This setup is very similar to filtfilt!
  N = nx_max(C)
  ty = eltype(C.x)
  Y = Array{ty,1}(undef, N+1)
  Z = similar(Y)
  rate = f0/C.fs
  ff = mkresample(rate)

  if size(C.t,1) == 2
    nx_in         = length(C.x)
    nx_out        = ceil(Int, nx_in*rate)
    nz_out        = inputlength(ff, nx_out)
    if nz_out > length(Z)
      append!(Z, zeros(ty, nz_out-length(Z)))
    end
    copyto!(Z, 1, C.x, 1, nx_in)
    if nz_out > nx_in
      Z[nx_in+1:nz_out] = zeros(ty, nz_out-nx_in)
    end
    n_out          = outputlength(ff, nz_out)
    ybuf           = view(Y, 1 : n_out)
    ny             = filt!(ybuf, ff, Z[1:nz_out])
    copyto!(C.x, 1, Y, 1, ny)
    deleteat!(C.x, ny+1:nx_in)
  else
    n_seg           = size(C.t, 1)-1
    gap_inds        = ones(Int64, n_seg+1)
    for k = n_seg:-1:1
      si            = C.t[k,1]
      ei            = C.t[k+1,1] - (k == n_seg ? 0 : 1)

      # determine boundaries
      nx_in         = ei-si+1
      nx_out        = ceil(Int, nx_in*rate)
      nz_out        = inputlength(ff, nx_out)

      # create padded version of this segment of C.x
      if nz_out > length(Z)
        append!(Z, zeros(ty, nz_out-length(Z)))
      end
      copyto!(Z, 1, C.x, si, nx_in)
      if nz_out > nx_in
        Z[nx_in+1:nz_out] = zeros(ty, nz_out-nx_in)
      end
      n_out          = outputlength(ff, nz_out)

      # basically the filt() call in DSP.jl/stream_filt.jl
      ybuf           = view(Y, 1 : n_out)
      ny             = filt!(ybuf, ff, Z[1:nz_out])
      copyto!(C.x, si, Y, 1, ny)
      deleteat!(C.x, si+ny:ei)
      gap_inds[k+1]  = ceil(Int, ei*rate)
    end
    copyto!(C.t, 1, gap_inds, 1, n_seg+1)
  end
  setfield!(C, :fs, f0)
  note!(C, string("resample!, fs=", repr("text/plain", f0, context=:compact=>true)))
  return nothing
end

@doc (@doc resample!)
function resample(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  fs::Float64=0.0)

  U = deepcopy(S)
  resample!(U, chans=chans, fs=fs)
  return U
end

function resample(C::GphysChannel, f0::Float64)
  U = deepcopy(C)
  resample!(U, f0)
  return U
end
