# randSeisEvent_well-behaved
function rse_wb(n::Int64)
  Ev = randSeisEvent(n, s=1.0)

  # Prevent problematic :source fields
  Ev.source.eid   = Ev.hdr.id
  Ev.source.npol  = 0
  Ev.source.notes = String[]
  Ev.source.misc  = Dict{String,Any}(
        "pax_desc"    => "azimuth, plunge, length",
        "mt_id"       => "smi:SeisIO/moment_tensor;fmid="*Ev.source.id,
        "planes_desc" => "strike, dip, rake")
  note!(Ev.source, "+origin ¦ " * Ev.source.src)

  # Prevent read/write of problematic :hdr fields
  Ev.hdr.int        = (0x00, "")
  Ev.hdr.loc.datum  = ""
  Ev.hdr.loc.typ    = ""
  Ev.hdr.loc.rms    = 0.0
  Ev.hdr.mag.src    = Ev.hdr.loc.src * ","
  Ev.hdr.notes      = String[]
  Ev.hdr.misc       = Dict{String,Any}()
  note!(Ev.hdr, "+origin ¦ " * Ev.hdr.src)

  # Ensure flags will re-read accurately
  flags = bitstring(Ev.hdr.loc.flags)
  if flags[1] == '1' || flags[2] == '1'
    flags             = "11" * flags[3:8]
    Ev.hdr.loc.flags  = parse(UInt8, flags, base=2)
  end

  # Prevent very low fs, bad locations, rubbish in :misc, :notes
  for j in 1:Ev.data.n
    Ev.data.fs[j]     = max(Ev.data.fs[j], 1.0)
    Ev.data.misc[j]   = Dict{String,Any}()
    Ev.data.notes[j]  = String[]
    Ev.data.loc[j]    = RandSeis.rand_loc(false)

    # Use time structures that formerly broke check_for_gap! / t_extend
    if j < 3
      Ev.data.t[j] = breaking_tstruct(Ev.data.t[j][1,2],
                                      length(Ev.data.x[j]),
                                      Ev.data.fs[j])
    end
  end
  return Ev
end
