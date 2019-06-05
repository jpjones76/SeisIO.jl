__precompile__()
module SeisIO
using Blosc, Dates, DSP, LightXML, LinearAlgebra, Printf, Sockets
using DelimitedFiles: readdlm
using FFTW: fft, ifft
using Glob: glob
using HTTP: request, Messages.statustext
using Statistics: mean
Blosc.set_compressor("lz4")
Blosc.set_num_threads(Sys.CPU_THREADS)
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
include("CoreUtils/typ2code.jl")
include("CoreUtils/file_io.jl")

# =========================================================
# Types and methods
# DO NOT CHANGE ORDER OF INCLUSIONS

# Back-end types
include("Types/KWDefs.jl")
include("Types/SeisIOBuf.jl")

# Prereqs for custom types
include("Types/InstPosition.jl")
include("Types/InstResp.jl")

# Abstract types
include("Types/GphysData.jl")
include("Types/GphysChannel.jl")

# Custom types
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")

for i in readdir(path*"/Types/Methods")
  if endswith(i, ".jl")
    include(joinpath("Types/Methods",i))
  end
end

# =========================================================
# Utilities that may require SeisIO types to work
for i in ls(path*"/Utils/")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Data processing operations
for i in ls(path*"/Processing/*")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Data formats
for i in ls(path*"/Formats/*")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Web clients
for i in ls(path*"/Web/")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Wrappers
for i in ls(path*"/Wrappers/")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Submodules
include("Quake/Quake.jl")
include("RandSeis/RandSeis.jl")

# We need these types for the native file format
using .Quake: EQLoc, EQMag, EventChannel, EventTraceData, PhaseCat, SeisEvent, SeisHdr, SeisPha, SeisSrc, SourceTime

# Last steps
include("Last/splat.jl")
include("Last/native_file_io.jl")

# Module ends
end
