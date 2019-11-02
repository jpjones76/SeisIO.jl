module SeisHDF
using Dates, HDF5, SeisIO, SeisIO.Quake
import LightXML: free, parse_string
import SeisIO: KW, TimeSpec, check_for_gap!, dtconst, endtime, mk_xml!,
  parsetimewin, read_station_xml!, split_id, sxml_mergehdr!, t_win, trunc_x!
import SeisIO.Quake:event_xml!, new_qml!, write_qml!

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
include("SeisHDF/read_asdf_evt.jl")

# writers
include("SeisHDF/write_asdf.jl")

# wrappers
include("SeisHDF/read_hdf5.jl")
include("SeisHDF/write_hdf5.jl")

# scanners
include("SeisHDF/scan_hdf5.jl")
include("SeisHDF/asdf_qml.jl")

export asdf_rqml, asdf_wqml, read_asdf_evt, read_hdf5, read_hdf5!, scan_hdf5, write_hdf5

end
