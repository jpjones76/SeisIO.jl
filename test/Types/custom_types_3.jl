H = randSeisHdr()
@test sizeof(H) > 0
clear_notes!(H)
@test length(H.notes) == 1

(S,T) = mktestseis()
U = S-T
sizetest(S,5)
sizetest(T,4)
sizetest(U,3)

(S,T) = mktestseis()
@test (S + T - T) == S

(S,T) = mktestseis()
U = deepcopy(S)
deleteat!(U, 1:3)
@test (S - [1,2,3]) == U
sizetest(S,5)
