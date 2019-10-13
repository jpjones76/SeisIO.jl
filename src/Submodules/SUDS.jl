module SUDS
using SeisIO, SeisIO.Quake
import SeisIO: check_for_gap!, checkbuf!, checkbuf_8!, BUF, KW, sμ
import SeisIO.Formats: formats, FmtVer, FormatDesc, HistVec

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
