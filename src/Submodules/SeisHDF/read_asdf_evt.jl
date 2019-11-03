function get_evt_range!(filestr::String, idr::Regex, t::Array{Int64,1})
  f = h5open(filestr, "r")
  D = get_datasets(f)
  for i in D
    has(i, "event_id") || continue
    evid = read(i["event_id"])
    if occursin(idr, evid)
      t0 = read(i["starttime"])
      fs = read(i["sampling_rate"])
      nx = length(i)

      # convert fs to sampling interval in ns
      Δ = round(Int64, 1.0e9/fs)
      t1 = t0 + (nx-1)*Δ

      t[1] = min(t[1], t0-Δ)
      t[2] = max(t[2], t1+Δ)
    end
  end
  close(f)
  return nothing
end

@doc """
    EventCat = read_asdf_evt(filestr, event_id::Union{String, Regex}[, KWs])

Read data in seismic HDF5 format with ids matching `event_id` from files
matching pattern `filestr`. Returns an array of SeisEvent structures.

    EventCat = read_asdf_evt(filestr, [, KWs])

Read data in seismic HDF5 format from files matching pattern `filestr` into
SeisEvent structures. Matches any event ID in any matching file.

|KW         | Type    | Default | Meaning                                     |
|:---       |:---     |:---     |:---                                         |
| msr       | Bool    | true    | read full (MultiStageResp) instrument resp? |
| v         | Int64   | 0       | verbosity                                   |

See also: timespec, parsetimewin, read_data, read_hdf5
""" read_asdf_evt
function read_asdf_evt(filestr::String, event_id::Union{String, Regex};
  msr       ::Bool                  = true,                   # read multistage response?
  v         ::Int64                 = KW.v                    # verbosity
  )

  one_file = safe_isfile(filestr)
  S = SeisData()

  # Regex ID
  idr = isa(event_id, String) ? id_to_regex(event_id) : id

  # Time range to read
  t = zeros(Int64, 2)
  t[1] = typemax(Int64)
  t[2] = typemin(Int64)
  if one_file

    # Time range
    get_evt_range!(filestr, idr, t)
    t_start = string(u2d(t[1]*1.0e-9))
    t_end = string(u2d(t[2]*1.0e-9))
    (v > 0) && println("read range: ", t_start, " -- ", t_end)

    # Read data
    append!(S, read_asdf(filestr, "*", t_start, t_end, msr, v))
  else
    files = ls(filestr)

    # Time range
    for fname in files
      get_evt_range!(fname, idr, t)
    end
    t_start = string(u2d(t[1]*1.0e-9))
    t_end = string(u2d(t[2]*1.0e-9))
    (v > 0) && println("read range: ", t_start, " -- ", t_end)

    # Read data
    for fname in files
      (v > 0) && println("reading from ", fname)
      append!(S, read_asdf(fname, "*", t_start, t_end, msr, v))
    end
  end

  # List of event IDs for each channel
  ns = S.n
  sid = Array{String,1}(undef, ns)
  for i in 1:ns
    sid[i] = get(S.misc[i], "event_id", "")
  end

  (H,R) = asdf_rqml(filestr)

  # List of event IDs for each SeisHdr
  nh = length(H)
  hid = Array{String,1}(undef, nh)
  inds = Int64[]
  sizehint!(inds, nh)
  fill!(hid, "")
  for i in 1:nh
    evid = H[i].id
    hid[i] = evid
    if occursin(event_id, evid)
      push!(inds, i)
    end
  end

  # Form event catalog by matching IDs
  EC = Array{SeisEvent,1}(undef, length(inds))
  for (k,j) in enumerate(inds)
    chans = Int64[]
    for i in 1:S.n
      if sid[i] == hid[j]
        push!(chans, i)
      end
    end
    EC[k] = SeisEvent(hdr = H[j], source = R[j], data = S[chans])
  end
  return EC
end

read_asdf_evt(filestr::String;
  msr       ::Bool                  = true,                   # read multistage response?
  v         ::Int64                 = KW.v                    # verbosity
  ) = read_asdf_evt(filestr, "", msr=msr, v=v)
