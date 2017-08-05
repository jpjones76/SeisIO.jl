"""
        del_sta!(S::SeisData, ssss::String)

Delete channels with station names (second substring of ID) that match `ssss`.
Specify station name as it appears within IDs, e.g. in "UW.HOOD..BHZ" use "HOOD".
Exact matches only.
"""

function del_sta!(S::SeisData, s::String)
  j = Array{Int64,1}(0)
  for i = 1:S.n
    if split(S.id[i], '.')[2] == s
      push!(j, i)
    end
  end
  if !isempty(j)
    deleteat!(S, j)
  end
  return nothing
end
