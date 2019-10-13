module SeisHDF
using Dates, HDF5, SeisIO, SeisIO.XMLwrite
import SeisIO: KW, TimeSpec, check_for_gap!, dtconst, endtime, parsetimewin,
  read_station_xml!, split_id, sxml_mergehdr!, trunc_x!
import SeisIO.XMLwrite: mk_xml!

# auxiliary functions
include("SeisHDF/load_data.jl")
include("SeisHDF/id_match.jl")
include("SeisHDF/get_trace_bounds.jl")

# readers
include("SeisHDF/read_asdf.jl")

# writers
include("SeisHDF/write_asdf.jl")

# wrappers
include("SeisHDF/read_hdf5.jl")
include("SeisHDF/write_hdf5.jl")

# scanner
include("SeisHDF/scan_hdf5.jl")

# These are adapted from unix2datetime.(1.0e-9.*[typemin(Int64), typemax(Int64)])
const unset_s = "1677-09-21T00:12:44"
const unset_t = "2262-04-11T23:47:16"

export read_hdf5, read_hdf5!, scan_hdf5, write_hdf5

end
