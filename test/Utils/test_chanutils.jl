S = randSeisData(3, s=1.0, nx=1024)
@test mkchans(1, S) == [1]
@test mkchans(1:2, S) == [1, 2]
@test mkchans([2,3], S) == [2, 3]

S.x[2] = Float64[]
@test mkchans([2,3], S) == [3]

S.t[3] = Array{Int64, 2}(undef, 0, 2)
@test mkchans(1:3, S, f=:t) == [1,2]
@test mkchans(1:3, S) == [1,3]

S = randSeisData(3, s=1.0, nx=1024)
@test get_seis_channels(S, chans=3) == [3]
@test get_seis_channels(S, chans=1:2) == [1,2]
@test get_seis_channels(S, chans=[1,3]) == [1,3]

cr = [1,2,3]
c0 = deepcopy(cr)
filt_seis_chans!(cr, S)
@test cr == c0

S.id[1] = "...0"
filt_seis_chans!(cr, S)
@test cr != c0
@test cr == [2,3]
