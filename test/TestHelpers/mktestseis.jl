function mktestseis()
  L0 = 30
  L1 = 10
  os = 5
  tt = time()
  t1 = round(Int64, tt/μs)
  t2 = round(Int64, (L0+os)/μs) + t1

  S = SeisData(5)
  S.name = ["Channel 1", "Channel 2", "Channel 3", "Longmire", "September Lobe"]
  S.id = ["XX.TMP01.00.BHZ","XX.TMP01.00.BHN","XX.TMP01.00.BHE","CC.LON..BHZ","UW.SEP..EHZ"]
  S.fs = collect(Main.Base.Iterators.repeated(100.0, S.n))
  S.fs[4] = 20.0
  for i = 1:S.n
    os1 = round(Int64, 1/(S.fs[i]*μs))
    S.x[i] = randn(Int(L0*S.fs[i]))
    S.t[i] = [1 t1+os1; length(S.x[i]) 0]
  end

  T = SeisData(4)
  T.name = ["Channel 6", "Channel 7", "Longmire", "September Lobe"]
  T.id = ["XX.TMP02.00.EHZ","XX.TMP03.00.EHN","CC.LON..BHZ","UW.SEP..EHZ"]
  T.fs = collect(Main.Base.Iterators.repeated(100.0, T.n))
  T.fs[3] = 20.0
  for i = 1:T.n
    T.x[i] = randn(Int(L1*T.fs[i]))
    T.t[i] = [1 t2; length(T.x[i]) 0]
  end
  return (S,T)
end
