function split_id(sid::AbstractString; c::String=".")
  id = String.(split(sid, c, keepempty=true))
  L = length(id)
  if L < 4
    id2 = Array{String, 1}(undef, 4-L)
    fill!(id2, "")
    append!(id, id2)
  elseif L > 4
    deleteat!(id, 5:L)
  end
  return id
end
