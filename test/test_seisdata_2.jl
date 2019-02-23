const μs = 1.0e-6
const datafields = [:name, :id, :fs, :gain, :loc, :misc, :notes, :resp, :src, :units, :t, :x]
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]

test_fields_preserved(S1::SeisData, S2::SeisData, x::Int, y::Int) = @assert(minimum([getfield(S1,f)[x]==getfield(S2,f)[y] for f in datafields]))
test_fields_preserved(S1::SeisChannel, S2::SeisData, y::Int) =
  @assert(minimum([getfield(S1,f)==getfield(S2,f)[y] for f in datafields]))

function sizetest(S::SeisData, nt::Int)
  @test ≈(S.n, nt)
  @test ≈(maximum([length(getfield(S,i)) for i in datafields]), nt)
  @test ≈(minimum([length(getfield(S,i)) for i in datafields]), nt)
  return nothing
end

function mktestseis()
  L0 = 30
  L1 = 10
  os = 5
  tt = time()
  t1 = round(Int64, tt/μs)
  t2 = round(Int64, (L0+os)/μs) + t1

  S = SeisData(5)
  S.name = ["Channel 1", "Channel 2", "Channel 3", "Channel 4", "Channel 5"]
  S.id = ["XX.TMP01.00.BHZ","XX.TMP01.00.BHN","XX.TMP01.00.BHE","CC.LON..BHZ","UW.SEP..EHZ"]
  S.fs = collect(Main.Base.Iterators.repeated(100.0, S.n))
  S.fs[4] = 20.0
  for i = 1:S.n
    os1 = round(Int64, 1/(S.fs[i]*μs))
    S.x[i] = randn(Int(L0*S.fs[i]))
    S.t[i] = [1 t1+os1; length(S.x[i]) 0]
  end

  T = SeisData(4)
  T.name = ["Channel 6", "Channel 7", "Channel 8", "Channel 9"]
  T.id = ["XX.TMP02.00.EHZ","XX.TMP03.00.EHN","CC.LON..BHZ","UW.SEP..EHZ"]
  T.fs = collect(Main.Base.Iterators.repeated(100.0, T.n))
  T.fs[3] = 20.0
  for i = 1:T.n
    T.x[i] = randn(Int(L1*T.fs[i]))
    T.t[i] = [1 t2; length(T.x[i]) 0]
  end
  return (S,T)
end

# Tests
println(stdout,"seisdata...")
C = SeisData()

(S,T) = mktestseis()

println(stdout,"getindex...")
i_targ = 3
C = S[i_targ]
test_fields_preserved(C,S,i_targ)

D = S[i_targ:i_targ+1]
test_fields_preserved(D,S,2,i_targ+1)

println(stdout,"in...")
@assert("XX.TMP01.00.BHZ" in S.id)

println(stdout,"findid...")
@test ≈(findid("CC.LON..BHZ",S),findid(S,"CC.LON..BHZ"))
@test ≈(findid(S,"CC.LON..BHZ"),4)
@test ≈(findid(S,C),3)

println(stdout,"setindex!...")
A = SeisData(3)
setindex!(A, C, 3)
A[1:2]=D
test_fields_preserved(A, S, 2, i_targ+1)
test_fields_preserved(C, S, 3)

println(stdout,"isempty...")
D = SeisData()
@assert(isempty(D))

println(stdout,"equality (reflexive)...")
@assert(S==S)

println(stdout,"append!...")
append!(S, T)
sizetest(S, 9)

println(stdout,"deleteat!, delete! (by channel index)...")
C = deepcopy(S[4])
deleteat!(S, 4)
sizetest(S, 8)
@test ≈(length(findall(S.name.==C.name)),0)

C = deepcopy(S[3:4])
delete!(S,3:4)
nt = 6
@test ≈(S.n, nt)
@test ≈(maximum([length(getfield(S,i)) for i in datafields]), nt)
@test ≈(minimum([length(getfield(C,i)) for i in datafields]), 2)
@test ≈(length(findall(S.name.==C.name[1])).*length(findall(S.id.==C.id[1])),0)
@test ≈(length(findall(S.name.==C.name[2])).*length(findall(S.id.==C.id[2])),0)

println(stdout,"deleteat!, delete! (id string)...")
s = "CC.LON..BHZ"
delete!(S, s)
sizetest(S, 5)

s = r"EH"
S -= s
sizetest(S, 2)

println(stdout,"merge!, no common channels...")
(S,T) = mktestseis()
A=deepcopy(S[5])
B=deepcopy(T[4])
T*=S[1]
sizetest(T, 5)

println(stdout,"merge!, one common channel...")
S*=T[2]
sizetest(S, 5)

println(stdout,"...time merge functionality...")
@test ≈(S.t[2][2,1], 1+length(A.x))
@test ≈(S.t[2][2,2], (5-1/S.fs[2])*1.0e6)

println(stdout,"merge!, common channels + seisdata splat...")
(S,T) = mktestseis()
U = SeisData(S,T)
merge!(U)
sizetest(U, 7)

println(stdout,"merge! (two independent channels)...")
println(stdout,"...w/no common channels...")
U = S[1] * T[2]
sizetest(U, 2)

println(stdout,"..two identical channel ids...")
U = S[4] * T[3]
@assert(typeof(U)==SeisData)
@assert(U.id[1]==S.id[4])
@assert(U.id[1]==T.id[3])

println(stdout,"pull...")
C = pull(S,4)
@assert(C.name=="Channel 4")
@assert(S.n==4)
@assert(length(findall(S.name.=="Channel 4"))==0)

println(stdout,"note!...")
str1 = "ADGJALMGFLSFMGSLMFLChannel 5 sucks"
str2 = "HIGH SNR ON THIS CHANNEL"
note!(S,str2)
note!(S,str1)
@assert(findall([maximum([occursin(str1, S.notes[i][j]) for j=1:length(S.notes[i])]) for i = 1:S.n]) == [4])
@assert(length(findall([maximum([occursin(str2, S.notes[i][j]) for j = 1:length(S.notes[i])]) for i = 1:S.n]))==S.n)

# merge test: when we merge, does each field have exactly 7 entries?
merge!(S,T)
n_targ = 7
@test ≈(S.n, n_targ)
@test ≈(maximum([length(getfield(S,i)) for i in datafields]), n_targ)
@test ≈(minimum([length(getfield(S,i)) for i in datafields]), n_targ)

# Some new functionality added 2019-02-23
S = SeisData(randseisdata(5), SeisChannel(), SeisChannel(),
      SeisChannel(id="UW.SEP..EHZ", name="Darth Exploded",
      loc=[46.1967, -122.1875, 1440, 0.0, 0.0], x=rand(1024)))
prune!(S)
@test (S.n == 6)
J = findchan("EHZ",S)
@test (6 in J)
