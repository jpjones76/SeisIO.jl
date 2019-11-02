"""
    scan_hdf5(hdf)

Scan HDF5 archive `hdf` and return station names with waveform data contained
therein as a list of Strings formatted "nn.sssss" (network.station).

    scan_hdf5(hdf, level="trace")

Scan HDF5 archive `hdf` and return channel names with waveform data contained
therein as a list of Strings formatted "nn.sssss.ll.ccc" (network.station.location.channel).
"""
function scan_hdf5( hdf::String; 
  fmt::String="asdf",
  level::String="station")

  f = h5open(hdf, "r")
  if fmt =="asdf"
    if level == "station"
      str = names(f["Waveforms"])
    elseif level == "trace"
      D = get_datasets(f)
      str = String[]
      for i in D
        push!(str, name(i))
      end
    else
      error("unsupported level!")
    end
  else
    error("unknown format or NYI!")
  end
  close(f)
  unique!(str)
  return str
end
