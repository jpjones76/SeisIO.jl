printstyled("  sync!\n", color=:light_green)

# Method of time calculation in old sync!
function sync_times(t::AbstractArray{Int64, 2}, fs::Float64, t_min::Int64, t_max::Int64)
  t_x = t_expand(t, fs)
  ii = vcat(findall(t_x.<t_min), findall(t_x.>t_max))
  return ii
end
sync_times(t::AbstractArray{Int64, 2}, fs::Float64, t_min::Int64) = get_sync_inds(t, fs, t_min, endtime(t, fs))

# Based on code in sync!
function prune_x!(x::SeisIO.FloatArray, x_del::Array{UnitRange, 1})
  nr = size(x_del, 1)
  for i in nr:-1:1
    if !isempty(x_del[i])
      deleteat!(x, x_del[i])
    end
  end
  return nothing
end

printstyled("    sync_t\n", color=:light_green)

# Cases to consider
printstyled("      nothing removed\n", color=:light_green)
# most basic case: a well-formed time matrix
Δ = 20000
ts = 1583455810004000
nx = 40000
fs = sμ/Δ

t = [1 ts; nx 0]
te = endtime(t, Δ)
t_min = ts
t_max = te
(xi, W) = sync_t(t, Δ, t_min, t_max)

@test xi == [1 nx]
@test W == t_win(t, Δ)

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

printstyled("      empty window\n", color=:light_green)
t = [1 ts-nx*Δ; nx 0]
(xi, W) = sync_t(t, Δ, t_min, t_max)

@test isempty(xi)
@test isempty(W)

printstyled("      simple truncations\n", color=:light_green)
# truncate start
t = [1 ts; nx 0]
nclip = 4
(xi, W) = sync_t(t, Δ, ts+nclip*Δ, te)

@test xi == [nclip+1 nx]

# truncate end
t_min = ts
t_max = te-nclip*Δ
(xi, W) = sync_t(t, Δ, t_min, t_max)

@test xi == [1 nx-nclip]

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# a time matrix with one gap equal to n samples
n = 1
gi = 10
t = [1 ts; gi n*Δ; nx 0]
(xi, W) = sync_t(t, Δ, ts, te)

@test xi == [1 gi-1; gi nx-n]

n = 120
gi = 10
t = [1 ts; gi n*Δ; nx 0]
(xi, W) = sync_t(t, Δ, ts, te)

@test xi == [1 gi-1; gi nx-n]

# two gaps, n and m samples
m = 33
gj = 2000
t = [1 ts; gi n*Δ; gj m*Δ; nx 0]
(xi, W) = sync_t(t, Δ, ts, te)

@test xi == [1 gi-1; gi gj-1; gj nx-m-n]

t_min = ts
t_max = te
i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# negative gap
t = [1 ts; gi -n*Δ; nx 0]
(xi, W) = sync_t(t, Δ, ts, te)

@test xi == [1 gi-1; n+1 nx]

# here, the number of samples before ts in window 2 is n-gi, or 110; the first
# n-gi samples of this window are samples gi to n-gi+gi = n; so the window
# starts at n+1, or 121

t_min = ts
t_max = te
i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# truncate other (windows not in chronological order)
n = 120
gi = 10
nx = 100

# start of middle window
W = ts .+ Δ.*([   1       gi
               -n+1        0
               gi+1       nx ] .- 1)
t_min = ts - div(n,2)*Δ
t_max = last(W)
t = w_time(W, Δ)
xi0 = x_inds(t)
(xi, W) = sync_t(t, Δ, t_min, t_max)

@test xi-xi0 == [0 0; div(n,2) 0; 0 0]

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# end of middle window
W = ts .+ Δ.*([   1       gi
               nx+1       nx+n
               gi+1       nx ] .- 1)
t_min = ts
t_max = ts + (nx - 1 + div(n,2))*Δ
t = w_time(W, Δ)
xi0 = x_inds(t)
(xi, W) = sync_t(t, Δ, t_min, t_max)

@test xi-xi0 == [0 0; 0 -div(n,2); 0 0]

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

printstyled("      segment removed\n", color=:light_green)
# first window gets emptied
gi = 10
nx = 100
gl = 6
W = ts .+ Δ.*[  -gl       -1
                  1     gi-1
              gi+gl       nx]
t_min = ts
t_max = last(W)
t = w_time(W, Δ)
xi0 = x_inds(t)
xi, W1 = sync_t(t, Δ, ts, last(W))

@test size(xi, 1) == size(W1, 1) == 2
@test sum(diff(xi, dims=2).+1) == nx-gl

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# second window gets emptied (no gap, windows 1 and 2 are out of order)
W = ts .+ Δ.*[    0     gi-1
                -gl       -1
                 gi  nx-gl-1]
t = w_time(W, Δ)
xi = x_inds(t)
xi1, W1 = sync_t(t, Δ, ts, last(W))

@test size(xi1, 1) == size(W1, 1) == 2
@test xi1 == xi[[1,3],:]

# last window gets emptied
W = ts .+ Δ.*[    0       gi
               gi+2       nx
               nx+2    nx+gi]
t_min = ts
t_max = W[2,2]
t = w_time(W, Δ)
xi = x_inds(t)
xi1, W1 = sync_t(t, Δ, t_min, t_max)

@test size(xi1, 1) == size(W1, 1) == 2
@test xi1 == xi[[1,2],:]

printstyled("      multiple segs removed\n", color=:light_green)
# first + last emptied
gi = 10
W = ts .+ Δ.*[    0     gi-1
               gi+2       nx
               nx+2    nx+gi]
t_min = ts + gi*Δ
t_max = ts + nx*Δ
t = w_time(W, Δ)
xi0 = x_inds(t)
xi, W1 = sync_t(t, Δ, t_min, t_max)

@test size(xi, 1) == size(W1, 1) == 1
@test xi == xi0[[2],:]

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# first + last emptied, middle truncated by os
os = 10
t_max = ts + (nx-os)*Δ
t = w_time(W, Δ)
xi0 = x_inds(t)
xi, W1 = sync_t(t, Δ, t_min, t_max)

@test size(xi, 1) == size(W1, 1) == 1
@test xi0[[2],:] .- xi == [0 os]

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# first emptied, last truncated, middle is one point
gi = 666
nx = gi + 100
W = ts .+ Δ.*[    0     gi-1
               gi+2       nx
               nx+2    nx+gi]
t_min = ts + nx*Δ
t_max = ts + (nx+div(gi,2))*Δ
t = w_time(W, Δ)
xi0 = x_inds(t)
xi, W1 = sync_t(t, Δ, t_min, t_max)

@test size(xi, 1) == size(W1, 1) == 2
@test W1[1,1] == W1[1,2]
@test div(W1[2,2] - W1[2,1], Δ) + 2 == div(gi, 2)

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# second and last emptied
gi = 10
W = ts .+ Δ.*[    0     gi-1
               gi+2       nx
               nx+2    nx+gi]
t_min = ts + (gi+1)*Δ
t_max = ts + nx*Δ
t = w_time(W, Δ)
xi = x_inds(t)
xi1, W1 = sync_t(t, Δ, t_min, t_max)

@test size(xi1, 1) == size(W1, 1) == 1
@test xi1 == xi[[2],:]

printstyled("      complicated cases\n", color=:light_green)
# complex case with no completely emptied windows; formed as W and not :t
nx = 40000
W = ts .+ Δ.*[1     10
              12    12
              14    14
              23    40
              51    100
              -1200 0
              101   9500
              12000 41318]

t_min = ts - 300Δ
t_max = last(W) - 2000Δ
t = w_time(W, Δ)
xi0 = x_inds(t)
xi, W = sync_t(t, Δ, t_min, t_max)

j = sortperm(W[:,1])
W1 = W[j,:]
t1 = w_time(W1, Δ)
@test t1[1,2] == t_min
@test endtime(t1, Δ) == t_max

# check our work; sorted matrix should be from t_min to t_max
t2 = w_time(W, Δ)
@test diff(x_inds(t2), dims=2) == diff(xi, dims=2)

i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi, t[end, 1])
test_del_ranges(x_del, i2)

# last window emptied; previous window truncated; first window truncated
nx = 1000
gi = 17
os = 50
W = ts .+ Δ.*[ -1*os      gi
               gi+2    nx+gi
               nx+gi+2   2nx ]
t_min = ts
t_max = W[2,2] - Δ*gi
t = w_time(W, Δ)
xi = x_inds(t)
xi1, W1 = sync_t(t, Δ, t_min, t_max)
t1 = w_time(W1, Δ)

@test size(xi1, 1) == size(W1, 1) == 2
@test xi1[2,2] == nx+os
@test W[[1,2],:] != W1
@test xi1[[1,2],:] != xi
@test t1[1,2] == t_min
@test endtime(t1, Δ) == t_max

nx_true = t[end,1]
i2 = sync_times(t, fs, t_min, t_max)
x_del = get_del_ranges(xi1, nx_true)
test_del_ranges(x_del, i2)

# Final step, putting it all together
x = randn(Float32, nx_true)
x1 = deepcopy(x)
x2 = deepcopy(x)
prune_x!(x1, x_del)
deleteat!(x2, i2)
@test x1 == x2

fs = 100.0
Δ = round(Int64, sμ/fs)
t0 = 1582934400000000
ns = 10
Δ3 = 1.0

# Test three seismic and three irregularly sampled channels
S = randSeisData(3, s=1.0)

# seismic channels will be ns seconds of data sampled at 100 Hz with preset gaps
nx = round(Int64, ns * fs)
for i = 1:3
  S.x[i] = rand(nx)       # Set S.x to be 1000 samples each
  S.fs[i] = fs            # Set S.fs to be uniformly 100 Hz
end
S.t[1] = [1 t0; nx 0]
S.t[2] = [1 t0-ns*1000000; nx 0]
S.t[3] = [1 t0; 2 round(Int64, Δ3*sμ); nx 0]

# irregular channels will be 100 points each, randomly sampled between the start and the end
append!(S, randSeisData(3, c=1.0))
n_irr = div(nx, 10)
ni = div(n_irr, ns)
for i = 4:6
  S.x[i] = rand(n_irr)
  S.fs[i] = 0.0
  S.t[i] = zeros(n_irr, 2)
  tv = zeros(Int64, n_irr)

  #= the definition of rmax here prevents rng giving us a value above tmax
    in test (6), which breaks the test
  =#
  for j = 1:ns
    si = 1 + (j-1)*ni
    ei = j*ni
    rmin = t0 + (j-1)*1000000
    rmax = t0 - 1 + (j*1000000) - (j == ns ? 2Δ : 0)
    r = UnitRange{Int64}(rmin:rmax)
    tv[si:ei] .= rand(r, ni)
  end
  sort!(tv)
  S.t[i][:,1] .= 1:n_irr
  S.t[i][:,2] .= tv
end
sx = Lx(S)

# Set derived variables
ts, te = get_edge_times(S)
ts₀ = minimum(ts)
ts₁ = maximum(ts)

# TEST 1 =====================================================================
# Sync to last start; don't sync ends
printstyled(stdout,"    sync to last start; don't sync ends\n", color=:light_green)
T = sync(S)
basic_checks(T)
ts_new, te_new = get_edge_times(T)

# Expectation: T[2] is deleted
@test T.n == 5
@test S.id[1] == T.id[1]
@test findid(S.id[2], T.id) == 0
for i = 3:6
  @test(S.id[i] == T.id[i-1])
end

# Expectation: the latest time in S.t is now the earliest start time
@test minimum(ts_new .≥ ts₁) == true
@test maximum(ts_new .== ts₁) == true

# TEST 2 =====================================================================
# Sync to last start; don't sync ends

# change trace 2 to begin only 1s earlier; resync
S.t[2] = [1 t0-1000000; nx 0]
ts, te = get_edge_times(S)
ts₀ = minimum(ts)
ts₁ = maximum(ts)

T = sync(S)
ts_new, te_new = get_edge_times(T)

# Expectation: T.x[2] is at least 100 pts shorter and exactly 100 shorter than T.x[1]
@test T.n == 6
tx = Lx(T)
@test tx[2] ≤ nx-100
@test tx[2] == tx[1] - 100
@test tx[2] ≤ tx[3]
@test minimum(ts_new .≥ ts₁) == true
@test maximum(ts_new .== ts₁) == true
basic_checks(T)

# TEST 3 =====================================================================
# Sync to last start; sync to first end
printstyled(stdout,"    sync to last start; sync to first end\n", color=:light_green)
te₀ = minimum(te)
te₁ = maximum(te)

T = sync(S, t="first")
basic_checks(T)
ts_new, te_new = get_edge_times(T)

# Expectation: T.x[1] and T.x[2] are same length, T.x[3] is shorter
tx = Lx(T)
@test tx[1] == tx[2]
@test tx[2] > tx[3]
@test minimum(te_new .≤ te₀) == true
@test maximum(te_new .== te₀) == true
@test minimum(sx.-tx.≥0) == true                # vx is always longer

# TEST 4 =====================================================================
# Sync to first start; sync to first end
printstyled(stdout,"    sync to first start; sync to last end\n", color=:light_green)
U = sync(S, s="first", t="first")
basic_checks(U)
ts_new, te_new = get_edge_times(U)

# Expectation:
ux = Lx(U)
@test minimum(ux.-tx.≥0) == true                # vx is always longer
@test tx[1]+100 ≤ ux[1]                        # U.x[1] gains >100 samples
@test minimum(ts_new .≥ ts₀) == true           # Should still be true
@test 2 ∈ findall((ts_new .== ts₀).== true)   # Defined earliest start time
@test ux[2]==ux[1]                            # Due to how we set the gap
@test ux[1]-ux[3] == 100
@test minimum(te_new .≤ te₀) == true
@test maximum(te_new .== te₀) == true
for i = 4:6
  @test ux[i] ≥ tx[i]
end

# TEST 5 =====================================================================
# Sync to first start; sync to last end
V = sync(S, s="first", t="last")
basic_checks(V)
ts_new, te_new = get_edge_times(V)
vx = Lx(V)

# Expectation:
@test minimum(vx.-sx.≥0) == true                # vx is always longer
t1 = t_expand(V.t[1], V.fs[1])
t2 = t_expand(S.t[1], S.fs[1])
j = setdiff(t1, t2)
@test vx[1]-sx[1] == length(j)
t2 = t_expand(U.t[1], U.fs[1])
j = setdiff(t1, t2)
@test vx[1]-ux[1] == length(j)
@test minimum(ts_new .≥ ts₀) == true           # Should still be true
@test 2 ∈ findall((ts_new .== ts₀).== true)   # Defined earliest start time
@test vx[2] == vx[1]                           # Due to how we set the gap
t2 = t_expand(V.t[2], V.fs[2])
t3 = t_expand(V.t[3], V.fs[3])
j = setdiff(t2, t3)
@test vx[2] - vx[3] == length(j)
@test minimum(te_new .≤ te₁) == true
@test maximum(te_new .== te₁) == true
for i = 4:6
  @test vx[i] ≥ tx[i]
  @test vx[i] == sx[i]
end

# TEST 6 =====================================================================
# Sync to s = DateTime (first trace start), t = "none"
# trace 3 should be 100 samples shorter
# so should trace 2
printstyled(stdout,"    sync to DateTime; don't sync ends\n", color=:light_green)
ts₆ = S.t[1][1,2]
te₆ = S.t[1][1,2] + Δ*(nx-1)
ds₆ = u2d(ts₆*μs)
de₆ = u2d(te₆*μs)
W = sync(S, s=ds₆)
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# Expectations:
@test sx[2]-wx[2] == 100                # Trace 2 is 100 samples shorter
for i in [1,3,4,5,6]
  @test sx[i] == wx[i]                  # No change in other trace lengths
end
@test minimum(ts_new .≥ ts₆) == true           # We start at ts₆, not before
@test findfirst(ts_new .== ts₆).== 1          # Defined start time

# Repeat with an end time
# te₆ = S.t[1][1,2] + round(Int64, sμ*(nx-1)/fs)
# de₆ = u2d(te₆*μs)
W = sync(S, s=ds₆, t=de₆)
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# Expectations:
@test sx[3]-wx[3] == 100                  # Trace 3 is 100 samples shorter
for i in [1,2,4,5,6]
  @test sx[i] == wx[i]    # No change in other trace lengths; 2 gets padded
end
@test minimum(ts_new .≥ ts₆) == true           # We start at ts₆, not before
@test findfirst(ts_new .== ts₆).== 1          # Defined start time

# TEST 7 =====================================================================
# Sync to DateTime 1s before first trace, 0.01s after; is it 101 pts longer?

# Repeat with an increased window range
ds₆ -= Second(1)
de₆ += Millisecond(10)
X = sync(S, s=ds₆, t=de₆)
basic_checks(X)
ts_new, te_new = get_edge_times(X)
xx = Lx(X)

# Expectations:
@test xx[1]-sx[1] == 101    # Trace 1 is 101 samples longer
@test xx[2]-sx[2] == 101    # Trace 2 is also 101 samples longer
@test xx[3]-sx[3] == 1      # Trace 3 loses 100 samples at the end, but gains 100 at end and 1 at start ... net gain +1
for i = 4:6
  @test xx[i] == sx[i]
end

# Sync to DateTime 2s after first trace, t="first"
ds₆ += Second(3)
X = sync(S, s=ds₆, t=de₆)
basic_checks(X)
ts_new, te_new = get_edge_times(X)
xx = Lx(X)

# Expectations:
@test xx[1] == 801          # Trace 1 should be 801 samples
@test xx[1] == xx[2]        # Should be the same due to padding
# In fact trace 2 should have 101 points appended
found = findall([occursin("appended 101", i) for i in X.notes[2]])
@test isempty(found) == false

# TEST 8 =====================================================================
# A few simple combinations; do these work?
printstyled(stdout,"    sync start to DateTime; sync first end\n", color=:light_green)
X = sync(S, s=ds₆, t="first"); basic_checks(X)

printstyled(stdout,"    sync start to DateTime; sync to last end\n", color=:light_green)
X = sync(S, s=ds₆, t="last"); basic_checks(X)

printstyled(stdout,"    sync start to string time; sync to last end\n", color=:light_green)
ss = string(ds₆)
Y = sync(S, s=ds₆, t="last", v=3); basic_checks(Y)

# Expect: X != Y due to notes, but all other fields equal
for f in datafields
  if f != :notes
    @test isequal(getfield(X,f), getfield(Y,f))
  end
end

# TEST 9 =====================================================================
# Do we actually prune campaign data when all times are out of range?
printstyled(stdout,"    prune all irregular data when all times are out of range\n", color=:light_green)

ss = string(ds₆)
Z = deepcopy(S)
t1 = deepcopy(Z.t[5])
t1 = hcat(t1[:,1:1], vcat(0, diff(t1[:,2:2], dims=1)))
Z.t[5] = deepcopy(t1)

redirect_stdout(out) do
  sync!(Z, v=3); basic_checks(Z)
end

# Expect: Z[5] is gone
for i in [1,2,3,4,6]
  @test any(Z.id.==S.id[i])
end
@test (any(Z.id.==S.id[5]) == false)

# ===========================================================================
# method extenson to SeisChannel
printstyled(stdout,"    SeisChannel method extension\n", color=:light_green)
ts₆ = S.t[1][1,2]
te₆ = S.t[1][1,2] + Δ*(nx-1)
ds₆ = u2d(ts₆*μs)
de₆ =  u2d(te₆*μs)
C = deepcopy(S[1])
sync!(C, s=ds₆)
W = SeisData(C)
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# Repeat with an end time
C = deepcopy(S[1])
W = SeisData(sync(C, s=ds₆, t=de₆))
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# ===========================================================================
# method extenson to SeisEvent
printstyled(stdout,"    SeisEvent method extension\n", color=:light_green)
ts₆ = S.t[1][1,2]
te₆ = S.t[1][1,2] + Δ*(nx-1)
ds₆ = u2d(ts₆*μs)
de₆ =  u2d(te₆*μs)
Ev = SeisEvent(hdr = randSeisHdr(), data = deepcopy(S))
sync!(Ev.data, s=ds₆)
W = Ev.data
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# Expectations:
@test sx[2]-wx[2] == 100                      # Trace 2 is 100 samples shorter
for i in [1,3,4,5,6]
  @test sx[i] == wx[i]                        # No change in other trace lengths
end
@test minimum(ts_new .≥ ts₆) == true           # We start at ts₆, not before
@test findfirst(ts_new .== ts₆).== 1          # Defined start time

Ev = SeisEvent(hdr = randSeisHdr(), data = deepcopy(S))
W = sync(Ev.data, s=ds₆)
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# Expectations:
@test sx[2]-wx[2] == 100                      # Trace 2 is 100 samples shorter
for i in [1,3,4,5,6]
  @test sx[i] == wx[i]                        # No change in other trace lengths
end
@test minimum(ts_new .≥ ts₆) == true           # We start at ts₆, not before
@test findfirst(ts_new .== ts₆).== 1          # Defined start time
