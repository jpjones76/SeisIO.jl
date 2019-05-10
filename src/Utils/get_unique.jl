# Given a SeisData structure S, create:
# H, a set of hashes where each unique hash matches a unique set of inputs
#   parameters (e.g. :fs, eltype(:x))
# X, a set of views corresponding to each H
# Get sets of channels where all channels in inds[i] have matching properties
# as specified in A
function get_unique(S::T, A::Array{String,1}) where {T<:GphysData}
  J = lastindex(A)
  N = getfield(S, :n)
  H = Array{UInt64,1}(undef,N)
  fields = fieldnames(T)
  h = Array{UInt64,1}(undef, J)
  cmd = Array{String,1}(undef, J)
  @inbounds for i = 1:N
    for (j, str) in enumerate(A)
      sym = Symbol(str)
      if any(fields.==sym)
        h[j] = hash(getfield(S, sym)[i])
      else
        h[j] = hash(getfield(Main, sym)(getfield(S, :x)[i]))
      end
    end
    H[i] = hash(h)
  end

  # Get unique hashes
  Uh = unique(H)
  Nh = length(Uh)
  inds = Array{Array{Int64,1},1}(undef,Nh)

  @inbounds for n = 1:Nh
    inds[n] = Array{Int64,1}(undef,0)
    for i = 1:N
      # Uses an order of magnitude less memory than findall
      if H[i] == Uh[n]
        push!(inds[n], i)
        continue
      end
    end
  end

  # One last pass...sort by size of eltype(S.x) in descending order
  el_size = [sizeof(eltype(S.x[i[1]])) for i in inds]
  ii = sortperm(el_size, rev=true)
  inds = inds[ii]

  return inds
end
