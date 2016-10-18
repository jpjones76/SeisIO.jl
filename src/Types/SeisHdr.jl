import Base:summary, isequal

"""
    S = SeisHdr()

Create a seismic header. Fields can be initialized by name at creation. For example:

    S = SeisHdr(cat="NEIC", mag=3.3)

Create a seismic header with S.cat="NEIC" and S.mag=3.3. Unspecified fields are set to system defaults.
"""
type SeisHdr
  id::Int64
  time::DateTime
  lat::Float64
  lon::Float64
  dep::Float64
  mag::Float32
  mag_typ::String
  mag_auth::String
  auth::String
  cat::String
  contrib::String
  contrib_id::Int64
  loc_name::String

  # Very ill-defined behavior seems to follow from the use of keywords .type or .*_type

  SeisHdr(; id=0::Int64,
            time=now()::DateTime,
            lat=0.0::Float64,
            lon=0.0::Float64,
            dep=0.0::Float64,
            mag=(-5.0f0)::Float32,
            mag_typ="No mag"::String,
            mag_auth=""::String,
            auth="None"::String,
            cat="None"::String,
            contrib=""::String,
            contrib_id=0::Int64,
            loc_name="Annywn, beneath the waves"::String) = begin
     return new(id, time, lat, lon, dep, mag, mag_typ, mag_auth, auth,
              cat, contrib, contrib_id, loc_name)
  end
end

# =============================================================================
# Equality
isequal(S::SeisHdr, T::SeisHdr) = minimum([isequal(hash(getfield(S,v)), hash(getfield(T,v))) for v in fieldnames(S)])
==(S::SeisHdr, T::SeisHdr) = isequal(S,T)
