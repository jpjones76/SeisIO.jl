segy_file = path*"/SampleFiles/02.050.02.01.34.0572.6"
uw_root = path*"/SampleFiles/99062109485W"
const μs = 1.0e-6
fs1 = 50.0

t1 = round(Int64,time()/μs)
ts = t1+round(Int64,0.25/μs)
te = t1+round(Int64,0.75/μs)

# s1 and s2 represent data from a fictitious channel
# s2 begins 1 second later, but has a gap of 1s after sample 25
s1 = SeisChannel(fs = fs1, gain = 10.0, name = "DEAD.STA.EHZ", id = "DEAD.STA..EHZ",
  t = [1 t1; 100 0], x=randn(100))
s2 = SeisChannel(fs = fs1, gain = 10.0, name = "POORLY NAMED", id = "DEAD.STA..EHZ",
  t = [1 t1+1000000; 26 1000000; 126 200000; 150 0], x=randn(150))


s3 = SeisChannel(fs = 100.0, gain = 5.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1 t1; 100 0], x=rand(100).-0.5)
s4 = SeisChannel(fs = 100.0, gain = 50.0, name = "UNNAMED", id = "DEAD.STA..EHE",
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

printstyled("  ...fixing data gaps...\n", color=:light_green)
s2u = ungap(s2)
@test length(s2.x) / s2.fs + μs * sum(s2.t[2:end - 1, 2]) ≈ length(s2u.x) / s2u.fs

printstyled("  ...channel add and simple merges...\n", color=:light_green)
S += (s1 * s2)

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
@test S.n ≈ 1
@test length(S.fs) ≈ 1
@test ≈(S.fs[1], s1.fs)
@test ≈(length(S.gain), 1)
@test ≈(S.gain[1], s1.gain)
@test ≈(length(S.name), 1)
@test ≈(length(S.t),1)
@test ≈(length(S.x),1)
@test S.id[1]=="DEAD.STA..EHZ"
ungap!(S::SeisData; m=false, w=false) # why do I have to force type here
@test ≈(length(S.x[1]), 260)
@test ≈(S.x[1][1:50], s1.x[1:50])
@test ≈(S.x[1][51:75], 0.5.*(s1.x[51:75] .+ s2.x[1:25]))
@test ≈(S.x[1][76:100], s1.x[76:100])
@test ≈(true, minimum(isnan.(S.x[1][101:125])))
@test ≈(S.x[1][126:225], s2.x[26:125])
@test ≈(true, minimum(isnan.(S.x[1][226:235])))
@test ≈(S.x[1][236:260], s2.x[126:150])

# Auto-tapering after a merge
T = deepcopy(S)
ii = findall(isnan.(S.x[1]))
# T.x[1] -= mean(T.x[1][!isnan(T.x[1])])
autotap!(S)
@test length(findall(isnan.(S.x[1])))==0           # No more NaNs?
@test sum(diff(S.x[1][ii]))==0                 # All NaNs filled w/same val?
@test ≈(T.x[1][12:90], S.x[1][12:90])     # Un-windowed vals untouched?

printstyled("  ...channel delete...\n", color=:light_green)
S -= 1
for i in fieldnames(typeof(S))
  if i != :n
    @test ≈(isempty([]), isempty(getfield(S,i)))
  end
end
@test isempty(S)

printstyled("  ...a more difficult merge...\n", color=:light_green)
S *= (s1 * s3)
S *= (s2 * s4)
@test ≈(S.n, 2)
@test ≈(length(S.fs), 2)
@test ≈(length(S.gain), 2)
@test ≈(length(S.name), 2)
@test ≈(length(S.t),2)
@test ≈(length(S.x),2)
@test ≈(S.fs[1], 100.0)
@test ≈(S.gain[2], 10.0)
@test ≈(true, S.id[2]=="DEAD.STA..EHZ")
ungap!(S, m=false, w=false)
@test ≈(length(S.x[2]), 260)
@test ≈(length(S.x[1]), 350)
@test ≈(S.x[1][101]/S.gain[1], s4.x[1]/s4.gain)

# Ensure merge works correctly with traces separated in time
printstyled("  ...channel merge with * operator...\n", color=:light_green)
s5 = SeisChannel(fs = 100.0, gain = 32.0, name = "DEAD.STA.EHE", id = "DEAD.STA..EHE",
  t = [1 t1; 100 0], x=randn(100))
s6 = SeisChannel(fs = 100.0, gain = 32.0, name = "UNNAMED", id = "DEAD.STA..EHE",
  t = [1 t1+30000000; 200 0], x=randn(200))
T = (s5 * s6)
ungap!(T)
@test ≈(length(T.x[1]),3200)
