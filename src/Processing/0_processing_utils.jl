function gapfill!(x::Array{T,1}, t::Array{Int64,2}, fs::Float64; m::Bool=true) where T<: Real
  (fs == 0.0 || isempty(x)) && (return x)
  mx::T = m ? mean(x[isnan.(x).==false]) : NaN
  u = round(Int64, max(20, 0.2*fs))
  for i = size(t,1):-1:2
    # Gap fill
    g = round(Int64, fs*μs*t[i,2])
    g < 0 && (@warn(string("Negative time gap (i = ", i, ", t = ", Float64(g)/fs, "; skipped.")); continue)
    g == 0 && continue
    j = t[i-1,1]
    k = t[i,1]
    N = k-j
    splice!(x, k:k-1, mx.*ones(T, g))
  end
  return nothing
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

# Faster than Polynomials.jl with less memory allocation + single-point type
# stability; adapted from
# https://github.com/JuliaMath/Polynomials.jl/blob/master/src/Polynomials.jl
function polyval(p::Array{T,1}, x::Array{T,1}) where T <: Real
  y = last(p)
  for i = lastindex(p)-1:-1:1
    y = p[i] .+ x*y
  end
  return y
end

function polyfit(x::Array{T,1}, y::Array{T,1}, n::Int=1) where T <: Real
  nx = length(x)
  nx == length(y) || throw(DomainError)
  1 <= n <= nx - 1 || throw(DomainError)
  A = Array{T}(undef, length(x), n+1)
  A[:,1] .= one(T)
  for i = 1:n
      A[:,i+1] .= A[:,i] .* x
  end
  return A \ y
end
