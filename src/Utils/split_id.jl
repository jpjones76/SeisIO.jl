function split_id(sid::String)
  id = String.(split(sid, ".", limit=4, keepempty=true))
  L = length(id)
  if L < 4
    id2 = deepcopy(id)
    id = Array{String, 1}(undef, 4)
    fill!(id, "")
    for j = 1:L
      id[j] = identity(id2[j])
    end
  end
  return id
end
