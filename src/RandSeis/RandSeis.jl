module RandSeis
export randSeisChannel, randSeisData, randSeisEvent, randSeisHdr

using ..SeisIO: SeisData, SeisChannel, SeisHdr, SeisEvent, code2typ, getbandcode, note!, μs, sμ
import Dates:now
import Random:randexp, randstring, shuffle!

include("randseis_utils.jl")
include("randSeisChannel.jl")
include("randSeisData.jl")
include("randSeisEvent.jl")

end
