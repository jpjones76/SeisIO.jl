function mk_netsta(S::GphysData)
  netsta = Array{String,1}(undef, S.n)
  cha = Array{String,1}(undef, S.n)
  for i in 1:S.n
    id = split_id(S.id[i])
    netsta[i] = id[1]*"."*id[2]
    cha[i] = lowercase(id[4])
  end
  nsid = unique(netsta)
  return netsta, cha, nsid
end

function asdf_wsxml(xbuf::IOBuffer, S::GphysData, chans::Array{Int64,1}, sta::HDF5Group)
  seekstart(xbuf)
  mk_xml!(xbuf, S, chans)
  sta["StationXML"] = take!(xbuf)
  return nothing
end

function asdf_mktrace(S::GphysData, xml_buf::IO, chan_numbers::Array{Int64,1}, wav::HDF5Group, ts::Array{Int64,1}, te::Array{Int64,1}, len::Int64, v::Integer, tag::String)
  nc = length(chan_numbers)
  netsta, cha, nsid = mk_netsta(S)
  trace_names = Array{Array{String,1},1}(undef, nc)
  (v>2) && println("traces to create = channels ", chan_numbers)

  # Build trace_names
  d0 = zeros(Int64, nc)
  for (i,j) in enumerate(chan_numbers)
    trace_names[i] = String[]
    id = S.id[j]
    cc = isempty(tag) ? cha[j] : tag

    # divide t0 and t1 by the time length using div to get d0, d1
    d0[i] = len*(div(ts[i], len))
    d1 = len*(div(te[i], len))
    Δ = round(Int64, 1.0e9/S.fs[j])

    # range of times is then d0:d1
    for d in d0[i]:len:d1
      # ...but we must end Δ ns *before* d1 to prevent a one-sample overlap
      s0 = string(u2d(d/1000000000))
      s1 = string(u2d((d+len-Δ)/1000000000))

      # create string like CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_
      chan_str = join([id, s0, s1, cc], "__")
      push!(trace_names[i], chan_str)
    end
    (v > 2) && println("trace_names[", i, "] = ", trace_names[i])
  end

  # Check for trace names in each ns
  chans = falses(nc)
  for j in 1:length(nsid)
    id = nsid[j]
    fill!(chans, false)
    for (j,i) in enumerate(chan_numbers)
      if (netsta[i] == id) && (S.fs[i] != 0.0)
        chans[j] = true
      end
    end
    (maximum(chans) == false) && continue

    # does net.sta exist?
    if has(wav, id)
      sta = wav[id]

    else
      # Create Waveforms/net.sta
      (v > 0) && println("creating Waveforms/", id)
      sta = g_create(wav, id)

      # Write StationXML to sta
      asdf_wsxml(xml_buf, S, chan_numbers[chans], sta)
    end

    # Create Waveforms/net.sta/chan_str
    for i = 1:length(chans)
      if chans[i]
        j = chan_numbers[i]
        (v > 2) && println("S.id[", j, "] = ", S.id[j], ", trace_names[", i, "] = ", trace_names[i])
        T = eltype(S.x[j])
        fs = S.fs[j]
        Δ = round(Int64, 1.0e9/fs)
        nx = div(len, Δ)
        for k = 1:length(trace_names[i])
          chan_str = trace_names[i][k]

          # is there a trace with the corresponding string?
          if has(sta, chan_str) == false
            (v > 1) && println("creating trace:  Waveforms/", id, "/", chan_str)
            sta[chan_str] = ones(T, nx).*T(NaN)

            # create a trace of all NaNs
            attrs(sta[chan_str])["sampling_rate"] = fs
            attrs(sta[chan_str])["starttime"] = d0[i] + (k-1)*len
          end
        end
      end
    end
  end

  return nothing
end

function asdf_write_chan(S::GphysData, sta::HDF5Group, i::Int64, tag::String, eid::String, v::Integer)
  fs = S.fs[i]
  tx = S.t[i]
  t = t_win(tx, fs)
  xi = x_inds(tx)
  n_seg = size(t, 1)
  (n_seg == 0) && return

    for k = 1:n_seg
    t0 = t[k,1]
    t1 = t[k,2]
    s0 = string(u2d(div(t0, 1000000)))
    s1 = string(u2d(div(t1, 1000000)))

    # create string like CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_
    chan_str = join([S.id[i], s0, s1, tag], "__")
    if has(sta, chan_str)
      (v > 0) && println("incrementing tag of ", chan_str)
      j = 0x2f
      while has(sta, chan_str)
        j += 0x01
        tag1 = String(vcat(UInt8.(codeunits(tag)), j))
        chan_str = join([S.id[i], s0, s1, tag1], "__")
      end
    end
    sta[chan_str] = S.x[i][xi[k,1]:xi[k,2]]

    # set dictionary attributes
    D = attrs(sta[chan_str])
    D["sampling_rate"] = fs
    D["starttime"] = t0*1000

    if !isempty(eid)
      D["event_id"] = eid
    end
  end

  return nothing
end

function write_asdf( hdf_out::String,
                     S::GphysData,
                     chan_numbers::Array{Int64,1},
                     add::Bool,
                     evid::String,
                     ovr::Bool,
                     len::Period,
                     tag::String,
                     v::Integer)

  # "add" implies "ovr"
  if add == true
    ovr = true
  end

  # Precheck for degenerate time structs, time shift
  if ovr
    for i in chan_numbers
      if (size(S.t[i],1) < 2) && (S.fs[i] != 0.0)
        error(string(S.id[i] *
          ": malformed :t; can't write with ovr=true."))
      end

      # ensure each channel starts on an exact sample
      t0 = S.t[i][1,2]
      Δ = round(Int64, sμ/S.fs[i])
      t1 = div(t0,Δ)*Δ
      δ = t0-t1
      S.t[i][1,2] = t1
      S.misc[i]["tc"] = δ
    end
  end

  xml_buf = IOBuffer()
  netsta, cha, nsid = mk_netsta(S)

  if isfile(hdf_out)
    io = h5open(hdf_out, "r+")
    fmt = read(attrs(io)["file_format"])
    (fmt == "ASDF") || (close(io); error("invalid ASDF file!"))
    if has(io, "Waveforms")
      wav = io["Waveforms"]
    else
      wav = g_create(io, "Waveforms")
    end
  else
    io = h5open(hdf_out, "cw")
    attrs(io)["file_format"] = "ASDF"
    attrs(io)["file_format_version"] = "1.0.2"
    wav = g_create(io, "Waveforms")
  end

  # =======================================================================
  # Add "empty" traces of all NaNs
  if add
    nc = length(chan_numbers)
    ts = zeros(Int64, nc)
    te = zeros(Int64, nc)
    for (i,j) in enumerate(chan_numbers)
      ts[i] = S.t[j][1,2]*1000
      te[i] = endtime(S.t[j], S.fs[j])*1000
    end
    p = convert(Nanosecond, len).value
    asdf_mktrace(S, xml_buf, chan_numbers, wav, ts, te, p, v, tag)
  end

  # write channels to net.sta waveform groups
  for j in 1:length(nsid)
    (v > 0) && println("writing ", nsid)
    id = nsid[j]
    chans = Int64[]
    for i in chan_numbers
      if (netsta[i] == id) && (S.fs[i] != 0.0)
        push!(chans, i)
      end
    end
    nc = length(chans)

    # does net.sta exist?
    if has(wav, id)
      sta = wav[id]

      if ovr
        # ====================================================================
        # overwrite StationXML
        (v > 1) && println("merging XML")

        # read old XML
        SX = SeisData()
        sxml = String(UInt8.(read(sta["StationXML"])))
        read_station_xml!(SX, sxml, "0001-01-01T00:00:00", "9999-12-31T23:59:59", true, v)

        # merge S headers into SX, overwriting SX
        SM = SeisData(length(chan_numbers))
        for f in (:id, :name, :loc, :fs, :gain, :resp, :units)
          setfield!(SM, f, deepcopy(getindex(getfield(S, f), chan_numbers)))
        end
        sxml_mergehdr!(SX, SM, false, true, v)

        # remake channel list; SX ordering differs from S
        cc = Int64[]
        for i in 1:SX.n
          idx = split_id(SX.id[i])
          ns = idx[1]*"."*idx[2]
          if ns == id
            push!(cc, i)
          end
        end
        o_delete(sta, "StationXML")
        asdf_wsxml(xml_buf, SX, cc, sta)

        # ==================================================================
        # overwrite trace data
        trace_ids = S.id[chans]
        t = Array{Array{Int64,2},1}(undef,nc)
        for (i,j) in enumerate(chans)
          t[i] = t_win(S.t[j], S.fs[j])
          broadcast!(*, t[i], t[i], 1000)
        end
        (v > 2) && println("t = ", t)

        # loop over trace waveforms using id, start time, end time
        for n in names(sta)
          (n == "StationXML") && continue
          cha_id = String(split(n, "_", limit=2, keepempty=true)[1])
          x = sta[n]
          (v > 1) && println("checking ", n)
          nx = length(x)
          t0 = read(x["starttime"])
          fs = read(x["sampling_rate"])
          (v > 2) && println("t0 = ", t0, "; fs = ", fs, "; nx = ", nx)

          # convert fs to sampling interval in ns
          Δ = round(Int64, 1.0e9/fs)
          t1 = t0 + (nx-1)*Δ

          for i in 1:length(chans)
            (trace_ids[i] == cha_id) || continue
            nk = size(t[i], 1)

            for k in 1:nk
              (v > 2) && println("segment k = ", k, "/", nk)
              # overlap
              ts = t[i][k,1]
              te = t[i][k,2]
              if (ts ≤ t1) && (te ≥ t0)
                # set channel index j in S
                j = chans[i]
                (v > 2) && println("j = ", j)

                # check for fs mismatch
                trace_fs = S.fs[j]
                (trace_fs == fs) || (@warn(string("Can't write ", S.id[j], "; fs mismatch!")); continue)
                lx = div(te-ts, Δ)+1

                # determine start, end indices in x that are overwritten
                (v > 2) && println("ts = ", ts, "; te = ", te, "; t0 = ", t0, "; t1 = ", t1, "; nx = ", nx, "; lx = ", lx)
                i0, i1, t2 = get_trace_bounds(ts, te, t0, t1, Δ, nx)

                # determine start, end indices in X to copy
                si = get_trace_bound(t0, ts, Δ, lx)
                ei = si + min(i1-i0, lx-1)

                # overwrite
                if v > 2
                  println("writing ", si, ":", ei, " to ", i0, ":", i1)
                end
                save_data!(S.x[j], x, i0:i1, si:ei)
              end
            end
          end

        end
      else
        for i in chans
          asdf_write_chan(S, sta, i, cha[i], evid, v)
        end
      end

    elseif ovr == false
      # Create Waveforms/net.sta
      sta = g_create(wav, id)

      # Create Waveforms/net.sta/chan_str
      for i in chans
        asdf_write_chan(S, sta, i, isempty(tag) ? cha[i] : tag, evid, v)
      end

      # Write StationXML to sta
      asdf_wsxml(xml_buf, S, chans, sta)
    end
  end

  close(xml_buf)
  close(io)

  # Correct :t
  if ovr
    for i in chan_numbers
      δ = get(S.misc[i], "tc", 0)
      t0 = S.t[i][1,2]
      S.t[i][1,2] = t0+δ
      delete!(S.misc[i], "tc")
    end
  end
  return nothing
end
