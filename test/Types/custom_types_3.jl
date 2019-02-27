H = randSeisHdr()
@test sizeof(H) > 0
clear_notes!(H)
@test length(H.notes) == 0
