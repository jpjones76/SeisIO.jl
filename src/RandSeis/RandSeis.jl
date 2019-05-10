module RandSeis
using ..SeisIO: EQLoc, EventTraceData, GeoLoc, PZResp, PZResp64, SeisData, SeisChannel, SeisHdr, SeisEvent,
  code2typ, getbandcode, note!, sμ, μs
import Dates:now
import Random:randexp, randstring, shuffle!

export randSeisChannel, randSeisData, randSeisEvent, randSeisHdr

include("randseis_utils.jl")
include("randSeisChannel.jl")
include("randSeisData.jl")
include("randSeisEvent.jl")

end
