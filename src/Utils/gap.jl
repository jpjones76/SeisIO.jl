function get_sync_t(s::Union{String,DateTime}, t::Array{Int64,1}, k::Array{Int64,1})
  isa(s, DateTime) && return round(Int, d2u(s)/μs)
  if s == "max"
    return minimum(t[k])
  elseif s == "min"
    return maximum(t[k])
  else
    return round(Int, d2u(DateTime(s))/μs)
  end
end

function gapfill!(x::Array{Float64,1}, t::Array{Int64,2}, fs::Float64; m=true::Bool, w=true::Bool)
  (fs == 0 || isempty(x)) && (return x)
  mx = m ? mean(x[!isnan(x)]) : NaN
  u = round(Int, max(20,0.2*fs))
  for i = size(t,1):-1:2
    # Gap fill
    g = round(Int, fs*μs*t[i,2])
    g < 0 && (warn(@sprintf("Negative time gap (i = %i, t = %.3f); skipped.", i, g)); continue)
    g == 0 && continue
    j = t[i-1,1]
    k = t[i,1]
    N = k-j
    splice!(x, k:k-1, mx.*ones(g))

    # Window if selected
    if w
      if N >= u
        x[j+1:k] .*= tukey(N, u/N)
      else
        warn(string(@sprintf("Channel %i: Time window too small, ",i),
        @sprintf("x[%i:%i]; replaced with mean.", j+1, k)))
        x[j+1:k] = mx
      end
    end
  end
  return x
end

gapfill(x::Array{Float64,1}, t::Array{Int64,2}, f::Float64) =
  (y = deepcopy(x); gapfill!(y,t,f); return y)
