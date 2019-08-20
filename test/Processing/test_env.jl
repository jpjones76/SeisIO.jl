printstyled("  env!\n", color=:light_green)

# GphysChannel, gaps
printstyled("    on SeisChannel\n", color=:light_green)
C = randSeisChannel(s=true)
C.t = [ 1 0;
        2 500;
        1959 69420;
        90250 0]
C.x = randn(C.t[end,1])
env!(C)

# GphysChannel, no gaps
C = randSeisChannel(s=true)
ungap!(C)
D = env(C)

# GphysData
printstyled("    on SeisData\n", color=:light_green)
S = randSeisData(24)
ungap!(S)
U = deepcopy(S)
env!(S, v=2)
T = env(U, v=2)
printstyled("    testing that env! == DSP.hilbert\n", color=:light_green)
for i = 1:S.n
  if S.fs[i] > 0.0
    ex1 = S.x[i]
    ex2 = abs.(DSP.hilbert(U.x[i]))
    @test isapprox(S.x[i], abs.(DSP.hilbert(U.x[i])))
    @test isapprox(S.x[i], T.x[i])
  end
end
