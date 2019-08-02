# We only really want the polynomial
function poly(x::Array{T,1}) where T<:Complex
  n = length(x)
  y = zeros(T, n+1)
  y[1] = one(T)
  for j = 1:n
    y[2:j+1] .-= x[j].*y[1:j]
  end
  return reverse(y)
end

# Faster than Polynomials.jl with less memory allocation + single-point type
# stability; adapted from
# https://github.com/JuliaMath/Polynomials.jl/blob/master/src/Polynomials.jl
function polyval(p::Array{T,1}, x::T) where T <: Number
  y = one(T)
  for i = lastindex(p)-1:-1:1
    y = p[i] .+ x*y
  end
  return y
end

function polyval(p::Array{T,1}, x::Array{T,1}) where T <: Number
  y = ones(T, length(x)) .* first(p)
  for i = 2:length(p)
    broadcast!(*, y, y, x)
    broadcast!(+, y, y, p[i])
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
  return reverse(A \ y)
end
