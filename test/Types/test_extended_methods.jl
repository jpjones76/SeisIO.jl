printstyled(stdout,"  extended methods\n", color=:light_green)

printstyled(stdout,"    getindex\n", color=:light_green)
(S,T) = mktestseis()
@test findid(T, S) == [0, 0, 4, 5]

printstyled(stdout,"    getindex + Int on SeisData ==> SeisChannel\n", color=:light_green)
i_targ = 3
C = S[i_targ]
test_fields_preserved(C,S,i_targ)

printstyled(stdout,"    getindex + Range on SeisData ==> SeisData\n", color=:light_green)
D = S[i_targ:i_targ+1]
test_fields_preserved(D,S,2,i_targ+1)

printstyled(stdout,"    setindex!\n", color=:light_green)
A = SeisData(3)
setindex!(A, C, 3)
test_fields_preserved(C, A, 3)
A[1:2]=D
test_fields_preserved(A, S, 2, i_targ+1)
test_fields_preserved(C, S, 3)

printstyled(stdout,"    in\n", color=:light_green)
@test ("XX.TMP01.00.BHZ" in S.id)

printstyled(stdout,"      findid\n", color=:light_green)
@test ≈(findid("CC.LON..BHZ",S), findid(S,"CC.LON..BHZ"))
@test ≈(findid(S,"CC.LON..BHZ"), 4)
@test ≈(findid(S,C), 3)

printstyled(stdout,"    isempty\n", color=:light_green)
D = SeisData()
@test isempty(D)

printstyled(stdout,"    append!\n", color=:light_green)
(S,T) = mktestseis()
append!(S, T)
sizetest(S, 9)

C = deepcopy(S[4])
deleteat!(S, 4)
sizetest(S, 8)
@test ≈(length(findall(S.name.==C.name)),1)

C = deepcopy(S[3:4])
deleteat!(S,3:4)
nt = 6
@test ≈(S.n, nt)
@test ≈(maximum([length(getfield(S,i)) for i in datafields]), nt)
@test ≈(minimum([length(getfield(C,i)) for i in datafields]), 2)
@test length(findall(S.name.==C.name[1])).*length(findall(S.id.==C.id[1])) == 0
@test length(findall(S.name.==C.name[2])).*length(findall(S.id.==C.id[2])) == 1

s = "CC.LON..BHZ"
delete!(S, s)
sizetest(S, 5)

s = r"EH"
# @test_throws BoundsError S - s
delete!(S, s, exact=false)
sizetest(S, 2)

# untested methods in SeisData
for i = 1:5
  S = randSeisData()
  @test sizeof(S) > 0

  r = S.id[1]
  U = S - r
  @test sizeof(U) < sizeof(S)
  @test S.n == U.n + 1

  T = pull(S,r)
  @test isa(T, SeisChannel)
  @test(U == S)
end

H = randSeisHdr()
@test sizeof(H) > 0
clear_notes!(H)
@test length(H.notes) == 1

(S,T) = mktestseis()
U = S-T
sizetest(S,5)
sizetest(T,4)
sizetest(U,3)

(S,T) = mktestseis()
U = deepcopy(S)
deleteat!(U, 1:3)
@test (S - [1,2,3]) == U
sizetest(S,5)

(S,T) = mktestseis()
@test in("UW.SEP..EHZ",S)
U = S[3:S.n]
V = deepcopy(S)
deleteat!(S, 1:2)
deleteat!(V, [1,2])
@test S == U == V
delete!(S, "CC.", exact=false)
delete!(U,V)

(S,T) = mktestseis()
X = deepcopy(T)
U = pull(S, 5)
@test U.id == "UW.SEP..EHZ"
sizetest(S, 4)
@test findid("UW.SEP..EHZ", S.id) == 0

U = pull(S, 3:4)
sizetest(S, 2)
@test findid(U.id[1], S.id) == 0
@test findid(U.id[2], S.id) == 0

V = pull(T, [2,3,4])
sizetest(T, 1)
@test findid(V.id[1], T.id) == 0
@test findid(V.id[2], T.id) == 0
@test findid(V.id[3], T.id) == 0
V = sort(V)

deleteat!(X,1)
@test findid(V,X) == [2,3,1]
Y = sort(X)
@test V == Y

# added 2019-02-23
S = SeisData(randSeisData(5), SeisChannel(), SeisChannel(),
    SeisChannel(id="UW.SEP..EHZ", name="Darth Exploded",
    loc=GeoLoc(lat=46.1967, lon=-122.1875, el=1440.0), t=[0 0; 1024 0], x=rand(1024)))
prune!(S)
@test (S.n == 6)
J = findchan("EHZ",S)
@test (6 in J)

printstyled(stdout,"    show\n", color=:light_green)
S = breaking_seis()
T = randSeisData(1)


redirect_stdout(out) do
  show(SeisChannel())
  show(SeisData())
  show(SeisHdr())
  show(SeisEvent())
  show(EventTraceData())
  show(EventChannel())

  show(randSeisChannel())
  show(S)
  show(T)
  show(randSeisHdr())
  show(randSeisEvent())

  summary(randSeisChannel())
  summary(randSeisData())
  summary(randSeisEvent())
  summary(randSeisHdr())

  # invoke help-only functions
  @test seed_support() == nothing
  @test chanspec() == nothing
  @test mseed_support() == nothing
  @test timespec() == nothing
end

printstyled("  SeisChannel methods\n", color=:light_green)

id = "UW.SEP..EHZ"
name = "Darth Exploded"

Ch = randSeisChannel()
Ch.id = id
Ch.name = name
S = SeisData(Ch)

@test in(id, Ch) == true
@test isempty(Ch) == false
@test convert(SeisData, Ch) == SeisData(Ch)
@test findid(Ch, S) == 1
@test sizeof(Ch) > 0
@test lastindex(S) == 1

printstyled("  convert\n", color=:light_green)
TD = convert(EventTraceData, EventChannel())
sz = sizeof(TD)
