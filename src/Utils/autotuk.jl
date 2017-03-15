function autotuk!(x::Array{Float64,1}, v::Array{Int64,1}, u::Int)
  g = find(diff(v) .> 1)
  L = length(g)
  y = Array{Float64,1}(0)
  if L > 0
    unshift!(g, 0)
    push!(g, length(x))
    for i = 1:length(g)-1
      j = g[i]+1
      k = g[i+1]
      if (k-j+1) > u
        N = k-j+1
        resize!(y, N)
        y[:] = x[j:k]
        μ = collect(repeated(mean(y), N))
        x[j:k] = ((y-μ).*tukey(N, u/N))+μ
      else
        warn(string("Time window too small, x[", j, ":", k, "]; replaced with zeros."))
        x[j:k] = 0
      end
    end
  end
  return x
end
