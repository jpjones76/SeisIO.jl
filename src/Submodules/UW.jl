module UW
using SeisIO, SeisIO.FastIO, SeisIO.Quake
using Dates: DateTime

include("UW/imports.jl")
include("UW/uwdf.jl")
include("UW/uwpf.jl")
include("UW/uwevt.jl")
include("UW/desc.jl")

# exports
export readuwevt, uwdf, uwdf!, uwpf, uwpf!, formats

end
