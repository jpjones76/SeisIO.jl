module RandSeis
using Random, SeisIO, SeisIO.Quake

include("RandSeis/imports.jl")
if VERSION <= v"1.1.0"
  include("RandSeis/1/constants.jl")
  include("RandSeis/1/utils.jl")
else
  include("RandSeis/constants.jl")
  include("RandSeis/utils.jl")
end
include("RandSeis/randSeisChannel.jl")
include("RandSeis/randSeisData.jl")
include("RandSeis/randSeisEvent.jl")
include("RandSeis/exports.jl")

end
