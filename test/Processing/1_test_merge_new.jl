import SeisIO: xtmerge!
printstyled(stdout,"  merge! behavior and intent\n", color=:light_green)
nx = 100
fs = 100.0
Δ = round(Int64, 1000000/fs)

id = "VV.STA1.00.EHZ"
loc = [46.8523, 121.7603, 4392.0, 0.0, 0.0]
loc1 = rand(Float64,3)
resp = fctopz(0.2)
resp1 = fctopz(2.0)
units = "m/s"
src = "test"
t0 = 0

C1() = SeisChannel( id = id, name = "Channel 1",
                  loc = loc, fs = fs, resp = resp, units = units,
                  src = "test channel 1",
                  notes = [tnote("New channel 1.")],
                  misc = Dict{String,Any}( "P" => 6.1 ),
                  t = [1 t0; nx 0],
                  x = randn(nx) )
C2() = SeisChannel( id = id, name = "Channel 2",
                  loc = loc, fs = fs, resp = resp, units = units,
                  src = "test channel 2",
                  notes = [tnote("New channel 2.")],
                  misc = Dict{String,Any}( "S" => 11.0 ),
                  t = [1 t0+nx*Δ; nx 0],
                  x = randn(nx) )
C4() = (C = C2(); C.loc = loc1;
                  C.name = "Channel 4";
                  C.src = "test channel 4";
                  C.notes = [tnote("New channel 4.")]; C)
C5() = (C = C2(); C.loc = loc1;
                  C.name = "Channel 5";
                  C.src = "test channel 5";
                  C.notes = [tnote("New channel 5.")];
                  C.t = [1 t0+nx*2Δ; nx 0];
                  C)
C2_ov() = (nov = 3; C = C2(); C.t = [1 t0+(nx-nov)*Δ; nx 0]; C)
C3_ov() = (nov = 3; C = C2(); C.t = [1 t0+2*(nx-nov)*Δ; nx 0]; C)

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
printstyled(stdout,"    Removal of traces with no data or time info\n", color=:light_green)
S = randSeisData(4)
S.x[2] = Float64[]
S.x[3] = Float64[]
S.t[4] = Array{Int64,2}(undef,0,0)
merge!(S, v=1)
basic_checks(S)
sizetest(S, 1)

printstyled(stdout,"    Ability to handle irregularly-sampled data\n", color=:light_green)
C = randSeisChannel(c=true)
namestrip!(C)
S = SeisData(C, randSeisChannel(c=true), randSeisChannel(c=true))
namestrip!(S)
for i = 2:3
  S.id[i] = identity(S.id[1])
  S.resp[i] = copy(S.resp[1])
  S.loc[i] = copy(S.loc[1])
  S.units[i] = identity(S.units[1])
end
T = merge(S, v=1)
basic_checks(T)
sizetest(T, 1)

# ===========================================================================
printstyled(stdout,"    (I) simple merges\n", color=:light_green)
printstyled(stdout,"      (a) three channels, two w/same params, no overlapping data\n", color=:light_green)
S = SeisData(C1(), C2(), randSeisChannel())

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test vcat(U.x[1], U.x[2])==S.x[i]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# Do the notes log the extra source?
@test findfirst([occursin("New channel 1", i) for i in S.notes[1]]) != nothing
@test findfirst([occursin("+src: test channel 1", i) for i in S.notes[1]]) != nothing

# Are dictionaries merging correctly?
@test haskey(S.misc[1], "P")
@test haskey(S.misc[1], "S")

printstyled(stdout, "      (b) \"zipper\" merge I: two channels, staggered time windows, no overlap\n", color=:light_green)
S = SeisData(C1(), C2())
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
printstyled(stdout,"    (II) channels must have identical :fs, :loc, :resp, and :units to merge \n", color=:light_green)
S = SeisData(C1(), C2(), randSeisChannel())
S += C4()

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
  @test getfield(U, i)[4] == getfield(S, i)[j]
end

# with a second channel at the new location
S = deepcopy(U)
S += C5()

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
S.loc[4] = copy(loc)
S.loc[5] = copy(loc)
S.resp[4] = resp1
S.resp[5] = resp1

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
@test S.resp[j] == resp1
@test mk_tcat(U.t[4:5], fs) == S.t[j]
@test vcat(U.x[4], U.x[5]) == S.x[j]

# ===========================================================================
printstyled(stdout,"    (III) one merging channel with a time gap\n", color=:light_green)
S = SeisData(C1(), C2(), randSeisChannel())
S.x[2] = rand(2*nx)
S.t[2] = vcat(S.t[2][1:1,:], [nx 2*Δ], [2*nx 0])

# Is the group merged correctly?
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
i = findid(id, S)
@test U.x[1] == S.x[1][1:nx]
@test U.x[2][1:nx] == S.x[1][nx+1:2nx]
@test U.x[2][nx+1:2nx] == S.x[1][2nx+1:3nx]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

printstyled(stdout,"      (a) merge window is NOT the first\n", color=:light_green)
os = 2
S = SeisData(C1(), C2(), randSeisChannel())
S.x[1] = rand(2*nx)
S.t[1] = vcat(S.t[1][1:1,:], [nx os*Δ], [2*nx 0])
S.t[2][1,2] += (os+nx)*Δ
U = deepcopy(S)
merge!(S)
basic_checks(S)
@test S.n == 2
@test U.x[1] == S.x[1][1:2nx]
@test U.x[2] == S.x[1][2nx+1:3nx]
@test mk_tcat(U.t[1:2], fs) == S.t[i]

# ===========================================================================
printstyled(stdout,"    (IV) one merge group has non-duplication time overlap\n", color=:light_green)
printstyled(stdout,"      (a) check for averaging\n", color=:light_green)
nov = 3
S = SeisData(C1(), C2_ov(), randSeisChannel())

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
@test findfirst([occursin("New channel 1", i) for i in S.notes[1]]) != nothing
@test findfirst([occursin("+src: test channel 1", i) for i in S.notes[1]]) != nothing

# Are dictionaries merging correctly?
@test haskey(S.misc[1], "P")
@test haskey(S.misc[1], "S")

printstyled(stdout,"      (b) src overlap window is NOT first\n", color=:light_green)
os = 2
S = SeisData(C1(), C2_ov(), randSeisChannel())
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
@test S.t[i] == vcat(U.t[1][1:2,:], [length(S.x[1]) 0])

printstyled(stdout,"      (c) dest overlap window is NOT first\n", color=:light_green)
nov = 3
S = SeisData(C1(), C2_ov(), randSeisChannel())
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

# t1 = t_expand([1 1000000000000000; 97 0], fs); t2 = t_expand([1 999999998990000; 101 980000; 200 0], fs); tt = sort(vcat(t1,t2)); τ = t_collapse(tt, fs)
# t1 = t_expand(U.t[1], fs); t2 = t_expand(U.t[2], fs); tt = sort(unique(vcat(t1, t2))); t = t_collapse(tt, fs)
# t == τ

# ===========================================================================
printstyled(stdout,"    (V) overlap with time mismatch\n", color=:light_green)

#= mk_tcat stops working here as merge shifts one window back in
time one sample to account for the intentional one-Δ time mismatch =#

printstyled(stdout,"      (a) data overlap one sample off of S.t\n", color=:light_green)

# (a) 3_sample overlap with wrong time (C2[1:2] == C1[99:100])
nov = 2
S = SeisData(C1(), C2_ov())
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

printstyled(stdout,"      (b) src overlap window is NOT first\n", color=:light_green)
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

printstyled(stdout,"      (c) dest overlap window is NOT first\n", color=:light_green)
S = SeisData(C1(), C2_ov())
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
printstyled(stdout,"    (VI) Multi-channel merge with overlap\n", color=:light_green)
breakpt_1 = nx-nov        # 97
breakpt_2 = 2*(nx-nov)-1  # 195
breakpt_3 = 2*(nx-nov)+2  # 198

S = SeisData(C1(), C2_ov(), C3_ov(), randSeisChannel())
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
breakpt_4 = length(S.x[1])
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
printstyled(stdout,"    (VII) \"Zipper\" merges II\n", color=:light_green)
printstyled(stdout,"      (a) two traces with staggered time windows, some with overlap\n", color=:light_green)

# (a) One overlap in a late window should not shift back previous windows
nov = 2
S = SeisData(C1(), C2())
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

printstyled(stdout,"      (b) one overlap, late window, time mismatch\n", color=:light_green)
nov = 3
true_nov = 2
S = SeisData(C1(), C2())
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
