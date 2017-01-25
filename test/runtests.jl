using Base.Test, Compat
using SeisIO
path = Base.source_dir()
println(STDOUT, path)

include(path*"/../src/SeisIO.jl")

println("begin tests:")

println("time (time.jl)...")
include(path*"/time.jl")

println("read/write \"misc\" dictionary (misc_rw.jl)...")
include(path*"/misc_rw.jl")

println("SAC (sac.jl)...")
include(path*"/sac.jl")

println("SeisData test 1 (seisdata1.jl)...")
include(path*"/seisdata1.jl")

println("seisdata test 2 (seisdata2.jl)...")
include(path*"/seisdata2.jl")

println("randseis and native format i/o (native_io.jl)...")
include(path*"/native_io.jl")

println("other (non-SAC) file formats (file_formats.jl)...")
include(path*"/file_formats.jl")

println("FDSN XML parsing...")
include(path*"/xml.jl")

println("FDSN data queries (fdsn.jl)...")
include(path*"/fdsn.jl")

println("IRIS web services (iris.jl)...")
include(path*"/iris.jl")

println("SEEDlink client (seedlink.jl)...")
include(path*"/seedlink.jl")

println("To test for faithful SAC write of SeisIO in SAC:")
println("     (1) Type `wsac(SL)` at the Julia prompt.")
println("     (2) Open a terminal, change to the current directory, and start SAC.")
println("     (4) type `r *GPW*SAC *MBW*SAC; qdp off; plot1; lh default`.")
println("     (5) Report any irregularities.")

println("To run the canonical examples type include(\"", path, "/examples.jl\")")
