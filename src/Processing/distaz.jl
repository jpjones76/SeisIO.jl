export distaz!

"""
    distaz!(Ev::SeisEvent)

Compute Δ, Θ by the Haversine formula. Updates `Ev` with distance, azimuth, and
backazimuth for each channel. Values are stored in
`S.data.misc["dist"], S.data.misc["az"], S.data.misc["baz"]`.

"""
function distaz!(S::SeisEvent)
  rec = Array{Float64, 2}(undef, S.data.n, 2)
  for i = 1:S.data.n
    rec[i,:] = S.data.loc[i][1:2]
  end
  D = gcdist(S.hdr.loc[1:2], rec)
  for i = 1:S.data.n
    S.data.misc[i]["dist"] = D[i,1]
    S.data.misc[i]["az"] = D[i,2]
    S.data.misc[i]["baz"] = D[i,3]
  end
  note!(S.data, "distaz!")
  return nothing
end
