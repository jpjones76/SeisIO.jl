#AuxiliaryData/{...}/{...}/{TAG}
function asdf_getaux( hdf_out::String )
  if isfile(hdf_out)
    io = h5open(hdf_out, "r+")
    fmt = read(attrs(io)["file_format"])
    (fmt == "ASDF") || (close(io); error("invalid ASDF file!"))
    if has(io, "AuxiliaryData")
      aux = io["AuxiliaryData"]
    else
      aux = g_create(io, "AuxiliaryData")
    end
  else
    io = h5open(hdf_out, "cw")
    attrs(io)["file_format"] = "ASDF"
    attrs(io)["file_format_version"] = "1.0.2"
    aux = g_create(io, "AuxiliaryData")
  end
  return io, aux
end

"""
    asdf_waux(hdf_out, path, X)

Write `X` to AuxiliaryData/path in `hdf_out`. If an object already exists at
AuxiliaryData/path, it will be deleted and overwritten with `X`.
"""
function asdf_waux(hdf_out::String, path::String, X::Union{HDF5Type,HDF5Array})
  # Correct leading /
  while startswith(path, "/")
    path = path[nextind(path, 1):lastindex(path)]
  end

  # Correct paths that start with AuxiliaryData
  startswith(path, "AuxiliaryData") && (path = String(split(path, "/", limit=2, keepempty=true)[2]))

  io, aux = asdf_getaux(hdf_out)

  # Remove existing object if it exists
  has(aux, path) && o_delete(aux, path)
  aux[path] = X
  close(io)
  return nothing
end
