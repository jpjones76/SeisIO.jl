export chanspec, seis_www, track_on!, track_off!

# Generic handler for getting data by HTTP
# Returns:
#   R::Array{UInt8,1}, either request body or error data
#   parsable::Bool, whether or not R is parsable
function get_http_req(url::String, req_info_str::String, to::Int; status_exception::Bool=false)
  (R::Array{UInt8,1}, parsable::Bool) = try
    req = request(  "GET", url, webhdr,
                    readtimeout = to,
                    status_exception = status_exception  )
    if req.status == 200
      (req.body, true)

    else
      @warn(string("Request failed", req_info_str,
      "\nRESPONSE = ", req.status, " (", statustext(req.status), ")",
      "\n\nHTTP response is in misc[\"data\"]"))
      (Array{UInt8,1}(string(req)), false)
    end

  catch err
    T = typeof(err)
    @warn(  string( "Error thrown", req_info_str,
                    "\n\nERROR = ", T,
                    "\n\nTrying to store error message in misc[\"data\"]"
                    )
          )
    msg_data::Array{UInt8,1} = Array{UInt8,1}( try; string(getfield(err, :response)); catch; try; string(getfield(err, :msg));  catch; ""; end; end )
    (msg_data, false)
  end

  return R, parsable
end

function get_http_post(url::String, body::String, to::Int; status_exception::Bool=false)
  try
    req = request(  "POST", url, webhdr, body,
                    readtimeout = to,
                    status_exception = status_exception)
    if req.status == 200
      return (req.body, true)
    else
      @warn(string( "Request failed!\nURL: ", url, "\nPOST BODY: \n", body, "\n",
                    "RESPONSE: ", req.status, " (", statustext(req.status), ")\n" ) )
      return (Array{UInt8,1}(string(req)), false)
    end

  catch err
    @warn(string( "Error thrown:\nURL: ", url, "\nPOST BODY: \n", body, "\n",
                  "ERROR TYPE: ", typeof(err), "\n" ) )
    msg_data::Array{UInt8,1} = Array{UInt8,1}( try; string(getfield(err, :response)); catch; try; string(getfield(err, :msg));  catch; ""; end; end )
    return (msg_data, false)
  end
end

datareq_summ(src::String, ID::String, d0::String, d1::String) = ("\n" * src *
  " query:\nID = " * ID * "\nSTART = " * d0 * "\nEND = " * d1)

# ============================================================================
# Utility functions not for export
hashfname(str::Array{String,1}, ext::String) = string(hash(str), ".", ext)

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
    j = findfirst(x -> x == id, ids)
    if j == nothing
      u[n] = true
    else
      if nxs[j] != length(S.x[n])
        u[n] = true
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
  fname = string(join([y, string(j), i, namestrip(net), namestrip(sta), namestrip(loc), namestrip(cha)],'.'), ".", q, ".", ext)
  safe_isfile(fname) && @warn(string("File ", fname, " contains an identical request. Overwriting."))
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

"""
## CHANNEL ID SPECIFICATION
Channel ID data can be passed to SeisIO web functions in three ways:

1. String: a comma-delineated list of IDs formatted `"NET.STA.LOC.CHA"` (e.g. `"PB.B004.01.BS1,PB.B004.01.BS2"`)
2. Array{String,1}: one ID per entry, formatted `"NET.STA.LOC.CHA"` (e.g. `["PB.B004.01.BS1","PB.B004.01.BS2"]`)
3. Array{String,2}: one ID per row, formatted `["NET" "STA" "LOC" "CHA"]` (e.g. `["PB" "B004" "01" "BS?"; "PB" "B001" "01" "BS?"]`)

The `LOC` field can be left blank (e.g. `"UW.ELK..EHZ", ["UW" "ELK" "" "EHZ"]`).

The allowed subfield widths before channel IDs break is identical to the FDSN
standard: NN.SSSSS.LL.CCC (network name length ≤ 2 chars, etc.)

#### SEEDLINK ONLY
For SeedLink functions (`seedlink!`, `has_stream`, etc.), channel IDs can
include a fifth field (i.e. NET.STA.LOC.CHA.T) to set the "type" flag (one of
DECOTL, for Data, Event, Calibration, blOckette, Timing, or Logs). Note that
SeedLink calibration, timing, and logs are not supported by SeisIO.
"""
function chanspec()
  return nothing
end
