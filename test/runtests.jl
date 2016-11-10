using Base.Test, Compat
using SeisIO

println("begin tests:")

println("timeaux...")
include("./timeaux_test.jl")

println("SAC i/o...")
include("./sac_test.jl")

println("seisdata...")
include("./seisdata_test.jl")

println("randseis and native file i/o...")
include("./fileio_test.jl")

println("other (non-SAC) file formats...")
include("./file_formats.jl")

println("FDSN data queries...")
include("./fdsn_test.jl")

println("IRIS web services...")
include("./iris_test.jl")

println("SEEDlink client...")
include("./seedlink_test.jl")

println("To test for faithful SAC write of SeisIO in SAC:")
println("     (1) Type `wsac(SL)` at the Julia prompt.")
println("     (2) Open a terminal, change to the current directory, and start SAC.")
println("     (4) type `r *GPW*SAC *MBW*SAC; qdp off; plot1; lh default`.")
println("     (5) Report any irregularities.")

println("To run the canonical examples type include(\"", dirname(Base.source_path()), "/examples.jl\")")
