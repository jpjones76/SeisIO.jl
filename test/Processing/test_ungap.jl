printstyled("  ungap!\n", color=:light_green)
printstyled("    subsample negative time gaps (Issue 29)\n", color=:light_green)

gf1 = path * "/SampleFiles/SEED/CIRIO__BHE___2017101.mseed"
opf = path * "/SampleFiles/SEED/obspy.dat"

# read merge/ungap target file
S = read_data(gf1)
C1 = deepcopy(S[1])
i1 = C1.t[2,1]
merge!(S)
ungap!(S)
C2 = S[1]
i2 = C2.t[2,1]

# read ObsPy merge output to compare
io = open(opf, "r")
X2 = Array{Int32,1}(undef, length(C2.x))
read!(io, X2)
X = map(Float32, X2)

# these should be approximately equal
@test isapprox(C2.x, X)
