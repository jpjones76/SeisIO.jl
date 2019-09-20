using SeisIO, SeisIO.RandSeis

# equivalence:
# FDSN wildcard         RegEx
#     ?           =>    .
#     *           =>    .*

function id_to_regex(cid::Array{UInt8,1})
  replace!(cid, 0x2e=>0x5c, 0x3f=>0x2e)
  L = length(cid)
  i = L
  while i > 0
    # replace: '*' => '.*'
    if cid[i] == 0x2a
      splice!(cid, i:i-1, 0x2e)
      i -= 1
    # now replace: '\' => '\.'
    elseif cid[i] == 0x5c
      if i == L
        push!(cid, 0x2e)
      else
        splice!(cid, i:i, [0x5c, 0x2e])
      end
    end
    i -= 1
  end
  return Regex(String(cid))
end

# function id_to_regex(id::AbstractString)
#   # replace: '.' => '\', '?' => '.'
#   cid = copy(codeunits(id))
#   replace!(cid, 0x2e=>0x5c, 0x3f=>0x2e)
#   L = length(cid)
#   i = L
#   while i > 0
#     # replace: '*' => '.*'
#     if cid[i] == 0x2a
#       splice!(cid, i:i-1, 0x2e)
#       i -= 1
#     # now replace: '\' => '\.'
#     elseif cid[i] == 0x5c
#       if i == L
#         push!(cid, 0x2e)
#       else
#         splice!(cid, i:i, [0x5c, 0x2e])
#       end
#     end
#     i -= 1
#   end
#   return Regex(String(cid))
# end
id_to_regex(id::AbstractString) = id_to_regex(copy(codeunits(id)))

function netsta_to_regex(id::AbstractString)
  cid = copy(codeunits(id))
  i = 0
  j = 0
  L = length(cid)
  while i < L
    i += 1
    if cid[i] == 0x2e
      j += 1
    end
    if j == 2
      deleteat!(cid, i:L)
      break
    end
  end
  return id_to_regex(cid)
end


function id_match(id::AbstractString, S::GphysData)
  j = findid(id, S.id)
  j > 0 && return [j]

  idr = id_to_regex(id)
  chans = Int64[]
  for (j, cid) in enumerate(S.id)
    if occursin(idr, cid)
      push!(chans, j)
    end
  end
  return chans
end
