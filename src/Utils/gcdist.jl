gc_ctr(lat, lon) = (atan(tan(lat*π/180.0)*0.9933056), lon*π/180.0)
gc_unwrap!(t::Array{Float64,1}) = (t[t .< 0] .+= 2.0*π; return t)

"""
(dist, az, baz) = gcdist([lat_src, lon_src], rec)

  Compute great circle distance, azimuth, and backazimuth from source
coordinates [lat_src, lon_src] to receiver coordinates [lat_rec, lon_rec].
*rec* should be a matix with latitudes in column 1, longitudes in column 2.

"""
function gcdist(src::Array{Float64,1}, rec::Array{Float64,2})
  N = size(rec, 1)
  lat_src = repmat([src[1]], N)
  lon_src = repmat([src[2]], N)
  lat_rec = rec[:,1]
  lon_rec = rec[:,2]

  ϕ1, λ1 = gc_ctr(lat_src, lon_src)
  ϕ2, λ2 = gc_ctr(lat_rec, lon_rec)
  Δϕ = ϕ2 - ϕ1
  Δλ = λ2 - λ1

  a = sin(Δϕ/2.0) .* sin(Δϕ/2.0) + cos(ϕ1) .* cos(ϕ2) .* sin(Δλ/2.0) .* sin(Δλ/2.0)
  Δ = 2.0 .* atan2(sqrt(a), sqrt(1.0 - a))
  A = atan2(sin(Δλ).*cos(ϕ2), cos(ϕ1).*sin(ϕ2) - sin(ϕ1).*cos(ϕ2).*cos(Δλ))
  B = atan2(-1.0.*sin(Δλ).*cos(ϕ1), cos(ϕ2).*sin(ϕ1) - sin(ϕ2).*cos(ϕ1).*cos(Δλ))

  # convert to degrees
  return (Δ.*180.0/π, gc_unwrap!(A).*180.0/π, gc_unwrap!(B).*180.0/π )
end
gcdist(lat0::Float64, lon0::Float64, lat1::Float64, lon1::Float64) = (gcdist([lat0, lon0], [lat1 lon1]))
gcdist(src::Array{Float64,2}, rec::Array{Float64,2}) = (gcdist([src[1], src[2]], rec))
gcdist(src::Array{Float64,2}, rec::Array{Float64,1}) = (
  warn("Multiple sources or source coords passed as a matrix; only keeping first coordinate pair!");
  gcdist([src[1,1], src[1,2]], [rec[1] rec[2]]);
  )
