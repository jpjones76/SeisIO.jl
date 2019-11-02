# TO DO:
# As soon as someone sends me a file with waveform traces that have the
# attributes event_id, magnitude_id, focal_mechanism_id, I can trivially
# output SeisEvents. No one has done that yet.

function asdf_rqml(io::HDF5File)
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
    (H,R) = asdf_rqml(fpat::String)

Read QuakeXML (qml) from ASDF file(s) matching file string pattern `fpat`. Returns:
* `H`, Array{SeisHdr,1}
* `R`, Array{SeisSrc,1}

"""
function asdf_rqml(fpat::String)
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

function asdf_wqml!(hdf::HDF5File, HDR::Array{SeisHdr,1}, SRC::Array{SeisSrc,1}; v::Int64=0)
  hq = Int8[]
  io = IOBuffer()
  if has(hdf, "QuakeML")
    hq = read(hdf["QuakeML"])

    # check whether we can append directly
    nq = length(hq)
    si = nq-29
    test_str = String(UInt8.(hq[si:nq]))
    if test_str == "</eventParameters>\n</quakeml>\n"
      # behavior for SeisIO-compatible QuakeML
      deleteat!(hq, si:nq)
      append!(hq, ones(Int8, 4).*Int8(32))
    else
      # behavior for other QuakeML
      qml = parse_string(test_str)
      H0 = Array{SeisHdr,1}()
      R0 = Array{SeisSrc,1}()
      event_xml!(H0, R0, qml)
      free(qml)
      append!(HDR, H0)
      append!(SRC, R0)
      new_qml!(io)
    end
    # delete hdf["QuakeML"]
    o_delete(hdf, "QuakeML")
  else
    new_qml!(io)
  end
  write_qml!(io, HDR, SRC, v)
  buf = vcat(hq, take!(io))
  hdf["QuakeML"] = buf
  close(io)
  return nothing
end

function asdf_wqml(hdf_out::String, HDR::Array{SeisHdr,1}, SRC::Array{SeisSrc,1}; v::Int64=0)
  if isfile(hdf_out)
    hdf = h5open(hdf_out, "r+")
    fmt = read(attrs(hdf)["file_format"])
    (fmt == "ASDF") || (close(hdf); error("invalid ASDF file!"))
  else
    hdf = h5open(hdf_out, "cw")
    attrs(hdf)["file_format"] = "ASDF"
    attrs(hdf)["file_format_version"] = "1.0.2"
  end
  asdf_wqml!(hdf, HDR, SRC, v=v)
  close(hdf)
  return nothing
end
asdf_wqml(hdf_out::String, H::SeisHdr, R::SeisSrc; v::Int64=0) = asdf_wqml(hdf_out, [H], [R], v=v)
