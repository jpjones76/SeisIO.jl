function track_src!(S::GphysData, j::Int64, nx::Array{Int64,1}, last_src::Array{Int64,1})
  n = length(nx)

  # Check existing channels for changes
  for i in 1:n
    if length(S.x[i]) > nx[i]
      last_src[i] = j
      nx[i] = length(S.x[i])
    end
  end

  # Add new channels
  if n < S.n
    δn = S.n - n
    append!(nx, zeros(Int64, δn))
    append!(last_src, zeros(Int64, δn))
    for i in n+1:S.n
      nx[i] = length(S.x[i])
      last_src[i] = j
    end
  end
  return nothing
end
