printstyled("  get_seis_channels\n", color=:light_green)
S = randSeisData(20, s=1.0)
S = S[get_seis_channels(S)]
@test get_seis_channels(S, chans=1) == get_seis_channels(S, chans=1:1) == get_seis_channels(S, chans=[1]) == [1]
c1 = collect(1:S.n)
filt_seis_chans!(c1, S)
@test c1 == 1:S.n

C1 = randSeisChannel(s=true)
C2 = randSeisChannel(s=false, c=true)
C2.id = "...YYY"
S = SeisData(C1, C2, S)
chans = collect(1:S.n)
filt_seis_chans!(chans, S)
@test (2 in chans) == false
