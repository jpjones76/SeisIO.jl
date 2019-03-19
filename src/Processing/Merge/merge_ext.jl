# Home of all extended merge! methods
merge(S::SeisData; v::Int64=KW.v) = (U = deepcopy(S); merge!(U, v=v); return U)
merge!(S::SeisData, U::SeisData; v::Int64=KW.v) = ([append!(getfield(S, f), getfield(U, f)) for f in SeisIO.datafields]; S.n += U.n; merge!(S; v=v))
merge!(S::SeisData, C::SeisChannel; v::Int64=KW.v) = merge!(S, SeisData(C), v=v)

"""
    S = merge(A::Array{SeisData,1})

Merge an array of SeisData objects, creating a single output with the merged
input data.

See also: merge!
"""
function merge(A::Array{SeisIO.SeisData,1}; v::Int64=KW.v)
  L::Int64 = length(A)
  n = sum([A[i].n for i = 1:L])
  T = SeisData(n)
  [setfield!(T, f, vcat([getfield(A[i],f) for i = 1:L]...)) for f in SeisIO.datafields]
  return merge!(T, v=v)
end
merge(S::SeisData, U::SeisData; v::Int64=KW.v) = merge(Array{SeisData,1}([S,U]), v=v)
merge(S::SeisData, C::SeisChannel; v::Int64=KW.v) = merge(S, SeisData(C), v=v)
merge(C::SeisChannel, S::SeisData; v::Int64=KW.v) = merge(SeisData(C), S, v=v)
merge(C::SeisChannel, D::SeisChannel; v::Int64=KW.v) = (S = SeisData(C,D); merge!(S, v=v))

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
