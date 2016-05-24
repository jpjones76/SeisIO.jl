using Base.Test, Compat
using DSP:resample
segy_file = "SampleFiles/02.050.02.01.34.0572.6"
uw_root = "SampleFiles/99062109485W"

t1 = time()
ts = t1+0.25
te = t1+0.75
fs1 = 50.0

# s1 and s2 represent data from a fictitious channel
# s2 begins 1 second later, but has a gap of 1s after sample 25
s1 = SeisObj(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1.0 t1; 100.0 0.0], x=randn(100))
s2 = SeisObj(fs = fs1, gain = 10.0, name = "POORLY NAMED", id = "DEAD.STA..EHZ",
  t = [1.0 t1+1.0; 26.0 1.0; 126 0.2; 150.0 0.0], x=randn(150))


s3 = SeisObj(fs = 100.0, gain = 5.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1.0 t1; 100.0 0.0], x=rand(100)-0.5)
s4 = SeisObj(fs = 100.0, gain = 50.0, name = "UNNAMED", id = "DEAD.STA..EHE",
  t = [1.0 t1+1; 100.0 1.0; 150.0 0.0], x=randn(150))

# We expect:
# (1) LAST 25-26 points in s1 will be averaged with first 25 points in s3
# (2) s3 will be ungapped with exactly 50 samples of junk
# (3) after sync of a seisobj formed from [s1+s3, s2], s2 will be padded with 0.5s
# at start and 3s at end

println("seisdata...")
println("...init...")
S = SeisData()
for i in fieldnames(S)
  if i != :n
    @test_approx_eq(isempty([]), isempty(S.(i)))
  end
end

println("...dealing with gaps...")
s2u = ungap(s2)
@test_approx_eq(length(s2.x)/s2.fs + sum(s2.t[2:end-1,2]), length(s2u.x)/s2u.fs)

println("...channel add...")
S += (s1 + s2)

# Do in-place operations only change leftmost variable?
@test_approx_eq(length(s1.x), 100)
@test_approx_eq(length(s2.x), 150)

# expected behavior for S = s1+s2
# (0) length[s.x[1]] = 250
# (1) S.x[1][1:50] = s1.x[1:50]
# (2) S.x[1][51:75] = mean(s1.x[51:75] + s2.x[1:25])
# (3) S.x[1][76:100] = s1.x[76:100]
# (4) S.x[1][101:125] = mean(S.x[1])
# (5) S.x[1][126:250] = s2.x[126:250]

# Basic merge ops
@test_approx_eq(S.n, 1)
@test_approx_eq(length(S.fs), 1)
@test_approx_eq(S.fs[1], s1.fs)
@test_approx_eq(length(S.gain), 1)
@test_approx_eq(S.gain[1], s1.gain)
@test_approx_eq(length(S.name), 1)
@test_approx_eq(length(S.t),1)
@test_approx_eq(length(S.x),1)
@test_approx_eq(true, S.id[1]=="DEAD.STA..EHZ")
ungap!(S, m=false, w=false)
@test_approx_eq(length(S.x[1]), 260)
@test_approx_eq(S.x[1][1:50], s1.x[1:50])
@test_approx_eq(S.x[1][51:75], 0.5.*(s1.x[51:75] .+ s2.x[1:25]))
@test_approx_eq(S.x[1][76:100], s1.x[76:100])
@test_approx_eq(S.x[1][101:125], collect(repeated(NaN,25)))
@test_approx_eq(S.x[1][126:225], s2.x[26:125])
@test_approx_eq(S.x[1][226:235], collect(repeated(NaN,10)))
@test_approx_eq(S.x[1][236:260], s2.x[126:150])

# Auto-tapering after a merge
T = deepcopy(S)
ii = find(isnan(S.x[1]))
autotap!(S)
@test_approx_eq(0, length(find(isnan(S.x[1]))))   # No more NaNs?
@test_approx_eq(sum(diff(S.x[1][ii])), 0)         # All NaNs filled w/same val?
@test_approx_eq(T.x[1][12:90], S.x[1][12:90])     # Un-windowed vals untouched?

println("...channel delete...")
S -= 1
for i in fieldnames(S)
  if i != :n
    @test_approx_eq(isempty([]), isempty(S.(i)))
  end
end

println("...merge...")
S += (s1 + s3)
S += (s2 + s4)
@test_approx_eq(S.n, 2)
@test_approx_eq(length(S.fs), 2)
@test_approx_eq(length(S.gain), 2)
@test_approx_eq(length(S.name), 2)
@test_approx_eq(length(S.t),2)
@test_approx_eq(length(S.x),2)
@test_approx_eq(S.fs[2], 100.0)
@test_approx_eq(S.gain[1], 10.0)
@test_approx_eq(true, S.id[1]=="DEAD.STA..EHZ")
ungap!(S, m=false, w=false)
@test_approx_eq(length(S.x[1]), 260)
println("...auto-resample on merge...")
@test_approx_eq(length(S.x[2]), 350)
println("...gain correction on merge...")
@test_approx_eq(S.x[2][101], s4.x[1]/10)

println("...direct reading of supported file formats...")
println("......SAC...")
S += readsac(sac_file)                                   # SAC
@test_approx_eq(S.t[S.n][1,1], 1.0)
@test_approx_eq(S.t[S.n][end,1], length(S.x[S.n]))
@test_approx_eq(S.t[S.n][end,2], 0.0)

println("......SEGY...")
S += readsegy(segy_file, f="nmt")                        # SEGY rev 0 mod PASSCAL
println("......UW...")
@test_approx_eq(S.t[S.n][1,1], 1.0)
@test_approx_eq(S.t[S.n][end,1], length(S.x[S.n]))
@test_approx_eq(S.t[S.n][end,2], 0.0)

S += readuw(uw_root)                                     # UW
@test_approx_eq(S.t[S.n][1,1], 1.0)
@test_approx_eq(S.t[S.n][end,1], length(S.x[S.n]))
@test_approx_eq(S.t[S.n][end,2], 0.0)

println("......win32 skipped; (file redistribution prohibited by NIED)...")

println("...randseisdata...")
R = randseisdata(c=true)
S += R

# Ensure merge works correctly with traces separated in time
s5 = SeisObj(fs = 100.0, gain = 32.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1.0 t1; 100.0 0.0], x=randn(100))
s6 = SeisObj(fs = 100.0, gain = 32.0, name = "UNNAMED", id = "DEAD.STA..EHE",
  t = [1.0 t1+30; 200.0 0.0], x=randn(200))
println("...channel add...")
T = (s5 + s6)
ungap!(T)
@test_approx_eq(length(T.x),3200)
println("...done!")
