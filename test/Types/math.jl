printstyled(stdout, "  mathematical properties\n", color=:light_green)
H = randSeisHdr()
V = randSeisEvent()
S = randSeisData()
T = convert(EventTraceData, S)
C = randSeisChannel()
D = convert(EventChannel, C)

printstyled(stdout, "    reflexivity\n", color=:light_green)
@test C==C
@test D==D
@test H==H
@test S==S
@test T==T
@test V==V

printstyled(stdout, "    commutativity\n", color=:light_green)

printstyled(stdout, "      S1 + S2 == S2 + S1\n", color=:light_green)

# SeisData + SeisData
S1 = randSeisData()
S2 = randSeisData()
@test S1 + S2 == S2 + S1

# EventTraceData + EventTraceData
S1 = convert(EventTraceData, randSeisData())
S2 = convert(EventTraceData, randSeisData())
@test S1 + S2 == S2 + S1

printstyled(stdout, "      S + C == C + S\n", color=:light_green)

# SeisData + SeisChannel
S = randSeisData()
C = randSeisChannel()
U = deepcopy(S)
push!(U, C)
U = sort(U)
@test C + S == S + C == U
@test findid(C, U) == findid(C, S + C) == findid(C, C + S)

# EventTraceData + EventChannel
S = convert(EventTraceData, randSeisData())
C = convert(EventChannel, randSeisChannel())
U = deepcopy(S)
push!(U, C)
U = sort(U)
@test C + S == S + C == U
@test findid(C, U) == findid(C, S + C) == findid(C, C + S)

printstyled(stdout, "      C1 + C2 == C2 + C1\n", color=:light_green)

# SeisChannel + SeisChannel
C1 = randSeisChannel()
C2 = randSeisChannel()
@test C1 + C2 == C2 + C1

# EventChannel + EventChannel
C1 = convert(EventChannel,randSeisChannel())
C2 = convert(EventChannel,randSeisChannel())
@test C1 + C2 == C2 + C1

printstyled(stdout, "      S + U - U == S (for sorted S)\n", color=:light_green)
# SeisData + SeisData - SeisData
(S, T) = mktestseis()
S = sort(S)
@test (S + T - T) == S

# EventTraceData + EventTraceData - EventTraceData
(S, T) = mktestseis()
S = convert(EventTraceData, S)
T = convert(EventTraceData, T)
@test (S + T - T) == sort(S)

printstyled(stdout, "    associativity\n", color=:light_green)

printstyled(stdout, "      (S1 + S2) + S3 == S1 + (S2 + S3)\n", color=:light_green)
# SeisData + SeisData + SeisData
S1 = randSeisData()
S2 = randSeisData()
S3 = randSeisData()
@test S1 + (S2 + S3) == (S1 + S2) + S3

printstyled(stdout, "      (S1 + S2) + C == S1 + (S2 + C)\n", color=:light_green)
# SeisData + SeisChannel
C1 = randSeisChannel()
@test S1 + (S2 + C1) == (S1 + S2) + C1

# EventTraceData + EventTraceData + EventTraceData
S1 = convert(EventTraceData, randSeisData())
S2 = convert(EventTraceData, randSeisData())
S3 = convert(EventTraceData, randSeisData())
@test S1 + (S2 + S3) == (S1 + S2) + S3

# EventTraceData + EventChannel
C1 = convert(EventChannel, randSeisChannel())
@test S1 + (S2 + C1) == (S1 + S2) + C1
