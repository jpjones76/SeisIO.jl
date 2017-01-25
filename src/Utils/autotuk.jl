function autotuk!(x::Array{Float64,1}, v::Array{Int64,1}, u::Int)
  g = find(diff(v) .> 1)
  L = length(g)
  if L > 0
    w = Array{Int64,2}(0,2)
    v[g[1]] > 1 && (w = cat(1, w, [1 v[g[1]]]))
    v[g[L]] < length(x) && (w = cat(1, w, [v[g[L]+1] length(x)]))
    L > 1 && ([w = cat(1, w, [v[g[i]+1] v[g[i+1]]]) for i = 1:L-1])
    for i = 1:size(w,1)
      (j,k) = w[i,:]
      if (k-j) >= u
        N = round(Int, k-j)
        x[j+1:k] .*= tukey(N, u/N)
      else
        warn(string("Channel ", i, ": Time window too small, x[", j+1, ":", k, "]; replaced with zeros."))
        x[j+1:k] = 0
      end
    end
  end
  return x
end
