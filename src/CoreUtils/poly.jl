# Faster than Polynomials.jl with less memory allocation + single-point type
# stability; adapted from Octave and
# https://github.com/JuliaMath/Polynomials.jl/blob/master/src/Polynomials.jl
function poly(x::Array{T,1}) where T <: Number
  n = length(x)
  y = zeros(T, n+1)
  y[1] = one(T)
  for j = 1:n
    y[2:j+1] .-= x[j].*y[1:j]
  end
  return y
end

function polyval(p::Array{T1,1}, x::T2) where {T1 <: Number, T2 <: Number}
  y = T2(p[1])
  for i = 2:lastindex(p)
    y = p[i] .+ x*y
  end
  return y
end

function polyval(p::Array{T1,1}, x::Array{T2,1}) where {T1 <: Number, T2 <: Number}
  y = ones(T2, length(x)) .* p[1]
  for i = 2:length(p)
    broadcast!(*, y, y, x)
    broadcast!(+, y, y, p[i])
  end
  return y
end

function polyfit(x::Array{T1,1}, y::Array{T2,1}, n::Integer=1) where {T1 <: Real, T2 <: Real}
  nx = length(x)
  nx == length(y) || error("SeisIO.polyfit requires length(t) == length(x)")
  -1 < n < nx || throw(DomainError)
  A = Array{T2, 2}(undef, length(x), n+1)
  A[:,n+1] .= one(T2)
  for i = n:-1:1
      A[:,i] .= A[:,i+1] .* x
  end
  return A \ y
end

# Convert to Float64 or use improved sum
function linreg(t::Array{Float64,1}, x::AbstractArray{T,1}) where T
  n = length(t)
  st = sum(t)
  sx = sum(x)
  stt = dot(t,t)
  stx = dot(t,x)
  sxx = dot(x,x)
  d = n*stt - st*st
  b = (stt*sx - st*stx)/d
  a = (n*stx - st*sx)/d
  return T[a,b]
end

# p = linreg(x, fs)
function linreg(x::AbstractArray{T,1}, dt::Float64) where T
  n = length(x)
  t = dt:dt:n*dt
  st = sum(t)
  sx = sum(x)
  stt = dot(t,t)
  stx = dot(t,x)
  sxx = dot(x,x)
  d = n*stt - st*st
  b = (stt*sx - st*stx)/d
  a = (n*stx - st*sx)/d
  return T[a,b]
end

#= CHANGELOG for this file
2019-08-08
* poly, polyval, and polyfit should now always output powers in descending
order, i.e., p^n ... p^0
* BUG fixed: polyval(p::Array{T,1}, x::T) used power ordering of Polynomials.jl;
corrected to be consistent with other routines
* polyfit now allows order n=0 and takes any Integer for n; n=0 returns the mean
2019-08-19
* added linreg for low-memory linear regression; identical to SAC detrend
=#
