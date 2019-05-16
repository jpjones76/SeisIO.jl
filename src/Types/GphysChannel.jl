export GphysChannel

abstract type GphysChannel end

function isequal(C::T, D::T) where {T<:GphysChannel}
  q::Bool = true
  F = fieldnames(T)
  for f in F
    if f != :notes
      q = min(q, getfield(C,f) == getfield(D,f))
    end
  end
  return q
end
==(C::T, D::T) where {T<:GphysChannel} = isequal(C,D)

@doc """
    findid(C::SeisChannel, S::SeisData)
    findid(S::SeisData, C::SeisChannel)

Get the index to the first channel `c` in S where `S.id[c]==C.id`.
""" findid
findid(C::TC, S::TS) where {TC<:GphysChannel, TS<:GphysData} = findid(getfield(C, :id), S)
findid(S::TS, C::TC) where {TC<:GphysChannel, TS<:GphysData} = findid(getfield(C, :id), S)
in(s::String, C::GphysChannel) = getfield(C, :id)==s

@doc (@doc namestrip)
namestrip!(C::T) where {T<:GphysChannel} = setfield!(C, :name, namestrip(getfield(C, :name)))
