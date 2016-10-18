function get_uhead(src)
  if src == "IRIS"
    uhead = "http://service.iris.edu/fdsnws/"
  elseif src == "GFZ"
    uhead = "http://geofon.gfz-potsdam.de/fdsnws/"
  elseif src == "RESIF"
    uhead = "http://ws.resif.fr/fdsnws/"
  elseif src == "NCSN"
    uhead = "http://service.ncedc.org/fdsnws/"
  else
    uhead = src
  end
  return uhead
end

"""
    S = getsta(CC)

Retrieve station info for channels specified in SeedLink-formatted input file
**CC**. See SeedLink documentation for keyword options. Returns a SeisData object
with information from the requested channels.
"""
function getsta(CC::String;
  st="2011-01-08T00:00:00"::Union{Real,DateTime,String},
  et="2011-01-09T00:00:00"::Union{Real,DateTime,String},
  src="IRIS"::String,
  to=60::Real,
  v=false::Bool,
  vv=false::Bool)

  (sta,cha) = chparse(CC)
  if vv
    println("sta =", sta, "cha=", cha)
  end
  S = getsta(sta, cha, src=src, st=st, et=et, to=to, v=v, vv=vv)
  return S
end
function getsta(stations::Array{String,1}, channels::Array{String,1};
  src="IRIS"::String,
  st="2011-01-08T00:00:00"::Union{Real,DateTime,String},
  et="2011-01-09T00:00:00"::Union{Real,DateTime,String},
  to=60::Real,
  v=false::Bool,
  vv=false::Bool)

  d0, d1 = parsetimewin(st, et)
  uhead = string(get_uhead(src), "station/1/query?")
  S = SeisData()
  for i = 1:1:size(stations,1)
    (sta, net) = split(stations[i],' ')
    cha = channels[i]
    if isempty(cha)
      umid = string("net=", net, "&sta=", sta)
    else
      umid = string("net=", net, "&sta=", sta, "&cha=", cha)
    end
    utail = string("&starttime=", d0, "&endtime=", d1, "&format=text&level=channel")
    sta_url = string(uhead, umid, utail)
    if (v | vv)
      println("Retrieving station data for net=", net, ", sta=", sta, ", cha=", cha)
      vv && println("URL = ", sta_url)
    end
    ch_data = readall(get(sta_url, timeout=to, headers=webhdr()))
    vv && println(ch_data)
    ch_data = split(ch_data,"\n")
    for n = 2:1:size(ch_data,1)-1
      C = split(ch_data[n],"|")
      try
        s = parse_cinfo(C, src)
        push!(S, s)
      catch
        ID = @sprintf("%s.%s.%s.%s",C[1],C[2],C[3],C[4])
        warn("Failed to parse ", ID,"; bad or missing parameter(s) returned by server.")
        if (v | vv)
          println("Text dump of bad record line follows:")
          println(ch_data[n])
        end
      end
    end
  end

  return S
end

function parse_cinfo(C::Array{SubString{String},1}, src::String)
  #Network | Station | Location | Channel
  ID = @sprintf("%s.%s.%s.%s",C[1],C[2],C[3],C[4])
  NAME = ID
  LOC = collect([parse(Float64, C[5])
                 parse(Float64, C[6])
                 parse(Float64, C[7])+parse(Float64, C[8])
                 parse(Float64, C[9])
                 parse(Float64, C[10])])
  # Strictly speaking this is only accurate for passive velocity sensors
  RESP = fctopz(parse(Float64, C[13]))
  MISC = Dict{String,Any}(
    "SensorDescription" => String(C[11]),
    "SensorStart" => String(C[16]),
    "SensorEnd" => String(C[17])
    )

  return SeisChannel(name=NAME, id=ID, fs=parse(Float64, C[15]),
    gain=parse(Float64, C[12]), loc=LOC, misc=MISC, resp=RESP, src=src,
    units=C[14])
end

function webhdr()
  return Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.0.1")
end
