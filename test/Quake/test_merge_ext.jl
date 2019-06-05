# Merge with EventTraceData
printstyled(stdout,"  merge! on EventTraceData\n", color=:light_green)

# Test case where we have to merge phase catalogs
(S,T) = mktestseis()
S = convert(EventTraceData, S)
T = convert(EventTraceData, T)
for i = 1:S.n
  S.az[i] = (rand()-0.5)*360.0
  S.baz[i] = (rand()-0.5)*360.0
  S.dist[i] = (rand()-0.5)*360.0
  S.pha[i] = randPhaseCat()
end

for i = 1:T.n
  T.az[i] = (rand()-0.5)*360.0
  T.baz[i] = (rand()-0.5)*360.0
  T.dist[i] = (rand()-0.5)*360.0
end

# Force a phase pick mismatch
P_true = SeisPha(rand(Float64,8)..., 'U', '0')
P_false = SeisPha(rand(Float64,8)..., '+', '1')
i = findid("CC.LON..BHZ", S)
j = findid("CC.LON..BHZ", T)

# T always begins later and should thus preserve P_true in the merge
S.pha[i]["P"] = deepcopy(P_false)
T.pha[j]["P"] = deepcopy(P_true)
merge!(S,T)
i = findid("CC.LON..BHZ", S)
@test S.pha[i]["P"] == P_true

# Check that purge works
V = purge(S)
purge!(S)
@test S == V

printstyled(stdout,"  merge! extensions to EventTraceData, EventChannel\n", color=:light_green)
S = convert(EventTraceData, randSeisData())
T = deepcopy(S)
merge!(S)
@test merge(T) == S
merge!(S,T)
sort!(T)
@test S == T

C = convert(EventChannel, randSeisChannel())
T = merge(S, C)
merge!(S, C)
@test S == T

C = convert(EventChannel, randSeisChannel())
S = convert(EventTraceData, randSeisData())
@test merge(C, S) == merge(S, C)

A = EventTraceData[convert(EventTraceData, randSeisData()),
convert(EventTraceData, randSeisData()),
convert(EventTraceData, randSeisData())]
merge(A)

S = convert(EventTraceData, randSeisData())
T = convert(EventTraceData, randSeisData())
@test S*T == T*S

@test S*C == merge(S, EventTraceData(C))

C = convert(EventChannel, randSeisChannel())
D = convert(EventChannel, randSeisChannel())
S = merge(C,D)
@test typeof(S) == EventTraceData
@test C*D == S
