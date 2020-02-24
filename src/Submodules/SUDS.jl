module SUDS
using Mmap, SeisIO, SeisIO.FastIO, SeisIO.Quake

#=
  Submodule for SUDS data format accessories.
=#

include("SUDS/imports.jl")
include("SUDS/SUDSbuf.jl")
include("SUDS/suds_const.jl")
include("SUDS/suds_structs.jl")
include("SUDS/suds_decode.jl")
include("SUDS/suds_aux.jl")
include("SUDS/read_suds.jl")
include("SUDS/desc.jl")

# exports
export formats, readsudsevt, suds_support
end
