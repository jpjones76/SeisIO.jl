# ============================================================================
# Utility functions not for export
webhdr() = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.0.1")
hashfname(str::Array{String,1}, ext::String) = string(hash(str), ".", ext)

function get_uhead(src::String)
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

function savereq(D::Array{UInt8,1}, ext::String, net::String, sta::String,
  loc::String, cha::String, s::String, t::String, q::String; c=false::Bool)
  if ext == "miniseed"
    ext = "mseed"
  elseif ext == "sacbl"
    ext = "SAC"
  end
  if c
    ymd = split(s, r"[A-Z]")
    (y,m,d) = split(ymd[1],"-")
    j = md2j(parse(y),parse(m),parse(d))
    i = replace(split(s, 'T')[2],':','.')
    if loc == "--"
      loc = ""
    end
    fname = string(join([y, string(j), i, net, sta, loc, cha],'.'), ".", q, ".", ext)
  else
    fname = hashfname([net, sta, loc, cha, s, t, q], ext)
  end
  if isfile(fname)
    warn(string("File ", fname, " contains an identical request. Not overwriting."))
  end
  f = open(fname, "w")
  write(f, D)
  close(f)
  return nothing
end
# ============================================================================

"""
    S = get_sta(CF)

Retrieve station/channel info for SeedLink-formatted parameter file (or string) `CF`. Type `?SeedLink` for keyword options.
"""
function get_sta(CC::String;
  st="2011-01-08T00:00:00"::Union{Real,DateTime,String},
  et="2011-01-09T00:00:00"::Union{Real,DateTime,String},
  src="IRIS"::String,
  to=60::Real,
  v=false::Bool,
  vv=false::Bool)

  #(sta,cha) = parse_chan_str(CC)
  Q = SL_parse(CC, fdsn=true)
  if vv
    println("station query =", Q)
  end
  S = get_sta(Q, src=src, st=st, et=et, to=to, v=v, vv=vv)
  return S
end
function get_sta(stations::Array{String,1};
  src="IRIS"::String,
  st="2011-01-08T00:00:00"::Union{Real,DateTime,String},
  et="2011-01-09T00:00:00"::Union{Real,DateTime,String},
  to=60::Real,
  v=false::Bool,
  vv=false::Bool)

  d0, d1 = parsetimewin(st, et)
  uhead = string(get_uhead(src), "station/1/query?")
  seis = SeisData()
  for i = 1:1:size(stations,1)
    utail = string("&starttime=", d0, "&endtime=", d1, "&format=text&level=channel")
    sta_url = string(uhead, stations[i], utail)
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
        #Network | Station | Location | Channel
        ID = @sprintf("%s.%s.%s.%s",C[1],C[2],C[3],C[4])
        NAME = ID
        LOC = collect([parse(Float64, C[5])
                       parse(Float64, C[6])
                       parse(Float64, C[7])+parse(Float64, C[8])
                       parse(Float64, C[9])
                       90.0 - parse(Float64, C[10])])

        # Strictly speaking this is only accurate for passive velocity sensors
        RESP = fctopz(parse(Float64, C[13]))
        MISC = Dict{String,Any}(
          "SensorDescription" => String(C[11]),
          "SensorStart" => String(C[16]),
          "SensorEnd" => String(C[17])
          )

        s = SeisChannel(name=NAME, id=ID, fs=parse(Float64, C[15]),
          gain=parse(Float64, C[12]), loc=LOC, misc=MISC, resp=RESP, src=src,
          units=C[14])

        note(s, string("src = get_sta(", src, ")"))
        seis += s
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

  return seis
end
