export mkchans

function mkchans(chans::ChanSpec, S::GphysData; f::Symbol=:x, keepempty::Bool=false, keepirr::Bool=true)
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

  # added 2020-03-08: option to auto-delete irregular channels
  if keepirr == false
    for (j,i) in enumerate(chan_list)
      if S.fs[i] == 0.0
        k[j] = false
      end
    end
  end
  return chan_list[k]
end
