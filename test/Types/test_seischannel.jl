printstyled("  SeisChannel methods\n", color=:light_green)

id = "UW.SEP..EHZ"
name = "Darth Exploded"

Ch = randSeisChannel()
Ch.id = id
Ch.name = name
S = SeisData(Ch)

@test in(id, Ch) == true
@test isempty(Ch) == false
@test convert(SeisData, Ch) == SeisData(Ch)
@test findid(Ch, S) == 1
@test sizeof(Ch) > 0
@test lastindex(S) == 1

S = randSeisData()
C = randSeisChannel()
U = C + S
@test findid(C,U) == 1
