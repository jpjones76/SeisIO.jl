export fill_sac_evh!

"""
    writesac(W::SeisEvent[, v=0])

Write all data in SeisEvent structure `W` to auto-generated SAC files. Event
header information is written from W.hdr; W.source is not used as there is no
standard header position for event source information.
"""
function writesac(S::SeisEvent;
  nvhdr::Integer=6,
  v::Integer=KW.v)

  tdata = Array{Float32, 1}(undef, 0)
  reset_sacbuf()

  ev_id  = codeunits(S.hdr.id == "" ? "-12345  " : S.hdr.id)
  ev_id  = ev_id[1:min(length(ev_id),16)]
  BUF.sac_cv[9:length(ev_id)+8] .= ev_id

  # Values from event header
  if S.hdr.loc.lat != 0.0
    setindex!(BUF.sac_fv, Float32(S.hdr.loc.lat), 36)
    setindex!(BUF.sac_dv, S.hdr.loc.lat, 18)
  end
  if S.hdr.loc.lon != 0.0
    setindex!(BUF.sac_fv, Float32(S.hdr.loc.lon), 37)
    setindex!(BUF.sac_dv, S.hdr.loc.lon, 17)
  end
  S.hdr.loc.dep == 0.0 || setindex!(BUF.sac_fv, Float32(S.hdr.loc.dep), 39)
  S.hdr.mag.val == -5.0f0 || setindex!(BUF.sac_fv, Float32(S.hdr.mag.val), 40)
  BUF.sac_cv[9:length(ev_id)+8] .= ev_id
  t_evt = d2u(S.hdr.ot)

  # Ints
  BUF.sac_iv[7] = Int32(7)
  try
    BUF.sac_iv[9] = parse(Int32, S.hdr.id)
  catch err
    @warn(string("Can't write non-integer event ID ", S.hdr.id, " to SAC."))
  end

  for i = 1:S.data.n
    BUF.sac_fv[8] = Float32(t_evt - S.data.t[i][1,2]*μs)
    BUF.sac_dv[2] = t_evt - S.data.t[i][1,2]*μs
    write_sac_channel(S.data, i, nvhdr, "", v)
  end
  return nothing
end

mk_ot!(Ev::SeisEvent, i::Int, o::T) where T<:AbstractFloat = (Ev.hdr.ot =
  u2d(o + Ev.data.t[i][1,2]*μs))

"""
    fill_sac_evh!(Ev::SeisEvent, fname::String; k=i)

Fill (overwrite) values in `Ev.hdr` with data from SAC file `fname`. Keyword
`k=i` specifies the reference channel `i` from which the absolute origin time
`Ev.hdr.ot` is set. Potentially affects header fields `:id`, `:loc` (subfields
.lat, .lon, .dep), and `:ot`.
"""
function fill_sac_evh!(Ev::SeisEvent, fname::String; k::Int=1)
  reset_sacbuf()
  io = open(fname, "r")
  swap = should_bswap(io)
  fv = BUF.sac_fv
  iv = BUF.sac_iv
  cv = BUF.sac_cv

  # read
  seekstart(io)
  fastread!(io, fv)
  fastread!(io, iv)
  fastread!(io, cv)
  if swap == true
    fv .= bswap.(fv)
    iv .= bswap.(iv)
  end
  sac_v = getindex(iv, 7)
  (iv[9] == sac_nul_i)  || (Ev.hdr.id = string(iv[9]))                # id
  (fv[8] == sac_nul_f)  || (mk_ot!(Ev, k, fv[8]))                     # ot
  (fv[36] == sac_nul_f) || (Ev.hdr.loc.lat = Float64(fv[36]))         # lat
  (fv[37] == sac_nul_f) || (Ev.hdr.loc.lon = Float64(fv[37]))         # lon
  (fv[39] == sac_nul_f) || (Ev.hdr.loc.dep = Float64(fv[39]))         # dep
  (fv[40] == sac_nul_f) || (Ev.hdr.mag.val = fv[40])                  # mag

  if sac_v > 6
    fastskip(io, 4*getindex(iv, 10))
    dv = BUF.sac_dv
    fastread!(io, dv)
    swap && (dv .= bswap.(dv))

    # parse doubles 4 (o), 17 (evlo), 18 (evla)
    (dv[4] == sac_nul_d)  || mk_ot!(Ev, k, dv[4])                     # ot
    (dv[17] == sac_nul_d) || (Ev.hdr.loc.lon = Float64(dv[17]))       # lon
    (dv[18] == sac_nul_d) || (Ev.hdr.loc.lat = Float64(dv[18]))       # lat
  end

  reset_sacbuf()
  close(io)
  return nothing
end
