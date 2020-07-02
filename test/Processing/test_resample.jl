printstyled("  resample!\n", color=:light_green)

function check_resamp()
  S = randSeisData(fs_min=20.0)
  sz = sizeof(S)
  (xx, ta, aa, xx, xx) = @timed resample(S, fs=10.0)
  return [aa/sz ta]
end

N = 20
check_resamp()
C = randSeisChannel()
nx = 8640000
C.t = [1 0; nx 0]
C.fs = 100.0
C.x = rand(Float32, nx)
resample!(C, 50.0)

C = randSeisChannel()
C.t = [       1  1559599308051202;
          29229          46380573;
         194240                 0]
C.x = randn(194240)
C.fs = 40.0
resample!(C, 10.0)
@test length(C.x) == 48560

# A controlled test with two groups of channels, 40.0 Hz and 20.0 Hz
printstyled("    downsample\n", color=:light_green)
S = randSeisData(4)
S.id = ["NN.STA1.00.EHZ", "NN.STA2.00.EHZ", "NN.STA3.00.EHZ", "NN.STA4.00.EHZ"]
n = 400
fs = 20.0
t20 = [1 1559599308051202; n 0]
t40 = [1 1559599308051202; 2n 0]
S.fs = [fs, 2fs, fs, 2fs]
S.t = [deepcopy(t20), deepcopy(t40), deepcopy(t20), deepcopy(t40)]
S.x = [randn(n), randn(2n), randn(n), randn(2n)]
U = deepcopy(S)
resample!(S, fs=fs)
for i = 1:S.n
  @test length(S.x[i]) == n
  @test S.fs[i] == fs
  @test S.t[i] == t20
end

norm_sz = Array{Float64,2}(undef,N,2)
printstyled("      trial ", color=:light_green)
for i = 1:N
  if i > 1
    print("\b\b\b\b\b")
  end
  printstyled(string(lpad(i, 2), "/", N), color=:light_green)
  norm_sz[i,:] = check_resamp()
end
println("")
println(stdout, "  mean overhead (", N, " random trials): ",
  @sprintf("%0.1f%%", 100.0*(mean(norm_sz[:,1])-1.0)), "; ",
  "mean t = " , @sprintf("%0.2f", mean(norm_sz[:,2])))

# Now with upsampling
printstyled("    upsample (Issue #50)\n", color=:light_green)
S = deepcopy(U)
resample!(S, fs=2fs)
for i = 1:S.n
  L = length(S.x[i])
  @test L in (2n, 2n-1)
  @test S.fs[i] == 2fs
  @test S.t[i] == (L == 2n ? t40 : [1 1559599308051202; 2n-1 0])
end

printstyled("    test on long, gapless Float32 SeisChannel\n", color=:light_green)

S = randSeisChannel()
nx = 8640000
S.t = [1 0; nx 0]
S.fs = 100.0
S.x = rand(Float32, nx)
U = SeisData(deepcopy(S))
C = resample(S, 50.0)
sz = sizeof(S)

(xx, ta, aa, xx, xx) = @timed resample!(S, 50.0)
println(stdout, "  resample!: overhead = ",
  @sprintf("%0.1f%%", 100.0*(aa/sz - 1.0)), ", t = ",
  @sprintf("%0.2f", ta), " s")
