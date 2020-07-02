import DSP.resample
export resample, resample!

function cheap_resample!(t::Array{Int64, 2}, x::FloatArray, fs_new::Float64, fs_old::Float64)
  r = fs_new/fs_old
  n_seg = size(t,1)-1
  gap_inds = zeros(Int64, n_seg+1)

  # resize S.x if we're upsampling
  if (r > 1.0)
    resize!(x, ceil(Int64, length(x)*r))
  end

  for k = n_seg:-1:1

    # indexing
    si            = t[k,1]
    ei            = t[k+1,1] - (k == n_seg ? 0 : 1)
    nx_in         = ei-si+1

    xr = DSP.resample(x[si:ei], r)

    # indexing
    nx_out        = min(floor(Int64, nx_in*r), length(xr))
    gap_inds[k+1] = nx_out

    # resample and copy
    copyto!(x, si, xr, 1, nx_out)

    # resize S.x if we downsampled
    (fs_new < fs_old) && (deleteat!(x, si+nx_out:ei))
  end

  for k = 2:n_seg+1
    gap_inds[k] += gap_inds[k-1]
  end
  copyto!(t, 2, gap_inds, 2, n_seg)

  # ensure length(S.x[i]) == S.t[i][end,1] if upsampled
  (r > 1.0) && resize!(x, t[end, 1])
  return nothing
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
  chans::ChanSpec=Int64[],
  fs::Float64=0.0)

  chans     = mkchans(chans, S, keepirr=false)
  f0        = fs == 0.0 ? minimum(S.fs[S.fs .> 0.0]) : fs
  proc_str  = string("resample!(S, chans=", chans, ", fs=",
              repr("text/plain", f0, context=:compact=>true), ")")

  for i = 1:S.n
    (S.fs[i] == 0.0)  && continue
    (S.fs[i] == f0)   && continue
    cheap_resample!(S.t[i], S.x[i], f0, S.fs[i])
    desc_str  = string("resampled from ", S.fs[i], " to ", f0, "Hz")
    proc_note!(S, i, proc_str, desc_str)
    S.fs[i]   = f0
  end
  return nothing
end

function resample!(C::GphysChannel, f0::Float64)
  C.fs > 0.0 || error("Can't resample non-timeseries data!")
  (C.fs == f0) && return nothing
  @assert f0 > 0.0
  proc_str = string("resample!(C, fs=",
              repr("text/plain", f0, context=:compact=>true), ")")
  cheap_resample!(C.t, C.x, f0, C.fs)
  desc_str = string("resampled from ", C.fs, " to ", f0, "Hz")
  proc_note!(C, proc_str, desc_str)
  C.fs = f0
  return nothing
end

@doc (@doc resample!)
function resample(S::GphysData;
  chans::ChanSpec=Int64[],
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
