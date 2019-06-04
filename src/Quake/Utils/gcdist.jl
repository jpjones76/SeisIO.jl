gc_ctr(lat::Array{Float64,1}, lon::Array{Float64,1}) =  (atan.(tan.(deg2rad.(lat)).*0.9933056), deg2rad.(lon))
gc_unwrap!(t::Array{Float64,1}) = (t[t .< 0] .+= (2.0*Float64(π)); return t)

@doc """
    G = gcdist(src, rec)

  Compute great circle distance, azimuth, and backazimuth from single source `s`
with coordinates `[s_lat, s_lon]` to receivers `r` with coordinates `[r_lat r_lon].`

  For a single source, pass `src` as a Float64 vector of the form `[s_lat, s_lon]`;
gcdist will return an Array{Float64,2} of the form

    [Δ₁   θ₁   β₁
     Δ₂   θ₂   β₂
     ⋮    ⋮    ⋮
     Δn   θn   βn]

for receivers `1:n`.

  For multiple sources, pass `src` as an Array{Float64,2} with each row
containing one (lat, lon) pair. This returns a three-dimensional matrix where
each two-dimensional slice takes the form

      [Δᵢ₁   θᵢ₁   βᵢ₁
       ⋮     ⋮     ⋮
       Δᵢn   θᵢn   βᵢn]

for source `i` at receivers `1:n`.
""" gcdist
function gcdist(src::Array{Float64,1}, rec::Array{Float64,2})
  N = size(rec, 1)
  lat_src = repeat([src[1]], N)
  lon_src = repeat([src[2]], N)
  lat_rec = rec[:,1]
  lon_rec = rec[:,2]

  ϕ1, λ1 = gc_ctr(lat_src, lon_src)
  ϕ2, λ2 = gc_ctr(lat_rec, lon_rec)
  Δϕ = ϕ2 - ϕ1
  Δλ = λ2 - λ1

  a = sin.(Δϕ/2.0) .* sin.(Δϕ/2.0) + cos.(ϕ1) .* cos.(ϕ2) .* sin.(Δλ/2.0) .* sin.(Δλ/2.0)
  Δ = 2.0 .* atan.(sqrt.(a), sqrt.(1.0 .- a))
  A = atan.(sin.(Δλ).*cos.(ϕ2), cos.(ϕ1).*sin.(ϕ2) - sin.(ϕ1).*cos.(ϕ2).*cos.(Δλ))
  B = atan.(-1.0.*sin.(Δλ).*cos.(ϕ1), cos.(ϕ2).*sin.(ϕ1) - sin.(ϕ2).*cos.(ϕ1).*cos.(Δλ))

  # convert to degrees
  return rad2deg.(hcat(Δ, gc_unwrap!(A), gc_unwrap!(B)))
end
gcdist(lat0::Float64, lon0::Float64, rec::Array{Float64,2}) = gcdist([lat0, lon0], rec)
gcdist(lat0::Float64, lon0::Float64, lat1::Float64, lon1::Float64) = gcdist([lat0, lon0], [lat1 lon1])

function gcdist(src::Array{Float64,2}, rec::Array{Float64,2})
  N_src = size(src,1)
  N_rec = size(rec,1)
  G = Array{Float64,3}(undef, N_rec, 3, N_src)
  for i = 1:N_src
    G[:,:,i] = gcdist(src[i,:], rec)
  end
  return G
end
gcdist(src::Array{Float64,2}, rec::Array{Float64,1}) = gcdist(src, [rec[1] rec[2]])
