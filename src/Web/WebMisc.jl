# ============================================================================
# Utility functions not for export
webhdr() = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.1.2")
hashfname(str::Array{String,1}, ext::String) = string(hash(str), ".", ext)
# chansplit(C::String) = map(String, split(C,['.','_'],limit=4,keepempty=true))

# Start tracking channel IDs and data lengths
"""
    track_on!(S::SeisData)

Track changes to S.id, changes to channel structure of S, and the sizes of data
vectors in S.x. Does not track data processing operations to any channel i
unless length(S.x[i]) changes for channel i.

**Warning**: If you have or suspect gapped data in any channel, do not use
ungap! while tracking is active.
"""
function track_on!(S::SeisData)
  if S.n > 0
    ids = unique(getfield(S, :id))
    nxs = zeros(Int64, S.n)
    for i = 1:S.n
      nxs[i] = length(S.x[i])
    end
    S.misc[1]["track"] = (ids, nxs)
  end
  return nothing
end

# Stop tracking channel IDs and data lengths; report which have changed
"""
    u = track_off!(S::SeisData)

Turn off tracking in S and return a boolean vector of which channels have
been added or altered significantly.
"""
function track_off!(S::SeisData)
  k = findfirst([haskey(S.misc[i],"track") for i = 1:S.n])
  if S.n == 0
    return nothing
  elseif k == nothing
    return trues(S.n)
  end
  u = falses(S.n)
  (ids, nxs) = S.misc[k]["track"]
  for (n, id) in enumerate(S.id)
    if id in ids == false
      u[n] = true
    else
      j = findfirst(x -> x == id, ids)
      if j == nothing
        u[n] = true
      else
        if nxs[j] != length(S.x[n])
          u[n] = true
        end
      end
    end
  end
  delete!(S.misc[k], "track")
  return u
end

function savereq(D::Array{UInt8,1}, ext::String, net::String, sta::String,
  loc::String, cha::String, s::String, t::String, q::String)
  if ext == "miniseed"
    ext = "mseed"
  elseif ext == "sacbl"
    ext = "SAC"
  end
  ymd = split(s, r"[A-Z]")
  (y, m, d) = split(ymd[1],"-")
  j = md2j(Meta.parse(y), Meta.parse(m), Meta.parse(d))
  i = replace(split(s, 'T')[2],':' => '.')
  if loc == "--"
    loc = ""
  end
  fname = string(join([y, string(j), i, namestrip!(net), namestrip!(sta), namestrip!(loc), namestrip!(cha)],'.'), ".", q, ".", ext)
  if safe_isfile(fname)
    @warn(string("File ", fname, " contains an identical request. Overwriting."))
  end
  f = open(fname, "w")
  write(f, D)
  close(f)
  return nothing
end

"""
| String | Source             |
|:------:|:-------------------|
|BGR    | http://eida.bgr.de |
|EMSC   | http://www.seismicportal.eu |
|ETH    | http://eida.ethz.ch |
|GEONET | http://service.geonet.org.nz |
|GFZ    | http://geofon.gfz-potsdam.de |
|ICGC   | http://ws.icgc.cat |
|INGV   | http://webservices.ingv.it |
|IPGP   | http://eida.ipgp.fr |
|IRIS   | http://service.iris.edu |
|ISC    | http://isc-mirror.iris.washington.edu |
|KOERI  | http://eida.koeri.boun.edu.tr |
|LMU    | http://erde.geophysik.uni-muenchen.de |
|NCEDC  | http://service.ncedc.org |
|NIEP   | http://eida-sc3.infp.ro |
|NOA    | http://eida.gein.noa.gr |
|ORFEUS | http://www.orfeus-eu.org |
|RESIF  | http://ws.resif.fr |
|SCEDC  | http://service.scedc.caltech.edu |
|TEXNET | http://rtserve.beg.utexas.edu |
|USGS   | http://earthquake.usgs.gov |
|USP    | http://sismo.iag.usp.br |
"""
seis_www = Dict("BGR" => "http://eida.bgr.de",
                "EMSC" => "http://www.seismicportal.eu",
                "ETH" => "http://eida.ethz.ch",
                "GEONET" => "http://service.geonet.org.nz",
                "GFZ" => "http://geofon.gfz-potsdam.de",
                "ICGC" => "http://ws.icgc.cat",
                "INGV" => "http://webservices.ingv.it",
                "IPGP" => "http://eida.ipgp.fr",
                "IRIS" => "http://service.iris.edu",
                "ISC" => "http://isc-mirror.iris.washington.edu",
                "KOERI" => "http://eida.koeri.boun.edu.tr",
                "LMU" => "http://erde.geophysik.uni-muenchen.de",
                "NCEDC" => "http://service.ncedc.org",
                "NIEP" => "http://eida-sc3.infp.ro",
                "NOA" => "http://eida.gein.noa.gr",
                "ODC" => "http://www.orfeus-eu.org",
                "ORFEUS" => "http://www.orfeus-eu.org",
                "RESIF" => "http://ws.resif.fr",
                "SCEDC" => "http://service.scedc.caltech.edu",
                "TEXNET" => "http://rtserve.beg.utexas.edu",
                "USGS" => "http://earthquake.usgs.gov",
                "USP" => "http://sismo.iag.usp.br")

fdsn_uhead(src::String) = haskey(seis_www, src) ? seis_www[src] * "/fdsnws/" : src
