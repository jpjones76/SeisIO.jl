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
    GetSta("config_file")

Retrieve station info for channels specified in SeedLink-formatted input file
config_file. See documentation for keyword options. Returns a SeisData object
with information from the requested channels.
"""
function GetSta(config_file::String;
  st="2011-01-08T00:00:00"::Union{Real,DateTime,String},
  et="2011-01-09T00:00:00"::Union{Real,DateTime,String},
  src="IRIS"::AbstractString,
  to=60::Real,
  v=false::Bool,
  vv=false::Bool)

  isfile(config_file) || error("First argument must be a string array or config filename")
  conf = filter(i -> !startswith(strip(i, ['\r', '\n']), ['\#','\*']), open(readlines, config_file))
  chans = Array{String,2}(0,3)
  for i = 1:length(conf)
    try
      (net, sta, cha) = split(strip(conf[i],['\r','\n']), ' ', limit=3)
      if isempty(sel)
        chans = [chans; [net sta ""]]
      else
        sel = collect(split(strip(sel), ' '))
        N = numel(sel)
        chans = [chans; [repmat(net,N,1) repmat(sta,N,1) sel']]
      end
    catch
      (net, sta) = split(strip(conf[i],['\r','\n']), ' ')
      chans = [chans; [net sta ""]]
    end
  end
  vv && println("CHANS=", chans)
  S = GetSta(chans, src=src, st=st, et=et, to=to, v=v, vv=vv)
  return S
end
function GetSta(chans::Array{String,2},
  src="IRIS"::AbstractString,
  st="2011-01-08T00:00:00"::Union{Real,DateTime,String},
  et="2011-01-09T00:00:00"::Union{Real,DateTime,String},
  to=60::Real,
  v=false::Bool,
  vv=false::Bool)

  d0, d1 = parsetimewin(st, et)
  uhead = string(get_uhead(src), "station/1/query?")
  S = SeisData()
  for i = 1:1:size(chans,1)
    (net, sta, cha) = chans[i,1:3]
    if isempty(cha)
      umid = string("net=", net, "&sta=", sta)
    else
      umid = string("net=", net, "&sta=", sta, "&cha=", cha)
    end
    utail = string("&starttime=", d0, "&endtime=", d1, "&format=text&level=channel")
    sta_url = string(uhead, umid, utail)
    if (v | vv)
      println("Retrieving station data for ", net, ".", sta, ".", cha)
      vv && println("URL = ", sta_url)
    end
    hdr = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.0.1")
    ch_data = readall(get(sta_url, timeout=to, headers=hdr))
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
  NAME = copy(ID)
  LOC = collect([parse(Float64, C[5])
                 parse(Float64, C[6])
                 parse(Float64, C[7])+parse(Float64, C[8])
                 parse(Float64, C[9])
                 parse(Float64, C[10])])
  # Strictly speaking this is only accurate for passive velocity sensors
  RESP = fctopz(parse(Float64, C[13]))
  MISC = Dict{String,Any}("SensorDescription" => C[11], "StartTime" => C[16], "EndTime" => C[17])

  return SeisObj(name=NAME, id=ID, fs=parse(Float64, C[15]),
    gain=parse(Float64, C[12]), loc=LOC, misc=MISC, resp=RESP, src=src,
    units=C[14])
end
