# export readuwevt, uwpf, uwpf!
#
"""
    writesac(W::SeisEvent[; ts=false, v=0])

Write all data in SeisEvent structure `W` to auto-generated SAC files. Event
header information is written from W.hdr; W.source is not used as there is no
standard header position for event source information.
"""
function writesac(S::SeisEvent; ts::Bool=false, v::Int64=KW.v)
  tdata = Array{Float32,1}(undef, 0)
  reset_sacbuf()

  evid  = codeunits(S.hdr.id == "" ? "-12345  " : S.hdr.id)
  evid  = evid[1:min(length(evid),16)]
  BUF.sac_cv[9:length(evid)+8] .= evid

  # Values from event header
  S.hdr.loc.lat == 0.0 || setindex!(BUF.sac_fv, Float32(S.hdr.loc.lat), 40)
  S.hdr.loc.lon == 0.0 || setindex!(BUF.sac_fv, Float32(S.hdr.loc.lon), 41)
  S.hdr.loc.dep == 0.0 || setindex!(BUF.sac_fv, Float32(S.hdr.loc.dep), 42)
  S.hdr.mag.val == -5.0f0 || setindex!(BUF.sac_fv, Float32(S.hdr.mag.val), 44)
  BUF.sac_cv[9:length(evid)+8] .= evid
  t_evt = d2u(S.hdr.ot)

  # Ints, always
  BUF.sac_iv[7] = Int32(6)

  for i = 1:S.data.n
    BUF.sac_fv[8] = t_evt - S.data.t[i][1,2]*μs
    write_sac_channel(S.data, i, v, false, "")
  end
  return nothing
end
