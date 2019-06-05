# save to disk/read from disk
savfile1 = "test.evt"

printstyled("  read/write of EventTraceData with compression\n", color=:light_green)
SeisIO.KW.comp = 0x02
S = convert(EventTraceData, randSeisData())
wseis(savfile1, S)
R = rseis(savfile1, v=2)[1]
@test R == S

SeisIO.KW.comp = 0x01
S = convert(EventTraceData, randSeisData())
C = convert(EventChannel, SeisChannel())
nx = SeisIO.KW.n_zip*2
C.t = [1 0; nx 0]
C.x = randn(nx)
push!(S, C)
wseis(savfile1, S)
R = rseis(savfile1, v=2)[1]
@test R == S

rm(savfile1)
