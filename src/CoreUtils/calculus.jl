# adapted from https://github.com/JuliaMath/KahanSummation.jl
function cumsum_kbn!(v::AbstractVector{T}) where T<:AbstractFloat
    s = v[1]
    c = zero(T)
    @inbounds for i = 2:length(v)
        vi = v[i]
        t = s + vi
        if abs(s) >= abs(vi)
            c += ((s-t) + vi)
        else
            c += ((vi-t) + s)
        end
        s = t
        v[i] = s+c
    end
    return nothing
end

function diff_x!(x::Array{T,1}, gaps::Array{Int64,1}, fs::T) where T<:AbstractFloat
  L = length(x)
  j = 1
  @inbounds while j < length(gaps)
    j += 1
    si = gaps[j-1]+1
    ei = gaps[j]-1
    if j == length(gaps)
      ei += 1
    end
    for i = ei:-1:si
      x[i] -= x[i-1]
    end
  end
  rmul!(x, fs)
  return nothing
end

function int_x!(x::Array{T,1}, gaps::Array{Int64,1}, δ::T) where T<:AbstractFloat
  L = length(x)
  j = 1
  @inbounds while j < length(gaps)
    j += 1
    si = gaps[j-1]
    ei = gaps[j]-1
    if j == length(gaps)
      ei += 1
    end

    xv = view(x, si:ei)
    cumsum_kbn!(xv)
  end
  rmul!(x, δ)
  return nothing
end
