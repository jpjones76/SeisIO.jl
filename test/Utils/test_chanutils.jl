S = randSeisData(3, s=1.0, nx=1024)
@test mkchans(1, S) == [1]
@test mkchans(1:2, S) == [1, 2]
@test mkchans([2,3], S) == [2, 3]

S.x[2] = Float64[]
@test mkchans([2,3], S) == [3]

S.t[3] = Array{Int64, 2}(undef, 0, 2)
@test mkchans(1:3, S, f=:t) == [1,2]
@test mkchans(1:3, S) == [1,3]

S.t[3] = [1 S.t[1][1,2]; length(S.x[3]) 0]
push!(S, randSeisChannel(c=true))
@test mkchans(1:4, S, keepirr=false) == [1, 3]
@test mkchans([2,3,4], S, keepirr=false) == [3]

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

printstyled("channel_match\n", color=:light_green)
C = SeisChannel()
D = SeisChannel()
@test channel_match(C, D)

C = randSeisChannel(s=true)
D = deepcopy(C)
C.gain = D.gain*0.5
@test channel_match(C, D) == false
@test channel_match(C, D, use_gain = false) == true

C.gain = D.gain
C.fs = D.fs*0.5
@test channel_match(C, D) == false

printstyled("cmatch_p!\n", color=:light_green)
C = randSeisChannel(s=true)
D = deepcopy(C)
C0 = deepcopy(C)

# Scenarios that must work:
# C set, D unset
D.fs = 0.0
D.gain = 1.0
D.loc = GeoLoc()
D.resp = PZResp()
D.units = ""
m = cmatch_p!(C,D)
@test m == true
@test channel_match(C, D) == true

# D set, C unset
C.fs = 0.0
C.gain = 1.0
C.loc = GeoLoc()
C.resp = PZResp()
C.units = ""
m = cmatch_p!(C,D)
@test m == true
@test channel_match(C, D) == true

# Values must preserve those in C0
@test channel_match(C, C0) == true

# Scenarios that must fail
C = randSeisChannel(s=true)
C.loc = GeoLoc(lat = 48.79911, lon=-122.54064, el=45.1104)
C.resp = PZResp(a0 = 223.43015f0, f0 = 2.0f0, p = ComplexF32.([-8.89+8.89im, 8.89-8.89im]))
C0 = deepcopy(C)

D = deepcopy(C0)
while D.units == C.units
  D.units = randstring()
end
@test cmatch_p!(C,D) == false
@test C == C0

D = deepcopy(C0)
D.fs = 2.0*C.fs
D0 = deepcopy(D)
@test cmatch_p!(C,D) == false
@test C == C0
@test D == D0

D = deepcopy(C0)
D.gain = 2.0*C.gain
D0 = deepcopy(D)
@test cmatch_p!(C,D) == false
@test C == C0
@test D == D0

D = deepcopy(C0)
D.loc.lat = 89.1
D0 = deepcopy(D)
@test cmatch_p!(C,D) == false
@test C == C0
@test D == D0

D = deepcopy(C0)
D.resp.f0 = 1.0f0
D0 = deepcopy(D)
@test cmatch_p!(C,D) == false
@test C == C0
@test D == D0
