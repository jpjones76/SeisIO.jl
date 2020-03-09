printstyled("  resample!\n", color=:light_green)

function naive_resample!(S::SeisData; fs::Float64=0.0)
  f0 = fs == 0.0 ? minimum(S.fs[S.fs .> 0.0]) : fs
  for i = 1:S.n
    (S.fs[i] == 0.0) && continue
    T = eltype(S.x[i])
    rate = rationalize(fs/S.fs[i])
    n_seg = size(S.t[i],1)-1
    gap_inds = Array{Int64,1}(undef, n_seg+1)
    gap_inds[1] = 1
    for k = n_seg:-1:1
      si            = S.t[i][k,1]
      ei            = S.t[i][k+1,1] - (k == n_seg ? 0 : 1)
      nx_old        = ei-si+1
      nx            = round(Int, nx_old*rate)
      x = T.(DSP.resample(S.x[i][si:ei], rate)[1:nx])
      copyto!(S.x[i], si, x, 1, nx)
      deleteat!(S.x[i], si+nx:ei)
      gap_inds[k+1]  = ceil(Int, ei*rate)
    end
    copyto!(S.t[i], 1, gap_inds, 1, n_seg+1)
    S.fs[i] = f0
    note!(S, i, string("naive_resample!, fs=", repr("text/plain", f0, context=:compact=>true)))
  end
  return nothing
end

function compare_resamp()
  S = randSeisData(fs_min=20.0)
  U = deepcopy(S)
  sz = sizeof(S)
  (xx, ta, aa, xx, xx) = @timed resample(S, fs=10.0)
  (xx, tb, ab, xx, xx) = @timed naive_resample!(U, fs=10.0)
  return [aa/sz ab/sz ta tb]
end

N = 20
compare_resamp()
C = randSeisChannel()
nx = 8640000
C.t = [1 0; nx 0]
C.fs = 100.0
C.x = rand(Float32, nx)
resample!(C, 50.0)

C = randSeisChannel()
C.t = [       1  1559599308051202;
          29228          46380573;
         194240                 0]
C.x = randn(194240)
C.fs = 40.0
resample!(C, 10.0)
@test length(C.x) == 48561 # off by one because of the gap

# A controlled test with two groups of channels, 40.0 Hz and 20.0 Hz
S = randSeisData(4)
S.id = ["NN.STA1.00.EHZ", "NN.STA2.00.EHZ", "NN.STA3.00.EHZ", "NN.STA4.00.EHZ"]
n = 400
fs = 20.0
t20 = [1 1559599308051202; n 0]
t40 = [1 1559599308051202; 2n 0]
S.fs = [fs, 2fs, fs, 2fs]
S.t = [deepcopy(t20), deepcopy(t40), deepcopy(t20), deepcopy(t40)]
S.x = [randn(n), randn(2n), randn(n), randn(2n)]
resample!(S, fs=fs)
for i = 1:S.n
  @test length(S.x[i]) == n
  @test S.fs[i] == fs
  @test S.t[i] == t20
end

norm_sz = Array{Float64,2}(undef,N,4)
printstyled("      trial ", color=:light_green)
for i = 1:N
  if i > 1
    print("\b\b\b\b\b")
  end
  printstyled(string(lpad(i, 2), "/", N), color=:light_green)
  norm_sz[i,:] = compare_resamp()
end
println("")
println(stdout, "  mean overhead (", N, " random trials): ",
  @sprintf("%0.1f%%", 100.0*(mean(norm_sz[:,1])-1.0)), "; ",
  "mean t = " , @sprintf("%0.2f", mean(norm_sz[:,3])))
println(stdout, "  naive (unsorted) resample by segment: ",
  @sprintf("%0.1f%%", 100.0*(mean(norm_sz[:,2])-1.0)), "; ",
  "mean t = " , @sprintf("%0.2f", mean(norm_sz[:,4])))

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
(xx, tb, ab, xx, xx) = @timed naive_resample!(U, fs=50.0)

println(stdout, "  resample!: overhead = ",
  @sprintf("%0.1f%%", 100.0*(aa/sz - 1.0)), ", t = ",
  @sprintf("%0.2f", ta), " s")
println(stdout, "  naive resample!: overhead = ",
  @sprintf("%0.1f%%", 100.0*(ab/sz - 1.0)), ", t = ",
  @sprintf("%0.2f", tb), " s")
