using Printf
fs = 100.0
nx = 10000000
T = Float32

# Methods
C = randSeisChannel(s=true)
C.fs = fs
C.t = [1 100; nx 0]
C.x = randn(T, nx)
D = filtfilt(C)
filtfilt!(C)
@test C == D
naive_filt!(D)

S = randSeisData(24, s=1.0)
deleteat!(S, findall(S.fs.<40.0))
Ev = SeisEvent(hdr=randSeisHdr(), data=deepcopy(S))
U = filtfilt(S)
filtfilt!(S)
@test U == S

Ev1 = filtfilt(Ev)
filtfilt!(Ev)
@test Ev1 == Ev

printstyled("\n  Filters applied to SeisData:\n\n", color = :light_green)
@printf("%12s | %10s | filt (MB) | data (MB) | ratio\n", "Name (dm=)", "Type (rt=)")
@printf("%12s | %10s | --------- | --------- | -----\n", " -----------", "---------")

for j = 1:2
  for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
    for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
      S = randSeisData(24, s=1.0)
      deleteat!(S, findall(S.fs.<40.0))
      b = @allocated(filtfilt!(S, rt=rt, dm=dm))
      s = sum([sizeof(S.x[i]) for i = 1:S.n])
      r = b/s

      if j == 2
        @printf("%12s | %10s | %9.2f | %9.2f | ", dm, rt, b/1024^2, s/1024^2)
        printstyled(@sprintf("%0.2f\n", r), color=(r ≥ 0.80 ? 1 :
                                                   r ≥ 0.60 ? 208 :
                                                   r ≥ 0.40 ? 184 :
                                                   r ≥ 0.20 ? 148 : 10))
      end
    end
  end
end

printstyled(string("\n  Filters vs. naive filtfilt! on a long, gapless ", T, " SeisChannel:\n\n"), color = :light_green)
@printf("%12s | %10s | filt (MB) | naive (MB) | data (MB) | ratio\n", "Name (dm=)", "Type (rt=)")
@printf("%12s | %10s | --------- | ---------- | --------- | -----\n", " -----------", "---------")

for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    C = randSeisChannel(s=true)
    C.fs = fs
    C.t = [1 100; nx 0]
    C.x = randn(T, nx)
    D = deepcopy(C)

    b = @allocated(filtfilt!(C, rt=rt, dm=dm))
    n = @allocated(naive_filt!(D, rt=rt, dm=dm))
    s = sizeof(C.x)
    p = b/s
    q = n/s
    r = p/q

    @printf("%12s | %10s | %9.2f | %10.2f | %9.2f | ", dm, rt, b/1024^2, n/1024^2, s/1024^2)
    printstyled(@sprintf("%0.2f\n", r), color=(r ≥ 0.80 ? 1 :
                                               r ≥ 0.60 ? 208 :
                                               r ≥ 0.40 ? 184 :
                                               r ≥ 0.20 ? 148 : 10))
  end
end
println("")
