export mkchans

function mkchans(chans::Union{Integer, UnitRange, Array{Int64,1}}, n::Int64)

  if chans == Int64[]
    return Int64.(collect(1:n))
  elseif typeof(chans) == UnitRange
    return Int64.(collect(chans))
  elseif typeof(chans) <: Integer
    return [Int64(chans)]
  else
    return chans
  end
end
