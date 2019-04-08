# Test tracking of changes in SeisData structure S ==========================
# Does S change? Let's see.
printstyled("  Tracking with track_on!, track_off!\n", color=:light_green)

S = SeisData()
track_on!(S)  # should do nothing but no error
@test track_off!(S) == nothing # should return nothing for empty struct

S = SeisData(3)
@test track_off!(S) == [true,true,true]
# @test_throws ErrorException("Tracking not enabled!") track_off!(S)

# Now replace S with randSeisData
S = randSeisData(3)
track_on!(S)
@test haskey(S.misc[1], "track")
S += randSeisChannel()
u = track_off!(S)
@test (u == [false, false, false, true])
@test haskey(S.misc[1], "track") == false

# Now turn tracking on again and move things around
track_on!(S)
@test haskey(S.misc[1], "track")
Ch1 = deepcopy(S[1])
Ch3 = deepcopy(S[3])
S[3] = deepcopy(Ch1)
S[1] = deepcopy(Ch3)
@test haskey(S.misc[3], "track")
@test haskey(S.misc[1], "track") == false
@test haskey(S.misc[2], "track") == false
append!(S.x[1], rand(Float64, 1024))        # Should flag channel 1 as updated
S.id[2] = reverse(S.id[2])                  # Should flag channel 2 as updated
u = track_off!(S)
@test (u == [true, true, false, false])
@test haskey(S.misc[3], "track") == false
