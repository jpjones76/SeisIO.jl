module SeisIO
using Blosc, Dates, DSP, LightXML, LinearAlgebra, Printf, Random, SharedArrays, Sockets, Statistics
using HTTP: request
__precompile__(true)
path = Base.source_dir()
const datafields = [:id, :name, :loc, :fs, :gain, :resp, :units, :src, :notes, :misc, :t, :x]
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]

# DO NOT CHANGE IMPORT ORDER
# Everything depends on these
include("CoreUtils/ls.jl")
include("CoreUtils/time.jl")
include("CoreUtils/safe_isfile.jl") # workaround for safe_isfile bad behaior in Windows

# Utilities that don't require SeisIO types to work
for i in readdir(path*"/Utils")
  include(joinpath("Utils",i))
end

# Types and core type functionality: do not change order of operations
include("Types/KWDefs.jl")
include("Types/SEED.jl")
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")
include("Types/SeisHdr.jl")
include("Types/SeisEvent.jl")
include("Types/note.jl")
include("Types/merge.jl")
include("Types/read.jl")
include("Types/show.jl")
include("Types/sync.jl")
include("Types/write.jl")

# Miscellaneous SeisIO-dependent functions
for i in readdir(path*"/Misc")
  if endswith(i, ".jl")
    include(joinpath("Misc",i))
  end
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
end
