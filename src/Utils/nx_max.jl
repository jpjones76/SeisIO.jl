function nx_max(S::GphysData)
  N = 0
  window_lengths = Array{Int64,1}(undef,0)
  t = Array{Int64,2}(undef,0,0)
  for i = 1:S.n
    if S.fs[i] > 0.0
      t = getfield(S, :t)[i]
      window_lengths = diff(t[:,1])
      window_lengths[end] += 1
      N = max(N, maximum(window_lengths))
    end
  end
  return N
end

function nx_max(C::GphysChannel)
  @assert C.fs > 0.0
  window_lengths = diff(C.t[:,1])
  window_lengths[end] += 1
  return maximum(window_lengths)
end
