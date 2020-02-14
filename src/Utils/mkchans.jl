export mkchans

# function mkchans(chans::Union{Integer, UnitRange, Array{Int64,1}}, n::Int64)
#
#   if chans == Int64[]
#     return Int64.(collect(1:n))
#   elseif typeof(chans) <: UnitRange
#     return Int64.(collect(chans))
#   elseif typeof(chans) <: Integer
#     return [Int64(chans)]
#   else
#     return chans
#   end
# end

function mkchans(chans::Union{Integer, UnitRange, Array{Int64,1}}, S::GphysData; f::Symbol=:x, keepempty::Bool=false)
  chan_list = (if chans == Int64[]
    Int64.(collect(1:S.n))
  elseif typeof(chans) <: UnitRange
    Int64.(collect(chans))
  elseif typeof(chans) <: Integer
    [Int64(chans)]
  else
    chans
  end)

  # added 2020-02-12; prevents processing an empty channel
  k = trues(length(chan_list))
  if keepempty == false
    F = getfield(S, f)
    for (j,i) in enumerate(chan_list)
      if isempty(F[i])
        k[j] = false
      end
    end
  end
  return chan_list[k]
end
