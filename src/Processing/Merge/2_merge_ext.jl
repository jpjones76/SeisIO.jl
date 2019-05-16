export mseis!, purge!

# Home of all extended merge! methods
@doc (@doc merge)
merge(S::SeisData; v::Int64=KW.v) = (U = deepcopy(S); merge!(U, v=v); return U)
merge!(S::SeisData, U::SeisData; v::Int64=KW.v) = ([append!(getfield(S, f), getfield(U, f)) for f in SeisIO.datafields]; S.n += U.n; merge!(S; v=v))
merge!(S::SeisData, C::SeisChannel; v::Int64=KW.v) = merge!(S, SeisData(C), v=v)

"""
    S = merge(A::Array{SeisData,1})

Merge an array of SeisData objects, creating a single output with the merged
input data.

See also: merge!
"""
function merge(A::Array{SeisData,1}; v::Int64=KW.v)
  L::Int64 = length(A)
  n = sum([A[i].n for i = 1:L])
  T = SeisData(n)
  [setfield!(T, f, vcat([getfield(A[i],f) for i = 1:L]...)) for f in SeisIO.datafields]
  merge!(T, v=v)
  return T
end
merge(S::SeisData, U::SeisData; v::Int64=KW.v) = merge(Array{SeisData,1}([S,U]), v=v)
merge(S::SeisData, C::SeisChannel; v::Int64=KW.v) = merge(S, SeisData(C), v=v)
merge(C::SeisChannel, S::SeisData; v::Int64=KW.v) = merge(SeisData(C), S, v=v)
merge(C::SeisChannel, D::SeisChannel; v::Int64=KW.v) = (S = SeisData(C,D); merge!(S, v=v))

"""
    mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures at once.

See also: merge!
"""
function mseis!(S...)
  U = Union{SeisData, SeisChannel, SeisEvent, EventTraceData, EventChannel}
  L = Int64(length(S))
  (L < 2) && return
  S1 = getindex(S, 1)
  (typeof(S1) == SeisData) || error("Target must be type SeisData!")
  for i = 2:L
    T = typeof(getindex(S, i))
    if (T <: U) == false
      @warn(string("Object of incompatible type passed to wseis at ", i+1, "; skipped!"))
      continue
    end
    if T == SeisData
      append!(S1, getindex(S, i))
    elseif T == EventTraceData
      append!(S1, convert(SeisData, getindex(S, i)))
    elseif T == SeisChannel
      append!(S1, SeisData(getindex(S, i)))
    elseif T == EventChannel
      append!(S1, SeisData(convert(SeisChannel, getindex(S, i))))
    elseif T == SeisEvent
      append!(S1, convert(SeisData, getfield(getindex(S, i), :data)))
    end
  end
  merge!(S1)
  return S1
end

"""
    purge!(S::SeisData)

Remove empty and duplicated channels in S; alias to merge!(S, purge_only=true)

    purge(S::SeisData)

"Safe" purge to a new SeisData object. Alias to merge(S, purge_only=true)
"""
purge!(S::T, v::Int64=KW.v) where {T<:GphysData} = merge!(S, purge_only=true, v=v)
function purge(S::T, v::Int64=KW.v) where {T<:GphysData}
  U = deepcopy(S)
  merge!(U, v=v, purge_only=true)
  return U
end
