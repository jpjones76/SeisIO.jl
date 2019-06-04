fs = 100.0
nx = 10000000
T = Float32

printstyled("  filtfilt!\n", color=:light_green)
Δ = round(Int, 1.0e6/fs)

# Methods
C = randSeisChannel(s=true)
C.fs = fs
C.t = [1 100; div(nx,4) Δ; div(nx,2) 5*Δ+3; nx 0]
C.x = randn(T, nx)
D = filtfilt(C)
filtfilt!(C)
@test C == D

printstyled("    equivalence with DSP.filtfilt\n", color=:light_green)
for i = 1:10
  C = randSeisChannel(s=true)
  C.fs = fs
  C.t = [1 100; nx 0]
  C.x = randn(Float64, 100000)
  D = deepcopy(C)
  filtfilt!(C)
  naive_filt!(D)
  @test isapprox(C.x, D.x)
end

printstyled("    former breaking cases\n", color=:light_green)
printstyled("      very short data windows\n", color=:light_green)
n_short = 5

C = randSeisChannel()
C.fs = fs
C.t = [1 0; n_short 0]
C.x = randn(Float32, n_short)
filtfilt!(C)

S = randSeisData(24, s=1.0)
deleteat!(S, findall(S.fs.<40.0))
S.fs[S.n] = fs
S.t[S.n] = [1 0; n_short 0]
S.x[S.n] = randn(Float32, n_short)
filtfilt!(S)

printstyled("      repeated segment lengths\n", color=:light_green)
n_rep = 2048

S = randSeisData(24, s=1.0)
deleteat!(S, findall(S.fs.<40.0))
for i in (1, S.n)
  S.fs[i] = fs
  S.t[i] = [1 0; n_rep 0]
  S.x[i] = randn(Float32, n_rep)
end
filtfilt!(S)
GC.gc()

printstyled("    checking that all filters work\n", color=:light_green)
for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    S = randSeisData(3, s=1.0)
    while maximum(S.fs) < 40.0
      S = randSeisData(3, s=1.0)
    end
    deleteat!(S, findall(S.fs.<40.0))
    filtfilt!(S, rt=rt, dm=dm)
  end
end

printstyled("    test all filters on SeisData\n\n", color = :light_green)
@printf("%12s | %10s | time (ms) | filt (MB) | data (MB) | ratio\n", "Name (dm=)", "Type (rt=)")
@printf("%12s | %10s | --------- | --------- | --------- | -----\n", " -----------", "---------")

for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    S = randSeisData(24, s=1.0)
    deleteat!(S, findall(S.fs.<40.0))
    (xx, t, b, xx, xx) = @timed filtfilt!(S, rt=rt, dm=dm)
    s = sum([sizeof(S.x[i]) for i = 1:S.n])
    r = b/s
    @printf("%12s | %10s | %9.2f | %9.2f | %9.2f | ", dm, rt, t*1000, b/1024^2, s/1024^2)
    printstyled(@sprintf("%0.2f\n", r), color=printcol(r))
    GC.gc()
  end
end

printstyled(string("\n    test all filters on a long, gapless ", T, " SeisChannel\n\n"), color = :light_green)
@printf("%12s | %10s |  data   |     filtfilt!    |  naive_filtfilt! |     ratio    |\n", "", "")
@printf("%12s | %10s | sz (MB) | t (ms) | sz (MB) | t (ms) | sz (MB) | speed | size |\n", "Name (dm=)", "Type (rt=)")
@printf("%12s | %10s | ------- | ------ | ------- | ------ | ------- | ----- | ---- |\n", " -----------", "---------")

for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    C = randSeisChannel(s=true)
    C.fs = fs
    C.t = [1 100; nx 0]
    C.x = randn(T, nx)
    D = deepcopy(C)

    # b = @allocated(filtfilt!(C, rt=rt, dm=dm))
    (xx, tc, b, xx, xx) = @timed(filtfilt!(C, rt=rt, dm=dm))
    (xx, td, n, xx, xx) = @timed(naive_filt!(D, rt=rt, dm=dm))
    # n = @allocated(naive_filt!(D, rt=rt, dm=dm))
    sz = sizeof(C.x)
    p = b/sz
    r = b/n
    q = tc/td

    @printf("%12s | %10s | %7.2f | %6.1f | %7.2f | %6.1f | %7.2f | ", dm, rt, sz/1024^2, tc*1000.0, b/1024^2, td*1000.0, n/1024^2)
    printstyled(@sprintf("%5.2f", q), color=printcol(q))
    @printf(" | ")
    printstyled(@sprintf("%4.2f", r), color=printcol(r))
    @printf(" | \n")
    GC.gc()
  end
end
println("")
