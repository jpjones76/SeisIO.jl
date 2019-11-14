module SeisHDF
using Dates, HDF5, SeisIO, SeisIO.Quake

# imports
include("SeisHDF/imports.jl")

# constants
include("SeisHDF/constants.jl")

# auxiliary functions
include("SeisHDF/load_data.jl")
include("SeisHDF/save_data.jl")
include("SeisHDF/id_match.jl")
include("SeisHDF/get_trace_bounds.jl")
include("SeisHDF/asdf_aux.jl")

# readers
include("SeisHDF/read_asdf.jl")
include("SeisHDF/read_asdf_evt.jl")

# writers
include("SeisHDF/write_asdf.jl")

# wrappers
include("SeisHDF/read_hdf5.jl")
include("SeisHDF/write_hdf5.jl")

# scanners
include("SeisHDF/scan_hdf5.jl")
include("SeisHDF/asdf_qml.jl")

# exports
include("SeisHDF/exports.jl")
end
