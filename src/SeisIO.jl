__precompile__()
module SeisIO
using Blosc, Dates, DSP, FFTW, LightXML, LinearAlgebra, Markdown, Mmap, Printf, Sockets
using DelimitedFiles: readdlm
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
include("CoreUtils/IO/FastIO.jl")
using .FastIO

include("CoreUtils/ls.jl")
include("CoreUtils/time.jl")
include("CoreUtils/namestrip.jl")
include("CoreUtils/typ2code.jl")
include("CoreUtils/poly.jl")
include("CoreUtils/calculus.jl")
include("CoreUtils/svn.jl")
include("CoreUtils/IO/read_utils.jl")
include("CoreUtils/IO/string_vec_and_misc.jl")

# =========================================================
# Types and methods
# DO NOT CHANGE ORDER OF INCLUSIONS

# Back-end types
include("Types/KWDefs.jl")

# Prereqs for custom types
include("Types/InstPosition.jl")
include("Types/InstResp.jl")

# IO buffer including location and instrument response buffers
include("Types/SeisIOBuf.jl")

# Abstract types
include("Types/GphysData.jl")
include("Types/GphysChannel.jl")

# Custom types
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")

for i in ls(path*"/Types/Methods/")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Logging
for i in ls(path*"/Logging/*")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Utilities that may require SeisIO types to work
for i in ls(path*"/Utils/")
  if endswith(i, ".jl")
    include(i)
  end
end
include("Utils/Parsing/streams.jl")
include("Utils/Parsing/strings.jl")
include("Utils/Parsing/buffers.jl")

# =========================================================
# Data processing operations
for i in ls(path*"/Processing/*")
  if endswith(i, ".jl")
    include(i)
  end
end

# =========================================================
# Data formats
for i in ls(path*"/Formats/")
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
# Submodules
#= Dependencies
.FastIO
    └---------------> Types/
            ╭-----------┴-----------------------┐
         .Quake                                 |
    ╭-------┴---┬--------┬--------┐         ╭---┴---┐
.RandSeis   .SeisHDF    .UW     .SUDS    .ASCII   .SEED
                └--------+--------┘         └---┬---┘
                         |                      |
                         v                      |
                      Wrappers/ <---------------┘
=#

include("Submodules/FormatGuide.jl")
using .Formats

include("Submodules/ASCII.jl")
using .ASCII

include("Submodules/Nodal.jl")
using .Nodal
import .Nodal: convert

include("Submodules/SEED.jl")
using .SEED
using .SEED: parserec!, read_seed_resp!, seed_cleanup!
export mseed_support, read_dataless, read_seed_resp!, read_seed_resp, RESP_wont_read, seed_support

# We need these types for the native file format
include("Submodules/Quake.jl")
using .Quake
import .Quake: convert, fwrite_note_quake!, merge_ext!
export read_qml, write_qml

include("Submodules/RandSeis.jl")

include("Submodules/SeisHDF.jl")
using .SeisHDF: read_hdf5, read_hdf5!, scan_hdf5, write_hdf5
export read_hdf5, read_hdf5!, scan_hdf5, write_hdf5

include("Submodules/SUDS.jl")

include("Submodules/UW.jl")

# =========================================================
# Wrappers
for i in ls(path*"/Wrappers/")
  if endswith(i, ".jl")
    include(i)
  end
end

formats["list"] = collect(keys(formats))

# Last steps
include("Last/splat.jl")
include("Last/native_file_io.jl")
include("Last/read_legacy.jl")
include("Last/set_file_ver.jl")

# Module ends
end
