__precompile__()
module SeisIO
using Blosc, Dates, DSP, LightXML, LinearAlgebra, Printf, Sockets
using FFTW: fft, ifft
using Glob: glob
using HTTP: request, Messages.statustext
using Statistics: mean

path = Base.source_dir()

# DO NOT CHANGE IMPORT ORDER
include("constants.jl")
include("CoreUtils/ls.jl")
include("CoreUtils/time.jl")
include("CoreUtils/namestrip.jl")

# Types and methods: do not change order of operations
include("Types/KWDefs.jl")
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")
include("Types/SeisHdr.jl")
include("Types/SeisEvent.jl")
include("Types/SeisIOBuf.jl")
include("Types/note.jl")
for i in readdir(path*"/Types/Methods")
  if endswith(i, ".jl")
    include(joinpath("Types/Methods",i))
  end
end

# Utilities that may require SeisIO types to work
for i in readdir(path*"/Utils")
  include(joinpath("Utils",i))
end

# Processing
for i in ls(path*"/Processing/*")
  if endswith(i, ".jl")
    include(joinpath("Processing",i))
  end
end

# Data formats
for i in ls(path*"/Formats/*")
  if endswith(i, ".jl")
    include(joinpath("Formats",i))
  end
end

# Web clients
for i in ls(path*"/Web/*")
  if endswith(i, ".jl")
    include(joinpath("Formats",i))
  end
end
# include("Web/WebMisc.jl")         # Common functions for web data access
# include("Web/get_data.jl")          # Common method for retrieving data
# include("Web/FDSN.jl")
# include("Web/IRIS.jl")            # IRISws command line client
# include("Web/SeedLink.jl")

# Wrappers
for i in ls(path*"/Wrappers/*")
  if endswith(i, ".jl")
    include(joinpath("Wrappers",i))
  end
end


# The RandSeis submodule
include("RandSeis/RandSeis.jl")

end
