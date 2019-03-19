# Home of all extended merge! methods
merge(S::SeisData) = (U = deepcopy(S); merge!(U); return U)
merge!(S::SeisData, U::SeisData) = ([append!(getfield(S, f), getfield(U, f)) for f in SeisIO.datafields]; S.n += U.n; merge!(S))
merge!(S::SeisData, C::SeisChannel) = merge!(S, SeisData(C))

"""
    S = merge(A::Array{SeisData,1})

Merge an array of SeisData objects, creating a single output with the merged
input data.

See also: merge!
"""
function merge(A::Array{SeisIO.SeisData,1})
  L::Int64 = length(A)
  n = sum([A[i].n for i = 1:L])
  T = SeisData(n)
  [setfield!(T, f, vcat([getfield(A[i],f) for i = 1:L]...)) for f in SeisIO.datafields]
  return merge!(T)
end
merge(S::SeisData, U::SeisData) = merge(Array{SeisData,1}([S,U]))
merge(S::SeisData, C::SeisChannel) = merge(S, SeisData(C))
merge(C::SeisChannel, S::SeisData) = merge(SeisData(C), S)
merge(C::SeisChannel, D::SeisChannel) = (S = SeisData(C,D); merge!(S))

# The "*" operator for SeisData
*(S::SeisData, U::SeisData) = merge(Array{SeisData,1}([S,U]))
*(S::SeisData, C::SeisChannel) = merge(S,SeisData(C))
*(C::SeisChannel, D::SeisChannel) = (s1 = deepcopy(C); s2 = deepcopy(D); S = merge(SeisData(s1),SeisData(s2)); return S)

"""
    mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures at once.

See also: merge!
"""
function mseis!(S...)
  U = Union{SeisData,SeisChannel,SeisEvent}
  L = Int64(length(S))
  (L < 2) && return
  (typeof(S[1]) == SeisData) || error("Target must be type SeisData!")
  for i = 2:L
    if !(typeof(S[i]) <: U)
      @warn(string("Object of incompatible type passed to wseis at ",i+1,"; skipped!"))
      continue
    end
    if typeof(S[i]) == SeisData
      append!(S[1], S[i])
    elseif typeof(S[i]) == SeisChannel
      append!(S[1], SeisData(S[i]))
    elseif typeof(S[i]) == SeisEvent
      append!(S[1], S[i].data)
    end
  end
  return merge!(S[1])
end
