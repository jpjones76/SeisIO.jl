function del_flagged!(S::SeisData, dflag::BitArray{1}, reason::String)
  d = findall(dflag)
  L = length(d)
  if L > 0
    @warn(string("Deleting (", reason, ")"), S.id[d])
    deleteat!(S, d)
  end
  return nothing
end
