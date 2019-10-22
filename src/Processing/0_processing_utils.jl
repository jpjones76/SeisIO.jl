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
  mx = m ? mean(skipmissing(x)) : T(NaN)
  u = max(Int64(20), round(Int64, 0.2*fs))
  Δ = round(Int64, 1.0/(fs*μs))
  nx = length(x) + div(sum(t[2:end,2]), Δ)
  resize!(x, nx)

  w = t_win(t, Δ)
  broadcast!(-, w, w, w[1,1])
  broadcast!(div, w, w, Δ)
  broadcast!(+, w, w, 1)
  nw = size(w,1)
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
  return nothing
end

function gapfill(x::Array{T,1}, t::Array{Int64,2}, fs::Float64; m::Bool=true) where T<: Real
  y = deepcopy(x)
  gapfill!(y, t, fs, m=m)
  return y
end

# replace NaNs with the mean
function nanfill!(x::Array{T,1}) where T<: Real
  J = findall(isnan.(x))
  if !isempty(J)
    if length(J) == length(x)
      fill!(x, zero(T))
    else
      x[J] .= T(mean(findall(isnan.(x).==false)))
    end
  end
  return nothing
end
