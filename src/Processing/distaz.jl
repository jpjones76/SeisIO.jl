export distaz!

"""
    distaz!(Ev::SeisEvent)

Compute Δ, Θ by the Haversine formula. Updates `Ev` with distance, azimuth, and
backazimuth for each channel. Values are stored in
`S.data.misc["dist"], S.data.misc["az"], S.data.misc["baz"]`.

"""
function distaz!(S::SeisEvent)
  TD = getfield(S, :data)
  ChanLoc = getfield(TD, :loc)
  SrcLoc = getfield(getfield(S, :hdr), :loc)
  N = getfield(TD, :n)
  rec = Array{Float64, 2}(undef, N, 2)
  for i = 1:N
    loc = getindex(ChanLoc, i)
    if typeof(loc) == GeoLoc
      rec[i,:] = [loc.lat loc.lon]
    else
      error(string(":loc for channel ", i, " is not a GeoLoc!"))
    end
  end
  D = gcdist(SrcLoc.lat, SrcLoc.lon, rec)
  @assert size(D,1) == N
  TD.dist = D[:,1]
  TD.az   = D[:,2]
  TD.baz  = D[:,3]
  note!(TD, "distaz!")
  return nothing
end
