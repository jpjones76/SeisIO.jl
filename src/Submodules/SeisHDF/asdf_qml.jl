# TO DO:
# As soon as someone sends me a file with waveform traces that have the
# attributes event_id, magnitude_id, focal_mechanism_id, I can trivially
# output SeisEvents. No one has done that yet.

function asdf_qml(io::HDF5File)
  EvCat = Array{SeisHdr,1}()
  EvSrc = Array{SeisSrc,1}()

  if has(io, "QuakeML")
    qml = parse_string(String(UInt8.(read(io["QuakeML"]))))
    event_xml!(EvCat, EvSrc, qml)
    free(qml)
  end
  return EvCat, EvSrc
end

"""
    (H,R) = asdf_qml(fpat::String)

Read QuakeXML (qml) from ASDF file(s) matching file string pattern `fpat`. Returns:
* `H`, Array{SeisHdr,1}
* `R`, Array{SeisSrc,1}

"""
function asdf_qml(fpat::String)
  files = safe_isfile(fpat) ? [fpat] : ls(fpat)
  EvCat = Array{SeisHdr,1}()
  EvSrc = Array{SeisSrc,1}()
  for file in files
    io = h5open(file, "r")
    if has(io, "QuakeML")
      qml = parse_string(String(UInt8.(read(io["QuakeML"]))))
      event_xml!(EvCat, EvSrc, qml)
      free(qml)
    end
  end
  return(EvCat, EvSrc)
end
