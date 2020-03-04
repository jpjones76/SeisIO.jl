@doc """
    findid(id::String, S::GphysData)
    findid(S::GphysData, id::String)

Get the index of the first channel in S where `id.==S.id` is true. Returns 0
for failure.

    findid(S::GphysData, T::GphysData)

Get index corresponding to the first channel in T that matches each ID in S;
equivalent to [findid(id,T) for id in S.id].

    findid(C::SeisChannel, S::SeisData)
    findid(S::SeisData, C::SeisChannel)

Get the index to the first channel `c` in S where `S.id[c]==C.id`.
""" findid
function findid(id::String, ID::Array{String,1})
  c = 0
  for i = 1:length(ID)
    if ID[i] == id
      c = i
      break
    end
  end
  return c
end

function findid(id::DenseArray{UInt8,1}, ID::Array{String,1})
  c = 0
  for i = 1:length(ID)
    if codeunits(ID[i]) == id
      c = i
      break
    end
  end
  return c
end

function findid(id::Union{Regex,String}, S::T) where {T<:GphysData}
  j=0
  for i=1:length(S.id)
    if S.id[i] == id
      j=i
      break
    end
  end
  return j
end
findid(S::T, id::Union{String,Regex})  where {T<:GphysData} = findid(id, S)
# DND ...why the fuck is findfirst so fucking slow?!

findid(C::TC, S::TS) where {TC<:GphysChannel, TS<:GphysData} = findid(getfield(C, :id), S)
findid(S::TS, C::TC) where {TC<:GphysChannel, TS<:GphysData} = findid(getfield(C, :id), S)
