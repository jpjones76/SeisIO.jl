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

in(s::String, C::GphysChannel) = getfield(C, :id)==s

@doc (@doc namestrip)
namestrip!(C::T) where {T<:GphysChannel} = setfield!(C, :name, namestrip(getfield(C, :name)))
