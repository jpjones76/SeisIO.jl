module RandSeis
using SeisIO, SeisIO.Quake
using Random:randexp, randstring, shuffle!
import Dates:now
import SeisIO:InstrumentPosition, code2typ, getbandcode, note!, sμ, μs
export randSeisChannel, randSeisData, randSeisEvent, randSeisHdr, randPhaseCat,
randSeisSrc

include("RandSeis/randseis_utils.jl")
include("RandSeis/randSeisChannel.jl")
include("RandSeis/randSeisData.jl")
include("RandSeis/randSeisEvent.jl")

const fc_vals = Float64[1.0/120.0 1.0/60.0 1.0/30.0 0.2 1.0 1.0 1.0 2.0 4.5 15.0]
const fs_vals = Float64[0.1, 1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 40.0, 50.0, 60.0, 62.5, 80.0, 100.0, 120.0, 125.0, 250.0]
const irregular_units = ["%", "%{cloud_cover}", "{direction_vector}", "Cel", "K", "{none}", "Pa", "T", "V", "W", "m", "m/m", "m/s", "m/s2", "m3/m3", "rad", "rad/s", "rad/s2", "t{SO_2}"]

end
