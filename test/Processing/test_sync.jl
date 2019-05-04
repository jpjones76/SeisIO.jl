using Dates
printstyled("  sync!\n", color=:light_green)

fs = 100.0
ns = 10
t = floor(Int64, time()-60.0)*sμ
δ3 = 1.0
dtμ = round(Int, 1.0e6/fs)

# for k = 1:10
# Test three seismic and three irregularly sampled channels
S = randSeisData(4, s=1.0)[2:4] + randSeisData(4, c=1.0)[2:4]

# seismic channels will be ns seconds of data sampled at 100 Hz with preset gaps
nx = round(Int, ns * fs)
for i = 1:3
  S.x[i] = rand(nx)       # Set S.x to be 1000 samples each
  S.fs[i] = fs            # Set S.fs to be uniformly 100 Hz
end
S.t[1] = [1 t; nx 0]
S.t[2] = [1 t-ns*1000000; nx 0]
S.t[3] = [1 t; 2 round(Int, δ3*1.0e6); nx 0]

# irregular channels will be 100 points each, randomly sampled between the start and the end
n_irr = div(nx,10)
for i = 4:6
  S.x[i] = rand(n_irr)
  S.fs[i] = 0.0
  r = UnitRange{Int64}(0:ns*1000000)
  S.t[i] = hcat(zeros(Int64, n_irr), t.+sort(rand(r, n_irr)))

  # Ensure the last sample is always <1s from the end
  τ = view(S.t[i], :, 2)
  if last(τ)-first(τ) < (ns-1)*1.0e6
    τ[end] = first(τ) + (ns-0.5)*1.0e6
  end
end
sx = Lx(S)

# Set derived variables
ts, te = get_edge_times(S)
ts₀ = minimum(ts)
ts₁ = maximum(ts)

# TEST 1 =====================================================================
# Sync to last start; don't sync ends
T = sync(S)
basic_checks(T)
ts_new, te_new = get_edge_times(T)

# Expectation: T.t[2] is deleted
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
S.t[2] = [1 t-1000000; nx 0]
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
@test vx[1]-sx[1] == 199
@test vx[1]-ux[1] == 199
@test minimum(ts_new .≥ ts₀) == true           # Should still be true
@test 2 ∈ findall((ts_new .== ts₀).== true)   # Defined earliest start time
@test vx[2] == vx[1]                           # Due to how we set the gap
@test vx[2] - vx[3] == 99
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
ts₆ = S.t[1][1,2]
te₆ = S.t[1][1,2] + round(Int, 1.0e6*nx/fs)
ds₆ = u2d(ts₆*1.0e-6)
de₆ =  u2d(te₆*1.0e-6)
W = sync(S, s=ds₆)
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

# Repeat with an end time
W = sync(S, s=ds₆, t=de₆)
basic_checks(W)
ts_new, te_new = get_edge_times(W)
wx = Lx(W)

# Expectations:
@test sx[3]-wx[3] == 99                       # Trace 3 is 99 samples shorter
for i in [1,2,4,5,6]
  @test sx[i] == wx[i]                        # No change in other trace lengths; 2 gets padded
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
@test xx[3]-sx[3] == 2      # Trace 3 loses 99 samples at the end, but gains 100 at end and 1 at start ... net gain +2
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
X = sync(S, s=ds₆, t="first"); basic_checks(X)
X = sync(S, s=ds₆, t="last"); basic_checks(X)

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

ss = string(ds₆)
Z = deepcopy(S)
t = deepcopy(Z.t[5])
t = hcat(t[:,1:1], vcat(0, diff(t[:,2:2], dims=1)))
Z.t[5] = deepcopy(t)
open("runtests.log", "a") do out
  redirect_stdout(out) do
    sync!(Z, v=3); basic_checks(Z)
  end
end

# Expect: Z[5] is gone
for i in [1,2,3,4,6]
  @test any(Z.id.==S.id[i])
end
@test (any(Z.id.==S.id[5]) == false)

# ===========================================================================
# method extenson to SeisChannel
ts₆ = S.t[1][1,2]
te₆ = S.t[1][1,2] + round(Int, 1.0e6*nx/fs)
ds₆ = u2d(ts₆*1.0e-6)
de₆ =  u2d(te₆*1.0e-6)
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
ts₆ = S.t[1][1,2]
te₆ = S.t[1][1,2] + round(Int, 1.0e6*nx/fs)
ds₆ = u2d(ts₆*1.0e-6)
de₆ =  u2d(te₆*1.0e-6)
Ev = SeisEvent(hdr = randSeisHdr(), data = deepcopy(S))
sync!(Ev, s=ds₆)
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
W = sync(Ev, s=ds₆).data
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
