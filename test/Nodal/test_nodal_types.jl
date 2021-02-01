printstyled("  Nodal types\n", color=:light_green)
printstyled("    method extensions\n", color=:light_green)
fs = 100.0
j = 7
j1 = 3
j2 = 5
j3 = 6
j4 = 8
nc = 10
nx = 2^12
v1 = 3.0
v2 = 4.0
J = j1:j2

printstyled("      append!\n", color=:light_green)
U = read_nodal("silixa", fstr)
S = deepcopy(U)
S2 = S[j1:j2]
n = S.n
append!(S, S2)
@test S.n == n + S2.n
for f in SeisIO.Nodal.nodalfields
  F1 = getfield(S, f)
  F2 = getfield(S2, f)
  for (i,j) in enumerate(n+1:n+S2.n)
    @test F1[j] == F2[i]
  end
end
@test S.data[:, n+1:n+S2.n] == S2.data

printstyled("      convert\n", color=:light_green)
printstyled("        NodalChannel ⟺ SeisChannel\n", color=:light_green)
C = randSeisChannel()
C1 = convert(NodalChannel, C)
C2 = convert(SeisChannel, C1)
@test C == C2

printstyled("        NodalChannel ⟺ EventChannel\n", color=:light_green)
C1 = EventChannel(C)
C2 = convert(NodalChannel, C1)
C3 = convert(SeisChannel, C2)
@test typeof(C1) == EventChannel
@test typeof(C2) == NodalChannel
@test C == C3

printstyled("        NodalData ⟺ SeisData\n", color=:light_green)
S = randSeisData(nc, nx=nx, s=1.0)
t = mk_t(nx, S.t[1][1,2])
for i in 1:S.n
  S.fs[i] = fs
  S.t[i] = copy(t)
end
D = convert(NodalData, S)
for f in SeisIO.Nodal.nodalfields
  @test length(getfield(D, f)) == nc
end
@test size(D.data) == (nx, nc)
@test NodalData(S) == D

S = convert(SeisData, U)
for i in 1:S.n
  @test isapprox(S.x[i], U.x[i])
end
@test SeisData(U) == S

printstyled("        NodalData ⟺ EventTraceData\n", color=:light_green)
Ev = convert(EventTraceData, S)
D = convert(NodalData, Ev)
@test typeof(Ev) == EventTraceData
for f in SeisIO.Nodal.nodalfields
  @test length(getfield(D, f)) == S.n
end
@test size(D.data) == size(U.data)
@test NodalData(Ev) == D
@test EventTraceData(D) == Ev

printstyled("      deleteat!\n", color=:light_green)
S = deepcopy(U)
deleteat!(S, 3)
@test S.data[:, 1:2] == U.data[:, 1:2]
@test S.data[:, 3:S.n] == U.data[:, 4:U.n]

S = deepcopy(U)
deleteat!(S, J)
@test S.data[:, 1:2] == U.data[:, 1:2]
@test S.data[:, 3:S.n] == U.data[:, 6:U.n]

printstyled("      getindex\n", color=:light_green)
S = deepcopy(U)

C = S[j]
@test S.data[:,j] == C.x
for f in SeisIO.Nodal.nodalfields
  F = getfield(S, f)
  @test getindex(F, j) == getfield(C, f)
end

S2 = S[j1:j2]
for f in SeisIO.Nodal.nodalfields
  F1 = getfield(S, f)
  F2 = getfield(S2, f)
  for (i,j) in enumerate(j1:j2)
    @test F1[j] == F2[i]
  end
end
@test S.data[:, j1:j2] == S2.data

printstyled("      isempty\n", color=:light_green)
S = NodalData()
@test isempty(S) == true
C = NodalChannel()
@test isempty(C) == true
L = NodalLoc()
@test isempty(L) == true

printstyled("      isequal\n", color=:light_green)
S = deepcopy(U)
@test S == U
S = NodalData()
T = NodalData()
@test S == T

C = NodalChannel()
D = NodalChannel()
@test C == D

L1 = NodalLoc()
L2 = NodalLoc()
@test L1 == L2

printstyled("      push!\n", color=:light_green)
U = read_nodal("silixa", fstr)
S = deepcopy(U)
n = S.n
C = S[S.n]
push!(S, C)
@test S.n == n + 1
for f in SeisIO.Nodal.nodalfields
  F1 = getindex(getfield(S, f), n)
  F2 = getfield(C, f)
  @test F1 == F2
end
@test S.data[:, n+1] == S.data[:, n]
@test ===(S.data[:, n+1], S.data[:, n]) == false

D = convert(SeisChannel, C)
push!(S, D)

printstyled("      setindex!\n", color=:light_green)
S = deepcopy(U)
S2 = getindex(S, j1:j2)
setindex!(S, S2, j3:j4)
@test S.data[:,j1:j2] == S.data[:, j3:j4]

C = S[j2]
setindex!(S, C, j1)
@test S.data[:, j1] == S.data[:, j2]

printstyled("      show\n", color=:light_green)
redirect_stdout(out) do

  for i = 1:10
    for T in (NodalLoc, NodalChannel, NodalData)
      repr(T(), context=:compact=>true)
      repr(T(), context=:compact=>false)
      show(T())
    end
  end
end

printstyled("      sizeof\n", color=:light_green)
S = deepcopy(U)

# Add some notes
for j in 1:3
  j_min = rand(1:3)
  j_max = rand(j_min:S.n)
  note!(S, j_min:j_max, randstring(rand(1:100)))
end

# Add some things to :misc
for i in 1:4
  j_min = rand(1:3)
  j_max = rand(j_min:S.n)

  # add 1-6 entries each to the :misc field of each channel
  for j in j_min:j_max
    D = S.misc[j]
    pop_nodal_dict!(D, n=rand(1:6))
  end
end
@test sizeof(S) > 168

C = S[1]
note!(C, randstring(rand(1:100)))
note!(C, randstring(rand(1:100)))
pop_nodal_dict!(C.misc, n=rand(3:18))
@test sizeof(C) > 120

printstyled("      sort!\n", color=:light_green)
S = deepcopy(U)
id1 = S.id[1]
id2 = S.id[2]
S.id[1] = id2
S.id[2] = id1
sort!(S)
@test S.data[:,1] == U.data[:,2]
@test S.data[:,2] == U.data[:,1]
S.x[1][1] = v1
S.x[2][1] = v2
@test S.data[1,1] == v1
@test S.data[1,2] == v2
