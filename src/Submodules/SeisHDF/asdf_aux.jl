function mk_netsta(S::GphysData)
  netsta = Array{String,1}(undef, S.n)
  cha = Array{String,1}(undef, S.n)
  for i in 1:S.n
    id = split_id(S.id[i])
    netsta[i] = id[1]*"."*id[2]
    cha[i] = lowercase(id[4]) * "_"
  end
  nsid = unique(netsta)
  return netsta, cha, nsid
end


function asdf_sxml(xbuf::IOBuffer, S::GphysData, chans::Array{Int64,1}, sta::HDF5Group)
  seekstart(xbuf)
  mk_xml!(xbuf, S, chans)
  sta["StationXML"] = take!(xbuf)
  return nothing
end


function asdf_mktrace(S::GphysData, xml_buf::IO, chan_numbers::Array{Int64,1}, wav::HDF5Group, ts::Array{Int64,1}, te::Array{Int64,1}, len::Int64, v::Int64)
  nc = length(chan_numbers)
  netsta, cha, nsid = mk_netsta(S)
  trace_names = Array{Array{String,1},1}(undef, nc)
  (v>2) && println("traces to create = channels ", chan_numbers)

  # Build trace_names
  d0 = zeros(Int64, nc)
  for (i,j) in enumerate(chan_numbers)
    trace_names[i] = String[]
    id = S.id[j]
    cc = cha[j]

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
      asdf_sxml(xml_buf, S, chan_numbers[chans], sta)
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

function asdf_write_chan(S::GphysData, sta::HDF5Group, i::Int64, cha::String, v::Int64)
  fs = S.fs[i]
  tx = S.t[i]
  t = t_win(tx, fs)
  n_seg = size(t,1)
  if n_seg == 0
    @warn(S.id[i] * ": malformed or empty :t field; can't write to file.")
    return
  end

  for k = 1:n_seg
    t0 = t[k,1]
    s0 = string(u2d(div(t0, 1000000)))
    s1 = string(u2d(div(t[k,2], 1000000)))

    si = S.t[i][k,1]
    ei = S.t[i][k+1,1] - (k == n_seg ? 0 : 1)

    # create string like CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_
    chan_str = join([S.id[i], s0, s1, cha], "__")
    if has(sta, chan_str)
      (v > 0) && println("rewriting ", chan_str)
      o_delete(sta, chan_str)
    end
    sta[chan_str] = S.x[i][si:ei]

    # set dictionary attributes
    attrs(sta[chan_str])["sampling_rate"] = fs
    attrs(sta[chan_str])["starttime"] = t0*1000
  end

  return nothing
end
