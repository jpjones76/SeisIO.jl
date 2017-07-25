function t_win(S::SeisData)
  T = Array{Array{Int64,2}}(S.n)
  for i = 1:S.n
    T[i] = t_win(S.t[i], S.fs[i])
  end
  return T
end
