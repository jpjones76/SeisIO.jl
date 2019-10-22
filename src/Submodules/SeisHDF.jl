module SeisHDF
using Dates, HDF5, SeisIO
import SeisIO: KW, TimeSpec, check_for_gap!, dtconst, endtime, mk_xml!,
  parsetimewin, read_station_xml!, split_id, sxml_mergehdr!, t_win, trunc_x!

# These are adapted from unix2datetime.(1.0e-9.*[typemin(Int64), typemax(Int64)])
const unset_s = "1677-09-21T00:12:44"
const unset_t = "2262-04-11T23:47:16"

# auxiliary functions
include("SeisHDF/load_data.jl")
include("SeisHDF/save_data.jl")
include("SeisHDF/id_match.jl")
include("SeisHDF/get_trace_bounds.jl")
include("SeisHDF/asdf_aux.jl")

# readers
include("SeisHDF/read_asdf.jl")

# writers
include("SeisHDF/write_asdf.jl")

# wrappers
include("SeisHDF/read_hdf5.jl")
include("SeisHDF/write_hdf5.jl")

# scanner
include("SeisHDF/scan_hdf5.jl")

export read_hdf5, read_hdf5!, scan_hdf5, write_hdf5

end
