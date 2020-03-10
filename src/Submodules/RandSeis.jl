module RandSeis
using Random, SeisIO, SeisIO.Quake

include("RandSeis/imports.jl")
if VERSION <= v"1.1.0"
  include("RandSeis/constants_1.jl")
else
  include("RandSeis/constants.jl")
end
include("RandSeis/iccodes_and_units.jl")
include("RandSeis/utils.jl")
include("RandSeis/randSeisChannel.jl")
include("RandSeis/randSeisData.jl")
include("RandSeis/randSeisEvent.jl")
include("RandSeis/exports.jl")

end
