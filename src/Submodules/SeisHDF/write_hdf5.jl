@doc """
    write_hdf5( hdf_out::String, S::GphysData )

Write data in a seismic HDF5 format to file `hdf_out` from structure `S`.

See also: read_hdf5
""" write_hdf5
function write_hdf5(file::String, S::GphysData;
  fmt ::String                = "asdf",                 # data format
  v   ::Int64                 = KW.v                    # verbosity
  )

  if fmt == "asdf"
    write_asdf(file, S)
  else
    error("Unknown file format (possibly NYI)!")
  end

  return nothing
end

function write_hdf5(file::String, C::GphysChannel;
  fmt ::String                = "asdf",                 # data format
  v   ::Int64                 = KW.v                    # verbosity
  )
  S = SeisData(C)
  write_hdf5(file, S, fmt=fmt, v=v)
  return nothing
end
