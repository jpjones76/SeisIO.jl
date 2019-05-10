__precompile__()
module SeisIO
using Blosc, Dates, DSP, LightXML, LinearAlgebra, Printf, Sockets
using FFTW: fft, ifft
using Glob: glob
using HTTP: request, Messages.statustext
using Statistics: mean

path = Base.source_dir()

# DO NOT CHANGE IMPORT ORDER
include("imports.jl")
include("constants.jl")

# =========================================================
# CoreUtils: SeisIO needs these for core functions
# DO NOT CHANGE ORDER OF INCLUSIONS
include("CoreUtils/ls.jl")
include("CoreUtils/time.jl")
include("CoreUtils/namestrip.jl")
include("CoreUtils/type2code.jl")

# =========================================================
# Types and methods
# DO NOT CHANGE ORDER OF INCLUSIONS

# Back-end
include("Types/KWDefs.jl")
include("Types/SeisIOBuf.jl")

# Prereqs for custom types
include("Types/InstPosition.jl")
include("Types/InstResp.jl")
include("Types/SeisPha.jl")

# Abstract types
include("Types/GphysData.jl")
include("Types/GphysChannel.jl")

# Custom types
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")
include("Types/EventTraceData.jl")
include("Types/EventChannel.jl")
include("Types/SeisHdr.jl")
include("Types/SeisEvent.jl")

for i in readdir(path*"/Types/Methods")
  if endswith(i, ".jl")
    include(joinpath("Types/Methods",i))
  end
end

# =========================================================
# Utilities that may require SeisIO types to work
for i in readdir(path*"/Utils")
  include(joinpath("Utils",i))
end

# =========================================================
# Data processing operations
for i in ls(path*"/Processing/*")
  if endswith(i, ".jl")
    include(joinpath("Processing",i))
  end
end

# =========================================================
# Data formats
for i in ls(path*"/Formats/*")
  if endswith(i, ".jl")
    include(joinpath("Formats",i))
  end
end

# =========================================================
# Web clients
for i in ls(path*"/Web/*")
  if endswith(i, ".jl")
    include(joinpath("Formats",i))
  end
end

# =========================================================
# Wrappers
for i in ls(path*"/Wrappers/*")
  if endswith(i, ".jl")
    include(joinpath("Wrappers",i))
  end
end

# =========================================================
# The RandSeis submodule
include("RandSeis/RandSeis.jl")

end
