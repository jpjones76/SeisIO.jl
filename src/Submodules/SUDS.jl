module SUDS
using SeisIO, SeisIO.Quake
import SeisIO: checkbuf!, BUF, endtime, KW, sμ

include("SUDS/SUDSbuf.jl")
include("SUDS/suds_const.jl")
include("SUDS/suds_structs.jl")
include("SUDS/suds_decode.jl")
include("SUDS/suds_aux.jl")
include("SUDS/read_suds.jl")

# exports
export suds_support
end
