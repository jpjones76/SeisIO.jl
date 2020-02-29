function add_chan!(S::GphysData, C::GphysChannel, strict::Bool)
  if isempty(S)
    push!(S, C)
    return 1
  end
  j = strict ? channel_match(S, C) : findid(S, C.id)
  if j > 0
    S.t[j] = t_extend(S.t[j], C.t[1,2], length(C.x), C.fs)
    append!(S.x[j], C.x)
  else
    push!(S, C)
    j = S.n
  end
  return j
end
