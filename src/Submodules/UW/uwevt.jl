@doc """
    Ev = readuwevt(fpat)

Read UW-format event data with file pattern stub `fpat` into SeisEvent `Ev`. `fstub` can be a datafile name, a pickfile name, or a stub:
* A datafile name must end in 'W'
* A pickfile name must end in a lowercase letter (a-z except w) and should describe a single event.
* A filename stub must be complete except for the last letter, e.g. "99062109485".
* Wild cards for multi-file read are not supported by `readuw` because the data format is strictly event-oriented.
""" readuwevt
function readuwevt(filename::String; v::Int64=KW.v, full::Bool=false)

  df = String("")
  pf = String("")

  # Identify pickfile and datafile
  if Sys.iswindows() == false
    filename = relpath(filename)
  end
  ec = UInt8(filename[end])
  lc = vcat(collect(UInt8, 0x61:0x76), 0x78, 0x79, 0x7a) # skip 'w'
  if Base.in(ec, lc)
    pf = filename
    df = filename[1:end-1]*"W"
  else
    if ec == 0x57
      df = filename
      pfstub = filename[1:end-1]
    else
      df = filename*"W"
      safe_isfile(df) || error("Invalid filename stub (no corresponding data file)!")
      pfstub = filename
    end
    pf = pfstub * "\0"
    for i in lc
      pf = string(pfstub, Char(i))
      if safe_isfile(pf)
        break
      end
    end
  end

  # Datafile + pickfile read wrappers
  if safe_isfile(df)

    # Datafile read wrapper
    v>0 && println(stdout, "Reading datafile ", df)

    W = SeisEvent()
    setfield!(W, :data, unsafe_convert(EventTraceData, uwdf(df, v=v, full=true)))

    v>0 && println(stdout, "Done reading data file.")

    # Pickfile read wrapper
    if safe_isfile(pf)
      v>0 && println(stdout, "Reading pickfile ", pf)

      uwpf!(W, pf, v=v)

      v>0 && println(stdout, "Done reading pick file.")

      # Move event keys to event header dict
      hdr = getfield(W, :hdr)
      data = getfield(W, :data)

      klist = ("extra", "flags", "mast_event_no", "mast_fs", "mast_lmin", "mast_lsec", "mast_nx", "mast_tape_no")
      D_data = getindex(getfield(data, :misc), 1)
      D_hdr = getfield(hdr, :misc)
      for k in klist
        D_hdr[k] = D_data[k]
        delete!(D_data, k)
      end
      D_hdr["comment_df"] = D_data["comment"]
      delete!(D_data, "comment")

      # Convert all phase arrival times to travel times
      δt = 1.0e-6*(rem(hdr.ot.instant.periods.value*1000 - dtconst, 60000000))
      for i = 1:data.n
        D = getindex(getfield(data, :pha), i)
        for p in keys(D)
          pha = get(D, p, SeisPha())
          tt = getfield(pha, :tt) - δt
          if tt < 0.0
            tt = mod(tt, 60)
          end
          setfield!(pha, :tt, tt)
        end
      end
      #= Note: use of "mod" above corrects for the (annoyingly frequent) case
      where file begin time and origin time have a different minute value.
      =#

    else
      v>0 && println(stdout, "Skipping pickfile (not found or not given)")
    end

  # Pickfile only
  else
    (hdr, source) = uwpf(pf, v=v)
    W = SeisEvent(hdr = hdr, source = source)
  end

  return W
end
