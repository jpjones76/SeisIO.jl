printstyled("  nanfill, ungap\n", color=:light_green)

# Check that nanfill does not error
S = randSeisData()
Ev = SeisEvent(hdr=randSeisHdr(), data=convert(EventTraceData, deepcopy(S)))
C = deepcopy(S[1])

for i = 1:S.n
  L = length(S.x[i])
  inds = rand(1:L, div(L,2))
  S.x[i][inds] .= NaN
end
nanfill!(S)
for i = 1:S.n
  x = getindex(getfield(S, :x), i)
  @test isempty(findall(isnan.(x)))
end

for i = 1:Ev.data.n
  L = length(Ev.data.x[i])
  inds = rand(1:L, div(L,2))
  Ev.data.x[i][inds] .= NaN
end
nanfill!(Ev.data)
for i = 1:Ev.data.n
  x = getindex(getfield(getfield(Ev, :data), :x), i)
  @test isempty(findall(isnan.(x)))
end

L = length(C.x)
inds = rand(1:L, div(L,2))
C.x[inds] .= NaN
nanfill!(C)
@test isempty(findall(isnan.(C.x)))

# Test that traces of all NaNs becomes traces of all zeros
C = SeisChannel()
C.x = fill!(zeros(Float32, 128), NaN32)
nanfill!(C)
@test C.x == zeros(Float32, 128)

S = randSeisData()
U = deepcopy(S)
for i = 1:S.n
  x = getindex(getfield(S, :x), i)
  nx = lastindex(x)
  T = eltype(x)
  fill!(x, T(NaN))

  u = getindex(getfield(U, :x), i)
  fill!(u, zero(T))
end
nanfill!(S)
for i = 1:S.n
  x = getindex(getfield(S, :x), i)
  nx = lastindex(x)
  T = eltype(x)
  u = getindex(getfield(U, :x), i)
  @test T == eltype(u)
  @test S.x[i] == x == U.x[i] == u
end

# Test that ungap calls nanfill properly
Ev2 = ungap(Ev.data, tap=true)
ungap!(Ev.data, tap=true)
@test Ev.data == Ev2
ungap!(C, tap=true)
ungap!(S, tap=true)

# Ensure one segment is short enough to invoke bad behavior in ungap
Ev = randSeisEvent()
Ev.data.fs[1] = 100.0
Ev.data.x[1] = rand(1024)
Ev.data.t[1] = vcat(Ev.data.t[1][1:1,:], [5 2*ceil(S.fs[1])*sμ], [8 2*ceil(S.fs[1])*sμ], [1024 0])

redirect_stdout(out) do
  ungap!(Ev.data)
end
