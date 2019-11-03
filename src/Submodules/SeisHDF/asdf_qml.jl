# TO DO:
# As soon as someone sends me a file with waveform traces that have the
# attributes event_id, magnitude_id, focal_mechanism_id, I can trivially
# output SeisEvents. No one has done that yet.

@doc """
    (H,R) = asdf_rqml(fpat::String)

Read QuakeXML (qml) from ASDF file(s) matching file string pattern `fpat`. Returns:
* `H`, Array{SeisHdr,1}
* `R`, Array{SeisSrc,1}

""" asdf_rqml
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
    close(io)
  end
  return(EvCat, EvSrc)
end

function asdf_wqml!(hdf::HDF5File, HDR::Array{SeisHdr,1}, SRC::Array{SeisSrc,1},
  ovr::Bool, v::Int64)
  hq = Int8[]
  io = IOBuffer()
  H0 = SeisHdr[]
  R0 = SeisSrc[]
  if has(hdf, "QuakeML")
    if ovr
      (v > 0) && println("ovewriting QuakeML...")
      new_qml!(io)
    else
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
        qml = parse_string(String(UInt8.(hq)))
        event_xml!(H0, R0, qml)
        free(qml)
        new_qml!(io)
        hq = Int8[]
        GC.gc()
      end
    end

    # delete hdf["QuakeML"]. I fear one can't resize HDF5 arrays in-place.
    # One certainly can't in the Julia HDF5 interface...
    o_delete(hdf, "QuakeML")
  else
    new_qml!(io)
  end
  if isempty(H0) && isempty(R0)
    write_qml!(io, HDR, SRC, v)
  else
    append!(H0, HDR)
    append!(R0, SRC)
    write_qml!(io, H0, R0, v)
  end
  buf = vcat(hq, take!(io))
  hdf["QuakeML"] = buf
  close(io)
  return nothing
end

@doc """
    asdf_wqml(fname, SHDR::Array{SeisHdr,1}, SSRC::Array{SeisSrc,1}[, KWs])
    asdf_wqml(fname, H::SeisHdr, R::SeisSrc[, KWs])

Write QuakeXML (qml) to "QuakeML/" dataset in ASDF file `fname` from `SHDR` and
`SSRC`.

    asdf_wqml(fname, evt::SeisEvent[, KWs])
    asdf_wqml(fname, evt::Array{SeisEvent,1}[, KWs])

As above, for the `:hdr` and `:source` fields of `evt`.

|KW     | Type      | Default   | Meaning                                     |
|:---   |:---       |:---       |:---                                         |
| ovr   | Bool      | false     | overwrite QML in existing ASDF file? [^1]   |
| v     | Int64     | 0         | verbosity                                   |

[^1] By default, data are appended to the existing contents of "QuakeML/".

!!! warning

    To write data from `R ∈ SSRC`, it must be true that `R.eid == H.id` for some `H ∈ SHDR`.

See also: write_qml
""" asdf_wqml
function asdf_wqml(hdf_out::String, HDR::Array{SeisHdr,1}, SRC::Array{SeisSrc,1};
  ovr::Bool=false,
  v::Int64=0)
  if isfile(hdf_out)
    hdf = h5open(hdf_out, "r+")
    fmt = read(attrs(hdf)["file_format"])
    (fmt == "ASDF") || (close(hdf); error("invalid ASDF file!"))
  else
    hdf = h5open(hdf_out, "cw")
    attrs(hdf)["file_format"] = "ASDF"
    attrs(hdf)["file_format_version"] = "1.0.2"
  end
  asdf_wqml!(hdf, HDR, SRC, ovr, v)
  close(hdf)
  return nothing
end
asdf_wqml(hdf_out::String, H::SeisHdr, R::SeisSrc; ovr::Bool=false, v::Int64=0) = asdf_wqml(hdf_out, [H], [R], ovr=ovr, v=v)
asdf_wqml(hdf_out::String, W::SeisEvent; ovr::Bool=false, v::Int64=0) = asdf_wqml(hdf_out, [W.hdr], [W.source], ovr=ovr, v=v)

function asdf_wqml(hdf_out::String, events::Array{SeisEvent,1};
  ovr::Bool=false,
  v::Int64=0)

  N = length(events)
  H = Array{SeisHdr, 1}(undef, N)
  R = Array{SeisSrc, 1}(undef, N)
  for i in 1:N
    H[i] = events[i].hdr
    R[i] = events[i].source
  end
  asdf_wqml(hdf_out, H, R, ovr=ovr, v=v)
  return nothing
end
