"""
    distaz!(S::SeisEvent)

Compute Δ, Θ by the Haversine formula. Updates `S` with distance, azimuth, and backazimuth for each channel. Values are stored as `S.data.misc["dist"], S.data.misc["az"], S.data.misc["baz"]`.

"""
function distaz!(S::SeisEvent)
  rec = Array{Float64, 2}(undef, S.data.n, 2)
  for i = 1:S.data.n
    rec[i,:] = S.data.loc[i][1:2]
  end
  (dist, az, baz) = gcdist(S.hdr.loc[1:2], rec)
  for i = 1:S.data.n
    S.data.misc[i]["dist"] = dist[i]
    S.data.misc[i]["az"] = az[i]
    S.data.misc[i]["baz"] = baz[i]
  end
end
