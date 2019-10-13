function write_asdf( hdf_out::String,
                     S::GphysData )

  # Open file, set top-level attributes
  io = h5open(hdf_out, "w")
  attrs(io)["file_format"] = "ASDF"
  attrs(io)["file_format_version"] = "1.0.2"

  # Create group "Waveforms"
  wav = g_create(io, "Waveforms")

  # Buffer for StationXML
  xml_buf = IOBuffer()

  netsta = Array{String,1}(undef, S.n)
  cha = Array{String,1}(undef, S.n)
  for i in 1:S.n
    id = split_id(S.id[i])
    netsta[i] = id[1]*"."*id[2]
    cha[i] = lowercase(id[4]) * "_"
  end
  nsid = unique(netsta)

  # write channels to net.sta waveform groups
  for j in 1:length(nsid)
    seekstart(xml_buf)
    id = nsid[j]
    chans = findall(netsta .== id)

    # Create Waveforms/net.sta
    sta = g_create(wav, id)

    # dump StationXML here
    mk_xml!(xml_buf, S, chans=chans)
    sta["StationXML"] = take!(xml_buf)

    for i in chans
      fs = S.fs[i]
      t = S.t[i]
      t0 = t[1,2]
      s0 = string(u2d(div(t0, 1000000)))
      s1 = string(u2d(div(endtime(t, fs), 1000000)))

      # create string like CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_
      chan_str = join([S.id[i], s0, s1, cha[i]], "__")

      # set dictionary attributes
      sta[chan_str] = S.x[i]
      attrs(sta[chan_str])["sampling_rate"] = fs
      attrs(sta[chan_str])["starttime"] = t0*1000
    end
  end
  close(xml_buf)
  close(io)
  return nothing
end
