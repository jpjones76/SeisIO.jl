__precompile__()
module SeisIO
using Blosc, Dates, DSP, LightXML, LinearAlgebra, Printf, Sockets
using HTTP: request
using Statistics: mean
using Polynomials: polyfit, polyval

path = Base.source_dir()

# DO NOT CHANGE IMPORT ORDER
include("constants.jl")
include("CoreUtils/ls.jl")
include("CoreUtils/time.jl")

# Utilities that don't require SeisIO types to work but may depend on CoreUtils
for i in readdir(path*"/Utils")
  include(joinpath("Utils",i))
end

# Types and methods: do not change order of operations
include("Types/KWDefs.jl")
include("Types/SEED.jl")
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")
include("Types/SeisHdr.jl")
include("Types/SeisEvent.jl")
include("Types/note.jl")
for i in readdir(path*"/Types/Methods")
  include(joinpath("Types/Methods",i))
end

# Processing
for i in readdir(path*"/Processing")
  include(joinpath("Processing",i))
end

# Data formats
for i in readdir(path*"/Formats")
  if endswith(i, ".jl")
    include(joinpath("Formats",i))
  end
end

# Web clients
include("Web/WebMisc.jl")         # Common functions for web data access
include("Web/get_data.jl")          # Common method for retrieving data
include("Web/FDSN.jl")
include("Web/IRIS.jl")            # IRISws command line client
include("Web/SLConfig.jl")
include("Web/SeedLink.jl")

# The RandSeis submodule
include("RandSeis/RandSeis.jl")

end
