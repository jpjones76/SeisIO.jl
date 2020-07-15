# save to disk/read from disk
printstyled("  Native file I/O\n", color=:light_green)
savfile1 = "test.dat"
fs = 100.0
nc = 10
nx = 2^12

D = randSeisData(nc, nx=nx, s=1.0)
t = mk_t(nx, D.t[1][1,2])
for i in 1:D.n
  D.fs[i] = fs
  D.t[i] = copy(t)
end
S = convert(NodalData, D)
S.ox = (rand()-0.5) * 360.0
S.oy = (rand()-0.5) * 90.0
S.oz = rand()*1000.0
S.info["foo"] = "bar"
pop_nodal_dict!(S.info)

printstyled("    NodalChannel\n", color=:light_green)
C = getindex(S, 1)
wseis(savfile1, C)
R = rseis(savfile1)[1]
@test R == C

printstyled("    NodalData\n", color=:light_green)
wseis(savfile1, S)
R = rseis(savfile1)[1]
@test R == S
rm(savfile1)
