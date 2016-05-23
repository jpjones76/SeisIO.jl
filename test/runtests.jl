using Base.Test, Compat
using SeisIO

include("./timeaux_test.jl")
include("./sac_test.jl")
include("./seisdata_test.jl")
include("./fileio_test.jl")
include("./file_formats.jl")
include("./fdsn_test.jl")
include("./iris_test.jl")
include("./seedlink_test.jl")

println("To test for faithful SAC writing of SeisData objects:")
println("     (0) Type `plotseis(SL)` at the Julia prompt.")
println("     (1) Type `wsac(SL)` at the Julia prompt.")
println("     (2) Open a terminal, change to the current directory, and start SAC.")
println("     (4) type `r *GPW*SAC *MBW*SAC; qdp off; plot1; lh default`.")
println("     (5) Report any discrepancies.")
