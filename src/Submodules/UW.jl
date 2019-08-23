module UW
using SeisIO, SeisIO.Quake
using Dates: DateTime
import SeisIO: BUF, KW, checkbuf!, checkbuf_8!, dtconst, endtime, fill_id!, fillx_i16_be!, fillx_i32_be!, sμ
import SeisIO.Quake: unsafe_convert

include("UW/uwdf.jl")
include("UW/uwpf.jl")
include("UW/uwevt.jl")

# exports
export readuwevt, uwdf, uwdf!, uwpf, uwpf!

end
