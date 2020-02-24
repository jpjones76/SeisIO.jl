function add_chan!(S::GphysData, C::GphysChannel, strict::Bool)
  j = strict ? findid(S, C.id) : channel_match(S, C)
  if j > 0
    S.t[j] = t_extend(S.t[j], C.t[1,2], length(C.x), C.fs)
    append!(S.x[j], C.x)
  else
    push!(S, C)
    j = S.n
  end
  return j
end
