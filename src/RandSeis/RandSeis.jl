module RandSeis
using SeisIO, SeisIO.Quake
using Random:randexp, randstring, shuffle!
import Dates:now
import SeisIO:InstrumentPosition, code2typ, getbandcode, note!, sμ, μs
export randSeisChannel, randSeisData, randSeisEvent, randSeisHdr, randPhaseCat,
randSeisSrc

include("randseis_utils.jl")
include("randSeisChannel.jl")
include("randSeisData.jl")
include("randSeisEvent.jl")

end
