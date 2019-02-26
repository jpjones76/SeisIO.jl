lenn_file = string(path, "/SampleFiles/0215162000.c00")

printstyled("  Lennartz ASCII...\n", color=:light_green)
A = rlennasc(lenn_file)
@test(occursin("rlennasc", A.src))
@test ≈(A.fs, 62.5)
S = SeisData(A)
