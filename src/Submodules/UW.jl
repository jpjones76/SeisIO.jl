module UW
using Mmap, SeisIO, SeisIO.FastIO, SeisIO.Quake
using Dates: DateTime

include("UW/imports.jl")
include("UW/uwdf.jl")
include("UW/uwpf.jl")
include("UW/uwevt.jl")
include("UW/desc.jl")

# exports
export formats, readuwevt, uwdf, uwdf!, uwpf, uwpf!

end
