# Merge with EventTraceData
printstyled(stdout,"      merge! on EventTraceData\n", color=:light_green)

(S,T) = mktestseis()
W = convert(EventTraceData, S)
merge!(W)
V = purge(W)
purge!(W)
@test W == V

printstyled(stdout,"      mseis! with Types from SeisIO.Quake\n", color=:light_green)
S = randSeisData()
mseis!(S, convert(EventChannel, randSeisChannel()),
            convert(EventTraceData, randSeisData()),
            randSeisEvent())

printstyled(stdout,"      merge! extensions to EventTraceData, EventChannel\n", color=:light_green)
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
