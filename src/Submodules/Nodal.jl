module Nodal
using Dates, LinearAlgebra, Mmap, SeisIO, SeisIO.FastIO
path = Base.source_dir()

# Imports
include("Nodal/imports.jl")

# Constants
include("Nodal/Types/TDMSbuf.jl")
include("Nodal/constants.jl")

# Types
include("Nodal/Types/NodalData.jl")
include("Nodal/Types/NodalChannel.jl")

# Formats
include("Nodal/Formats/desc.jl")
include("Nodal/Formats/tdms.jl")

# Utils
for i in ls(path*"/Nodal/Utils/")
  if endswith(i, ".jl")
    include(i)
  end
end

# Wrappers
include("Nodal/Wrappers/read_nodal.jl")

# Exports
include("Nodal/exports.jl")

end
