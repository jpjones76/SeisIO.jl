"""
    gapfill!(x t, fs; m::Bool=true)
    y = gapfill(x, t, fs; m::Bool=true)

Fill gaps in `x`, sampled at `fs`, with gap indices given by `t[:,1]` and
gap lengths in μs given by `t[:,2]`.

Specify `m=false` to fill with NaNs; else, fill with the mean of non-NaN
values in `x`.
"""
function gapfill!(x::Array{T,1}, t::Array{Int64,2}, fs::Float64; m::Bool=true) where T<: Real
  (fs == 0.0 || isempty(x)) && (return x)
  nt = size(t,1)
  ng = nt - (t[nt,2] == 0 ? 2 : 1)
  (ng == 0) && (return x)

  timegaps = t[2:end,2]                       # number of time gaps
  mx = m ? mean(skipmissing(x)) : T(NaN)      # mean or NaN
  Δ = round(Int64, 1.0/(fs*μs))               # sampling interval in μs

  # this always yields rows in w whose indices are correct output assignments
  w = t_win(t, Δ)
  nw = size(w,1)
  broadcast!(-, w, w, w[1,1])
  broadcast!(div, w, w, Δ)
  broadcast!(+, w, w, 1)
  nx = maximum(w)-minimum(w)+1

  if minimum(timegaps) ≥ 0
    resize!(x, nx)
    for i = nw:-1:1
      N = w[i,2]-w[i,1]+1
      j = t[i,1]
      copyto!(x, w[i,1], x, j, N)
      if i > 1
        fill_s = w[i-1,2]+1
        fill_e = w[i,1]-1
        x[fill_s:fill_e] .= mx
      end
    end
  else
    # Fix for issue #29
    x1 = Array{T,1}(undef, nx)

    # with negative gaps, source start indices are in t[:,1]
    for i in 1:nw
      N = w[i,2]-w[i,1]+1
      j = t[i,1]
      copyto!(x1, w[i,1], x, j, N)
      if i > 1
        fill_s = w[i-1,2]+1
        fill_e = w[i,1]-1
        (fill_e > fill_s) && (x1[fill_s:fill_e] .= mx)
      end
    end
    resize!(x, nx)
    copyto!(x, 1, x1, 1, nx)
  end
  return nothing
end
