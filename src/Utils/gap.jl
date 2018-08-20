function get_sync_t(s::Union{String,DateTime}, t::Array{Int64,1}, k::Array{Int64,1})
  isa(s, DateTime) && return round(Int64, d2u(s)/μs)
  if s == "max"
    return minimum(t[k])
  elseif s == "min"
    return maximum(t[k])
  else
    return round(Int64, d2u(DateTime(s))/μs)
  end
end

function gapfill!(x::Array{Float64,1}, t::Array{Int64,2}, fs::Float64; m=true::Bool, w=true::Bool)
  (fs == 0.0 || isempty(x)) && (return x)
  mx = m ? mean(x[isnan.(x).==false]) : NaN
  u = round(Int64, max(20, 0.2*fs))
  for i = size(t,1):-1:2
    # Gap fill
    g = round(Int64, fs*μs*t[i,2])
    g < 0 && (@warn(string("Negative time gap (i = ", i, ", t = ", Float64(g)/fs, "; skipped.")); continue)
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
        @warn(@sprintf("segment %i too short; x[%i:%i] replaced with mean(x).", i, j+1, k))
        x[j+1:k] = mx
      end
    end
  end
  return x
end

gapfill(x::Array{Float64,1}, t::Array{Int64,2}, f::Float64) =
  (y = deepcopy(x); gapfill!(y,t,f); return y)
