printstyled(stdout,"  merge! behavior and intent\n", color=:light_green)
nx = 100
fs = 100.0
Δ = round(Int64, 1000000/fs)

id = "VV.STA1.00.EHZ"
loc = GeoLoc(lat=46.8523, lon=121.7603, el=4392.0)
loc1 = GeoLoc(lat=rand(), lon=rand(), el=rand())
resp1 = fctoresp(0.2, 1.0)
resp2 = fctoresp(2.0, 1.0)
units = "m/s"
src = "test"
t0 = 0

mkC1() = SeisChannel( id = id, name = "Channel 1",
                  loc = loc, fs = fs, resp = deepcopy(resp1), units = units,
                  src = "test channel 1",
                  notes = [tnote("New channel 1.")],
                  misc = Dict{String,Any}( "P" => 6.1 ),
                  t = [1 t0; nx 0],
                  x = randn(nx) )
mkC2() = SeisChannel( id = id, name = "Channel 2",
                  loc = loc, fs = fs, resp = deepcopy(resp1), units = units,
                  src = "test channel 2",
                  notes = [tnote("New channel 2.")],
                  misc = Dict{String,Any}( "S" => 11.0 ),
                  t = [1 t0+nx*Δ; nx 0],
                  x = randn(nx) )
mkC4() = (C = mkC2(); C.loc = loc1;
                  C.name = "Channel 4";
                  C.src = "test channel 4";
                  C.notes = [tnote("New channel 4.")]; C)
mkC5() = (C = mkC2(); C.loc = loc1;
                  C.name = "Channel 5";
                  C.src = "test channel 5";
                  C.notes = [tnote("New channel 5.")];
                  C.t = [1 t0+nx*2Δ; nx 0];
                  C)
C2_ov() = (nov = 3; C = mkC2(); C.t = [1 t0+(nx-nov)*Δ; nx 0]; C)
C3_ov() = (nov = 3; C = mkC2(); C.t = [1 t0+2*(nx-nov)*Δ; nx 0]; C)

function prandSC(c::Bool)
  if c == true
    C = randSeisChannel(c=true, nx=1000)
  else
    C = randSeisChannel(c=false, nx=10000)
  end
  C.name = randstring(20)
  C.misc = Dict{String,Any}()
  return C
end

function mk_tcat(T::Array{Array{Int64,2},1}, fs::Float64)
  L = length(T)
  τ = Array{Array{Int64,1},1}(undef,L)
  for i = 1:L
    τ[i] = t_expand(T[i], fs)
  end
  tt = sort(unique(vcat(τ...)))
  return t_collapse(tt, fs)
end

# ===========================================================================
printstyled(stdout,"    xtmerge!\n", color=:light_green)
x = randn(12)
t = sort!(rand(Int64,12))
x = vcat(x, x[1:6])
t = vcat(t, t[1:6])
xtmerge!(t, x, 10000)
@test length(t) == 12
@test length(x) == 12

# ===========================================================================
printstyled(stdout,"    removal of traces with no data or time info\n", color=:light_green)
S = SeisData(prandSC(false), prandSC(false), prandSC(false), prandSC(false))
S.x[2] = Float64[]
S.x[3] = Float64[]
S.t[4] = Array{Int64,2}(undef,0,0)
merge!(S, v=1)
basic_checks(S)
sizetest(S, 1)

printstyled(stdout,"    ability to handle irregularly-sampled data\n", color=:light_green)
C = prandSC(true)
namestrip!(C)
S = SeisData(C, prandSC(true), prandSC(true))
namestrip!(S)
for i = 2:3
  S.id[i] = identity(S.id[1])
  S.resp[i] = copy(S.resp[1])
  S.loc[i] = deepcopy(S.loc[1])
  S.units[i] = identity(S.units[1])
end
T = merge(S, v=1)
basic_checks(T)
sizetest(T, 1)

# ===========================================================================
printstyled(stdout,"    simple merges\n", color=:light_green)
printstyled(stdout,"      three channels, two w/same params, no overlapping data\n", color=:light_green)
S = SeisData(mkC1(), mkC2(), prandSC(false))

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test vcat(U.x[1], U.x[2])==S.x[i]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# Do the notes log the extra source?
@test findfirst([occursin("New channel 1", i) for i in S.notes[i]]) != nothing
@test findfirst([occursin("+src: test channel 1", i) for i in S.notes[i]]) != nothing

# Are dictionaries merging correctly?
@test haskey(S.misc[i], "P")
@test haskey(S.misc[i], "S")

printstyled(stdout, "      \"zipper\" merge I: two channels, staggered time windows, no overlap\n", color=:light_green)
S = SeisData(mkC1(), mkC2())
W = Array{Int64,2}(undef, 8, 2);
for i = 1:8
  W[i,:] = t0 .+ [(i-1)*nx*Δ ((i-1)*nx + nx-1)*Δ]
end
w1 = W[[1,3,5,7], :]
w2 = W[[2,4,6,8], :]
S.t[1] = w_time(w1, Δ)
S.t[2] = w_time(w2, Δ)
S.x[1] = randn(4*nx)
S.x[2] = randn(4*nx)
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 1
@test S.t[1] == [1 t0; 8*nx 0]

# ===========================================================================
# (II) as (I) with another channel at a new location
printstyled(stdout,"    channels must have identical :fs, :loc, :resp, and :units to merge \n", color=:light_green)
S = SeisData(mkC1(), mkC2(), prandSC(false), mkC4())

U = deepcopy(S)
merge!(S)
@test S.n == 3
basic_checks(S)
# Are there two channels with the same ID?
@test length(findall(S.id.==id)) == 2

# Is the subgroup merged correctly?
i = findfirst(S.src.=="test channel 2")
@test S.loc[i] == loc
@test mk_tcat(U.t[1:2], fs) == S.t[i]
@test vcat(U.x[1], U.x[2]) == S.x[i]

# Is the odd channel left alone?
j = findfirst(S.src.=="test channel 4")
@test S.loc[j] == loc1
for i in datafields
  if i != :notes
    @test getfield(U, i)[4] == getfield(S, i)[j]
  end
end

# with a second channel at the new location
S = SeisData(deepcopy(U), mkC5())
U = deepcopy(S)
merge!(S)
@test S.n == 3
basic_checks(S)

# Are there two channels with the same ID?
@test length(findall(S.id.==id)) == 2

# Is the first subgroup merged correctly?
i = findfirst(S.src.=="test channel 2")
@test S.loc[i] == loc
@test mk_tcat(U.t[1:2], fs) == S.t[i]
@test vcat(U.x[1], U.x[2]) == S.x[i]

# Is the second subgroup merged correctly?
j = findfirst(S.src.=="test channel 5")
@test S.loc[j] == loc1
@test mk_tcat(U.t[4:5], fs) == S.t[j]
@test vcat(U.x[4], U.x[5]) == S.x[j]

# with resp, not loc
S = deepcopy(U)
S.loc[4] = deepcopy(loc)
S.loc[5] = deepcopy(loc)
S.resp[4] = deepcopy(resp2)
S.resp[5] = deepcopy(resp2)

U = deepcopy(S)
merge!(S)
@test S.n == 3
basic_checks(S)

# Are there two channels with the same ID?
@test length(findall(S.id.==id)) == 2

# Is the first subgroup merged correctly?
i = findfirst(S.src.=="test channel 2")
@test S.loc[i] == loc
@test mk_tcat(U.t[1:2], fs) == S.t[i]
@test vcat(U.x[1], U.x[2]) == S.x[i]

# Is the second subgroup merged correctly?
j = findfirst(S.src.=="test channel 5")
@test S.resp[j] == resp2
@test mk_tcat(U.t[4:5], fs) == S.t[j]
@test vcat(U.x[4], U.x[5]) == S.x[j]

# ===========================================================================
printstyled(stdout,"    one merging channel with a time gap\n", color=:light_green)
S = SeisData(mkC1(), mkC2(), prandSC(false))
S.x[2] = rand(2*nx)
S.t[2] = vcat(S.t[2][1:1,:], [nx 2*Δ], [2*nx 0])

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test U.x[1] == S.x[i][1:nx]
@test U.x[2][1:nx] == S.x[i][nx+1:2nx]
@test U.x[2][nx+1:2nx] == S.x[i][2nx+1:3nx]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

printstyled(stdout,"      merge window is NOT the first\n", color=:light_green)
os = 2
S = SeisData(mkC1(), mkC2(), prandSC(false))
S.x[1] = rand(2*nx)
S.t[1] = vcat(S.t[1][1:1,:], [nx os*Δ], [2*nx 0])
S.t[2][1,2] += (os+nx)*Δ
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test U.x[1] == S.x[i][1:2nx]
@test U.x[2] == S.x[i][2nx+1:3nx]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# ===========================================================================
printstyled(stdout,"    one merge group has non-duplication time overlap\n", color=:light_green)
printstyled(stdout,"      check for averaging\n", color=:light_green)
nov = 3
S = SeisData(mkC1(), C2_ov(), prandSC(false))

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)

@test S.n == 2
i = findid(id, S)
@test S.x[i][1:nx-nov] == U.x[1][1:nx-nov]
@test S.x[i][nx-nov+1:nx] == 0.5*(U.x[1][nx-nov+1:nx] + U.x[2][1:nov])
@test S.x[i][nx+1:2nx-nov] == U.x[2][nov+1:nx]
@test S.t[i] == [1 U.t[1][1,2]; 2nx-nov 0]

# Do the notes log the extra source?
@test findfirst([occursin("New channel 1", i) for i in S.notes[i]]) != nothing
@test findfirst([occursin("+src: test channel 1", i) for i in S.notes[i]]) != nothing

# Are dictionaries merging correctly?
@test haskey(S.misc[i], "P")
@test haskey(S.misc[i], "S")

printstyled(stdout,"      src overlap window is NOT first\n", color=:light_green)
os = 2
S = SeisData(mkC1(), C2_ov(), prandSC(false))
S.x[1] = rand(2*nx)
S.t[1] = vcat(S.t[1][1:1,:], [nx os*Δ], [2*nx 0])
S.t[2][1,2] += (os+nx)*Δ
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test S.x[i][1:2nx-nov] == U.x[1][1:2nx-nov]
@test S.x[i][2nx-nov+1:2nx] == 0.5*(U.x[1][2nx-nov+1:2nx] + U.x[2][1:nov])
@test S.x[i][2nx+1:3nx-nov] == U.x[2][nov+1:nx]
@test S.t[i] == vcat(U.t[1][1:2,:], [length(S.x[i]) 0])

printstyled(stdout,"      dest overlap window is NOT first\n", color=:light_green)
nov = 3
S = SeisData(mkC1(), C2_ov(), prandSC(false))
S.x[2] = rand(2*nx)
S.t[2] = [1 t0-nx*Δ; nx+1 Δ*(nx-nov); 2*nx 0]

U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test S.x[i][1:nx] == U.x[2][1:nx]
@test S.x[i][nx+1:2nx-nov] == U.x[1][1:nx-nov]
@test S.x[i][2nx-nov+1:2nx] == 0.5*(U.x[1][nx-nov+1:nx] + U.x[2][nx+1:nx+nov])
@test S.x[i][2nx+1:3nx-nov] == U.x[2][nx+nov+1:2nx]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# ===========================================================================
printstyled(stdout,"    overlap with time mismatch\n", color=:light_green)

#= mk_tcat stops working here as merge shifts one window back in
time one sample to account for the intentional one-Δ time mismatch =#

printstyled(stdout,"      data overlap one sample off of S.t\n", color=:light_green)

# (a) 3_sample overlap with wrong time (C2[1:2] == C1[99:100])
nov = 2
S = SeisData(mkC1(), C2_ov())
S.x[2] = vcat(copy(S.x[1][nx-nov+1:nx]), rand(nx-nov))
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 1
i = findid(id, S)
@test length(S.x[i]) == 2nx-nov
@test S.x[i][1:nx-nov] == U.x[1][1:nx-nov]
@test S.x[i][nx-nov+1:nx] == U.x[1][nx-nov+1:nx] == U.x[2][1:nov]
@test S.x[i][nx+1:2nx-nov] == U.x[2][nov+1:nx]
@test S.t[i] == [1 U.t[1][1,2]-Δ; 2nx-nov 0]

printstyled(stdout,"      src overlap window is NOT first\n", color=:light_green)
S = deepcopy(U)
S.x[1] = rand(2*nx)
S.t[1] = vcat(S.t[1][1:1,:], [nx os*Δ], [2*nx 0])
S.x[2] = vcat(copy(S.x[1][2nx-nov+1:2nx]), rand(nx-nov))
S.t[2][1,2] += (os+nx)*Δ
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 1
i = findid(id, S)
@test S.x[i][1:2nx-nov] == U.x[1][1:2nx-nov]
@test S.x[i][2nx-nov+1:2nx] == U.x[1][2nx-nov+1:2nx] == U.x[2][1:nov]
@test S.x[i][2nx+1:3nx-nov] == U.x[2][nov+1:nx]
@test S.t[i] == [1 0; U.t[1][2,1] U.t[1][2,2]-Δ; 3nx-nov 0]

#= mk_tcat starts working again here as the time shift is now
applied to the second window, rather than the first. =#

printstyled(stdout,"      dest overlap window is NOT first\n", color=:light_green)
S = SeisData(mkC1(), C2_ov())
S.t[2] = [1 t0-nx*Δ; nx+1 Δ*(nx-nov); 2*nx 0]
S.x[2] = vcat(randn(nx), copy(S.x[1][nx-nov+1:nx]), randn(nx-nov))
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 1
i = findid(id, S)
@test S.x[i][1:nx] == U.x[2][1:nx]
@test S.x[i][nx+1:2nx-nov] == U.x[1][1:nx-nov]
@test S.x[i][2nx-nov+1:2nx] == U.x[1][nx-nov+1:nx] == U.x[2][nx+1:nx+nov]
@test S.x[i][2nx+1:3nx-nov] == U.x[2][nx+nov+1:2nx]
@test mk_tcat(U.t[1:2], fs) == S.t[i]


# ===========================================================================
printstyled(stdout,"    multichannel merge with overlap\n", color=:light_green)
breakpt_1 = nx-nov        # 97
breakpt_2 = 2*(nx-nov)-1  # 195
breakpt_3 = 2*(nx-nov)+2  # 198

S = SeisData(mkC1(), C2_ov(), C3_ov(), prandSC(false))
S.x[2] = vcat(copy(S.x[1][nx-nov+1:nx]), rand(nx-nov))
U = deepcopy(S)
merge!(S)
basic_checks(S)
i = findid(id, S)
@test S.n == 2
@test S.x[i][1:breakpt_1] == U.x[1][1:nx-nov]
@test S.x[i][breakpt_1+1:nx] == U.x[1][nx-nov+1:nx] == U.x[2][1:nov]
@test S.x[i][nx+1:breakpt_2] == U.x[2][nov+1:nx-nov-1]
@test S.x[i][breakpt_2+1:breakpt_3] == 0.5*(U.x[2][nx-nov:nx] + U.x[3][1:nov+1])
@test S.x[i][breakpt_3+1:end] == U.x[3][nov+2:end]
@test S.t[i] == [1 U.t[1][1,2]-Δ; 3nx-2nov-1 0]

# What happens when there's a gap in one trace?
breakpt_4 = length(S.x[i])
S = deepcopy(U)
S.x[3] = rand(2*nx)
S.t[3] = vcat(S.t[3][1:1,:], [nx 2*Δ], [2*nx 0])
@test w_time(t_win(S.t[3], Δ), Δ)  == S.t[3]
U = deepcopy(S)
merge!(S)
basic_checks(S)
i = findid(id, S)
@test S.t[i] == [1 t0-Δ; 295 2*Δ; 395 0]
@test S.x[i][1:breakpt_1] == U.x[1][1:nx-nov]
@test S.x[i][breakpt_1+1:nx] == U.x[1][nx-nov+1:nx] == U.x[2][1:nov]
@test S.x[i][nx+1:breakpt_2] == U.x[2][nov+1:nx-nov-1]
@test S.x[i][breakpt_2+1:breakpt_3] == 0.5*(U.x[2][nx-nov:nx] + U.x[3][1:nov+1])
@test S.x[i][breakpt_3+1:breakpt_4] == U.x[3][nov+2:nx]
@test S.x[i][breakpt_4+1:end] == U.x[3][nx+1:end]

# ===========================================================================
printstyled(stdout,"    \"zipper\" merges II\n", color=:light_green)
printstyled(stdout,"      two traces with staggered time windows, some with overlap\n", color=:light_green)

# (a) One overlap in a late window should not shift back previous windows
nov = 2
S = SeisData(mkC1(), mkC2())
W = Array{Int64,2}(undef, 8, 2);
for i = 1:8
  W[i,:] = t0 .+ [(i-1)*nx*Δ ((i-1)*nx + nx-1)*Δ]
end
W[8,1] -= nov*Δ
W[8,2] -= nov*Δ
w1 = W[[1,3,5,7], :]
w2 = W[[2,4,6,8], :]
S.t[1] = w_time(w1, Δ)
S.t[2] = w_time(w2, Δ)
S.x[1] = randn(4*nx)
S.x[2] = randn(4*nx)
U = deepcopy(S)
merge!(S)
basic_checks(S)
i = findid(id, S)
@test S.n == 1
@test S.t[i] == [1 t0; 8*nx-nov 0]

# These should be untouched
for j = 1:6
  si = 1 + nx*(j-1)
  ei = nx*j
  k = div(j,2)
  if isodd(j)
    usi = k*nx + 1
    uei = usi + nx - 1
    @test S.x[i][si:ei] == U.x[1][usi:uei]
  else
    usi = (k-1)*nx + 1
    uei = usi + nx - 1
    @test S.x[i][si:ei] == U.x[2][usi:uei]
  end
end

# The only overlap should be here:
@test S.x[i][1+6nx:7nx-nov] == U.x[1][1+3nx:4nx-nov]
@test S.x[i][7nx-nov+1:7nx] == 0.5*(U.x[1][4nx-nov+1:4nx] .+ U.x[2][3nx+1:3nx+nov])
@test S.x[i][7nx+1:8nx-nov] == U.x[2][3nx+nov+1:4nx]

printstyled(stdout,"      one overlap, late window, time mismatch\n", color=:light_green)
nov = 3
true_nov = 2
S = SeisData(mkC1(), mkC2())
W = Array{Int64,2}(undef, 8, 2);
for i = 1:8
  W[i,:] = t0 .+ [(i-1)*nx*Δ ((i-1)*nx + nx-1)*Δ]
end
W[8,1] -= nov*Δ
W[8,2] -= nov*Δ
w1 = W[[1,3,5,7], :]
w2 = W[[2,4,6,8], :]
S.t[1] = w_time(w1, Δ)
S.t[2] = w_time(w2, Δ)
S.x[1] = randn(4*nx)
S.x[2] = randn(4*nx)
S.x[2][3nx+1:3nx+2] = copy(S.x[1][4nx-1:4nx])
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 1
for j = 1:5
  si = 1 + nx*(j-1)
  ei = nx*j
  k = div(j,2)
  if isodd(j)
    usi = k*nx + 1
    uei = usi + nx - 1
    @test S.x[i][si:ei] == U.x[1][usi:uei]
  else
    usi = (k-1)*nx + 1
    uei = usi + nx - 1
    @test S.x[i][si:ei] == U.x[2][usi:uei]
  end
end
δi = nov - true_nov

# Because we moved the start time of 2:3 back by 1, we expect:
@test S.x[i][1+5nx:6nx-δi] == U.x[2][1+2nx:3nx-δi]

# Thus there's a one-point overlap (that gets resolved by averaging) at:
@test S.x[i][6nx-δi+1:6nx] == 0.5*(U.x[2][3nx-δi+1:3nx] + U.x[1][3nx+1:3nx+δi])

# Proceeding through the merged time series, we expect:
@test S.x[i][6nx+1:7nx-nov] == U.x[1][3nx+δi+1:4nx-true_nov]
@test S.x[i][7nx-nov+1:7nx-δi] == U.x[1][4nx-true_nov+1:4nx] == U.x[2][3nx+1:3nx+true_nov]
@test S.x[i][7nx-δi+1:end] == U.x[2][3nx+true_nov+1:end]

# ============================================================================
printstyled(stdout,"    distributivity: S1*S3 + S2*S3 == (S1+S2)*S3\n", color=:light_green)
imax = 10
printstyled("      trial ", color=:light_green)
for i = 1:imax
  if i > 1
    print("\b\b\b\b\b")
  end
  printstyled(string(lpad(i, 2), "/", imax), color=:light_green)
  S1 = randSeisData()
  S2 = randSeisData()
  S3 = randSeisData()
  # M1 = (S1+S2)*S3
  # M2 = S1*S3 + S2*S3
  @test ((S1+S2)*S3) == (S1*S3 + S2*S3)
  if i == imax
    println("")
  end
end

# ============================================================================
printstyled(stdout,"    checking (formerly-breaking) end-member cases\n", color=:light_green)
printstyled(stdout,"      time windows not in chronological order\n", color=:light_green)
C1 = mkC1()
C2 = mkC2()
C3 = deepcopy(C1)
C3.t = [1 0; 101 -2000000; 200 0]
append!(C3.x, randn(100))
S = SeisData(C3, C2, prandSC(false))

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test S.t[i] == [1 -1000000; 300 0]
@test vcat(U.x[1][101:200], U.x[1][1:100], U.x[2]) == S.x[i]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# Do the notes log the extra source?
@test findfirst([occursin("New channel 1", j) for j in S.notes[i]]) != nothing
@test findfirst([occursin("+src: test channel 1", j) for j in S.notes[i]]) != nothing

# Are dictionaries merging correctly?
@test haskey(S.misc[i], "P")
@test haskey(S.misc[i], "S")

printstyled(stdout,"      sequential one-sample windows\n", color=:light_green)
C1 = mkC1()
C2 = mkC2()
C2.t = [1 1200000; 99 90059; 100 90210]
C2.t = [1 1000000; 99 90059; 100 90210]
S = SeisData(C1, C2, prandSC(false))

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test S.t[i] == [1  0; 199  90059; 200  90210]
@test vcat(U.x[1], U.x[2])==S.x[i]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# Do the notes log the extra source?
@test findfirst([occursin("New channel 1", j) for j in S.notes[i]]) != nothing
@test findfirst([occursin("+src: test channel 1", j) for j in S.notes[i]]) != nothing

# Are dictionaries merging correctly?
@test haskey(S.misc[i], "P")
@test haskey(S.misc[i], "S")

# ============================================================================
printstyled(stdout,"  merge! and new/extended methods\n", color=:light_green)
fs1 = 50.0
Δ = round(Int64, sμ/fs1)

# t1 = round(Int64,time()/μs)
t1 = 0

# s1 and s2 represent data from a fictitious channel
# s2 begins 1 second later, but has a gap of 1s after sample 25
s1 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1 t1; 100 0], x=randn(100))
s2 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1 t1+1000000; 26 1000000; 126 200000; 150 0], x=randn(150))


s3 = SeisChannel(fs = 100.0, gain = 5.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1 t1; 100 0], x=rand(100).-0.5)
s4 = SeisChannel(fs = 100.0, gain = 50.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1 t1+1000000; 100 1000000; 150 0], x=randn(150))

# We expect:
# (1) LAST 25-26 points in s1 will be averaged with first 25 points in s3
# (2) s3 will be ungapped with exactly 50 samples of junk
# (3) after sync of a seisobj formed from [s1+s3, s2], s2 will be padded with 0.5s
# at start and 3s at end

S = SeisData()
for i in fieldnames(typeof(S))
  if i != :n
    @test ≈(isempty([]), isempty(getfield(S,i)))
  end
end

printstyled("    fixing data gaps\n", color=:light_green)
s2u = ungap(s2)
@test length(s2.x) / s2.fs + μs * sum(s2.t[2:end - 1, 2]) ≈ length(s2u.x) / s2u.fs

printstyled("    channel add and simple merges\n", color=:light_green)
S = S + (s1 * s2)

# Do in-place operations only change leftmost variable?
@test length(s1.x) ≈ 100
@test length(s2.x) ≈ 150

# expected behavior for S = s1+s2
# (0) length[s.x[1]] = 250
# (1) S.x[1][1:50] = s1.x[1:50]
# (2) S.x[1][51:75] = 0.5.*(s1.x[51:75] + s2.x[1:25])
# (3) S.x[1][76:100] = s1.x[76:100]
# (4) S.x[1][101:125] = mean(S.x[1])
# (5) S.x[1][126:250] = s2.x[126:250]

# Basic merge ops
@test S.n == 1
@test length(S.fs) == 1
@test ==(S.fs[1], s1.fs)
@test ==(length(S.gain), 1)
@test ==(S.gain[1], s1.gain)
@test ==(length(S.name), 1)
@test ==(length(S.t),1)
@test ==(length(S.x),1)
@test S.id[1]=="DEAD.STA..EHZ"
U = deepcopy(S)
ungap!(S, m=false, tap=false) # why do I have to force type here
@test ==(length(S.x[1]), 260)
@test ==(S.x[1][1:50], s1.x[1:50])
@test ==(S.x[1][51:75], 0.5.*(s1.x[51:75] .+ s2.x[1:25]))
@test ==(S.x[1][76:100], s1.x[76:100])
@test minimum(isnan.(S.x[1][101:125]))
@test ==(S.x[1][126:225], s2.x[26:125])
@test minimum(isnan.(S.x[1][226:235]))
@test ==(S.x[1][236:260], s2.x[126:150])

# Auto-tapering after a merge
T = deepcopy(S)
ii = findall(isnan.(S.x[1]))
nanfill!(S)
taper!(S, N_min = 0)
@test length(findall(isnan.(S.x[1])))==0          # No more NaNs?
@test sum(diff(S.x[1][ii]))==0                    # All NaNs filled w/same val?
@test ≈(T.x[1][15:90], S.x[1][15:90])             # Un-windowed vals untouched?

printstyled("    channel delete\n", color=:light_green)
S -= 1
for i in fieldnames(typeof(S))
  if i != :n
    @test ≈(isempty([]), isempty(getfield(S,i)))
  end
end
@test isempty(S)

printstyled("    a more difficult merge\n", color=:light_green)
S = SeisData()
S *= (s1 * s3)
S *= (s2 * s4)
@test ≈(S.n, 2)
@test ≈(length(S.fs), 2)
@test ≈(length(S.gain), 2)
@test ≈(length(S.name), 2)
@test ≈(length(S.t),2)
@test ≈(length(S.x),2)
i = findid("DEAD.STA..EHE", S)
j = findid("DEAD.STA..EHZ", S)
@test ≈(S.fs[i], 100.0)
@test ≈(S.gain[j], 10.0)
ungap!(S, m=false, tap=false)
@test ≈(length(S.x[j]), 260)
@test ≈(length(S.x[i]), 350)
@test ≈(S.x[i][101]/S.gain[i], s4.x[1]/s4.gain)

printstyled("    fastmerge!\n", color=:light_green)

# Repeating data
loc1 = GeoLoc(lat=45.28967, lon=-121.79152, el=1541.0)
loc2 = GeoLoc(lat=48.78384, lon=-121.90093, el=1676.0)


s1 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
t = [1 t1; 100 0], x=randn(100))
s2 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1 t1+1000000; 150 0], x=vcat(s1.x[51:100], randn(100)))
C = (s1 * s2)[1]
@test length(C.x) == 200
@test C.x[1:100] == s1.x
@test C.x[101:200] == s2.x[51:150]

# Simple overlapping times
os = 50
nx = length(s1.x)
lx = length(s1.x)/s1.fs
τ = round(Int, 1.0e6*(2.0-os/fs1))
s2 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1 t1+τ; 150 0], x=randn(150))
C = (s1 * s2)[1]
@test length(C.x) == 250-os
@test C.x[1:nx-os] == s1.x[1:os]
@test C.x[nx-os+1:nx] == 0.5.*(s1.x[nx-os+1:nx]+s2.x[1:os])
@test C.x[nx+1:200] == s2.x[os+1:150]

# two-sample offset
os = 2
nx = length(s1.x)
lx = length(s1.x)/s1.fs
τ = round(Int, 1.0e6*(2.0-(os-1)/fs1))
s2 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1 t1+τ; 150 0], x=vcat(copy(s1.x[nx-os+1:nx]), randn(150-os)))
@test s1.x[nx] == s2.x[os]
C = (s1 * s2)[1]
@test length(C.x) == 250-os+1
@test C.x[1:99] == s1.x[1:99]
@test C.x[100] == 0.5*(s2.x[1] + s1.x[100])
@test C.x[101:249] == s2.x[2:150]

# Ensure merge works correctly with traces separated in time
printstyled("    operator \"*\"\n", color=:light_green)
s5 = SeisChannel(fs = 100.0, loc=loc1, gain = 32.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1 t1; 100 0], x=randn(100))
s6 = SeisChannel(fs = 100.0, loc=loc1, gain = 16.0, name = "UNNAMED", id = "DEAD.STA..EHE",
  t = [1 t1+30000000; 200 0], x=randn(200))
T = (s5 * s6)
ungap!(T)
@test ≈(length(T.x[1]),3200)


printstyled(stdout,"    SeisData * SeisChannel ==> SeisData\n", color=:light_green)
(S,T) = mktestseis()
merge!(S,T)
C = prandSC(false)
D = prandSC(false)
U = merge(S,C)
U = sort(U)
V = merge(C,S)
V = sort(V)
@test U == V
U = merge(C,D)

(S,T) = mktestseis()
A = deepcopy(S[5])
B = deepcopy(T[4])
T*=S[1]
sizetest(T, 5)

printstyled(stdout,"    SeisData merge tests\n", color=:light_green)
printstyled(stdout,"      one common channel (fast, no gaps)\n", color=:light_green)
(S,T) = mktestseis()
t = t_expand(S.t[4], S.fs[4])
T.t[3][1,2] = t[end] + t[end]-t[end-1]
merge!(T, S[4])

printstyled(stdout,"      one common channel (slow, has gaps)\n", color=:light_green)
(S,T) = mktestseis()
A = deepcopy(S[5])
B = deepcopy(T[4])
T*=S[1]
sizetest(T, 5)

T = sort(T)
S*=T[2]
sizetest(S, 5)
i = findid(A, S)
@test ≈(S.t[i][2,1], 1+length(A.x))
@test ≈(S.t[i][2,2], (5-1/S.fs[i])*1.0e6)

printstyled(stdout,"      common channels and \"splat\" notation (mseis!)\n", color=:light_green)
(S,T) = mktestseis()
U = merge(S,T)
sizetest(U, 7)

V = SeisData(S,T)
merge!(V)
@test U == V

mseis!(S,T)
@test S == V

printstyled(stdout,"      mseis! with Types from SeisIO.Quake\n", color=:light_green)
S = randSeisData()
Ev = randSeisEvent(1)
Ev.data.az[1] = 0.0
Ev.data.baz[1] = 0.0
Ev.data.dist[1] = 0.0
mseis!(S,   randSeisChannel(),
            convert(EventChannel, randSeisChannel()),
            rand(Float64, 23),  # should warn
            convert(EventTraceData, randSeisData()),
            Ev,
            randSeisEvent())

printstyled(stdout,"      two independent channels ==> same as \"+\"\n", color=:light_green)
(S,T) = mktestseis()
U = S[1] * T[2]
sizetest(U, 2)
@test U == S[1]+T[2]

printstyled(stdout,"      two identical channel IDs\n", color=:light_green)
U = S[4] * T[3]
@test typeof(U)==SeisData
@test U.id[1]==S.id[4]
@test U.id[1]==T.id[3]

printstyled(stdout,"    pull\n", color=:light_green)
ux = Float64.(randperm(800))
C = pull(S,4)
C.x = ux[1:600]
@test C.name=="Longmire"
@test S.n==4
@test length(findall(S.name.=="Longmire"))==0

printstyled(stdout,"      notes still faithfully track names in modified objects\n", color=:light_green)
str1 = "ADGJALMGFLSFMGSLMFLSeptember Lobe sucks"
str2 = "HIGH SNR ON THIS CHANNEL"
note!(S,str2)
note!(S,str1)
@test (findall([maximum([occursin(str1, S.notes[i][j]) for j=1:length(S.notes[i])]) for i = 1:S.n]) == [4])
@test (length(findall([maximum([occursin(str2, S.notes[i][j]) for j = 1:length(S.notes[i])]) for i = 1:S.n]))==S.n)

# merge test: when we merge, does each field have exactly 7 entries?
printstyled(stdout,"      merge! after pull doesn't affect pulled channel\n", color=:light_green)
T.x[3] = ux[601:800]
merge!(S,T)
n_targ = 7
@test ≈(S.n, n_targ)
@test ≈(maximum([length(getfield(S,i)) for i in datafields]), n_targ)
@test ≈(minimum([length(getfield(S,i)) for i in datafields]), n_targ)
@test any(maximum([C.x.==i for i in S.x[1]])) == false

# Old: (Test Passed, 1.42978256,  154864097, 0.038663895, Base.GC_Diff(154864097, 109, 0, 1845386, 4165, 0,  38663895, 7, 0))
# New: (Test Passed, 1.263168574, 128490661, 0.108295874, Base.GC_Diff(128490661,  81, 0, 1324714, 3857, 0, 108295874, 6, 1))

printstyled(stdout,"      purge!\n", color=:light_green)
(S,T) = mktestseis()
S.t[5] = Array{Int64,2}(undef,0,2)
S.x[5] = Array{Float32,1}(undef,0)
U = purge(S)
purge!(S)
@test S == U
@test S.n == 4
