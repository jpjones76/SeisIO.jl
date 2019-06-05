S = convert(EventTraceData, randSeisData())
T = deepcopy(S)
merge!(S)
@test merge(T) == S
merge!(S,T)
sort!(T)
@test S == T

C = convert(EventChannel, randSeisChannel())
merge!(S, C)

A = EventTraceData[convert(EventTraceData, randSeisData()),
convert(EventTraceData, randSeisData()),
convert(EventTraceData, randSeisData())]
merge(A)

S = convert(EventTraceData, randSeisData())
T = convert(EventTraceData, randSeisData())
@test S*T == T*S

@test S*C == merge(S, EventTraceData(C))

D = convert(EventChannel, randSeisChannel())
S = merge(C,D)
