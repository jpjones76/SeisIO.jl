export nanfill!

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
  return length(J)
end

"""
  nanfill!(S::SeisData)
  nanfill!(C::SeisChannel)

Replace NaNs in `:x` with mean of non-NaN values.
"""
function nanfill!(S::GphysData)
  for i = 1:S.n
    if !isempty(S.x[i])
      nn = nanfill!(S.x[i])
      if nn > 0
        proc_note!(S, i, "nanfill!(S)", "replaced NaNs with the mean of all non-NaN values")
      end
    end
  end
  return nothing
end

function nanfill!(C::GphysChannel)
  nn = nanfill!(C.x)
  if nn > 0
    proc_note!(C, "nanfill!(C)", "replaced NaNs with the mean of all non-NaN values")
  end
  return nothing
end
