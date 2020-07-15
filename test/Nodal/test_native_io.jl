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
for i in 1:12
  k = randstring(rand(1:32))
  t = rand([0x00000001,
            0x00000002,
            0x00000003,
            0x00000004,
            0x00000005,
            0x00000006,
            0x00000007,
            0x00000008,
            0x00000009,
            0x0000000a,
            0x00000020])
  T = get(SeisIO.Nodal.tdms_codes, t, UInt8)
  v = T == Char ? randstring(rand(1:64)) : rand(T)
  S.info[k] = v
end

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
