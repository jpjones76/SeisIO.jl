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

"""
  (s, c) = chparse(C)

Parse channel file or channel string **C**. **C** must use valid SeedLink
syntax, e.g. C = "GE ISP  BH?.D,NL HGN"; (s, c) = chparse(C).

Outputs:
* s: array of station strings, each formatted "net sta"
* c: array of channel patterns to match
"""
function chparse(C::String)

  # Read C
  if isfile(C)
    ccfg = [strip(j, ['\r','\n']) for j in filter(i -> !startswith(i, ['\#','\*']), open(readlines, C))]
  else
    ccfg = split(C, ',')
  end

  stas = Array{String,1}()
  patts = Array{String,1}()

  # Parse ccfg
  for i = 1:length(ccfg)
    try
      (net, sta, sel) = split(ccfg[i], ' ', limit=3)
      ch = join([sta, net],' ')
      if isempty(sel)
        push!(stas, ch)
        push!(patts, "")
      else
        sel = collect(split(strip(sel), ' '))
        for j = 1:length(sel)
          push!(stas, ch)
          push!(patts, sel[j])
        end
      end
    catch
      (net, sta) = split(ccfg[i], ' ', limit=3)
      push!(stas,net)
      push!(patts,"")
    end
  end

  return (stas, patts)
end


"""
  (net, sta, loc, cha) = mkchanstr(C)

Generate input strings for web queries from channel config file or string C.
Each entry should be formatted "SSS NN LLCCC.T" (N = net, S = sta, L = loc,
C = channel; number of letters gives the allowed size of each string). T (type)
is not used by any routine that calls mkchanstr.

If C is a file, there should be one entry per line.

If C is a string, separate entries with commas.

If C is a string array, each string should comprise one channel specification.
"""
function mkchanstr(C::String)

  # Read C
  if isfile(C)
    ccfg = [strip(j, ['\r','\n']) for j in filter(i -> !startswith(i, ['\#','\*']), open(readlines, C))]
  else
    ccfg = split(C, ',')
  end
  net = Array{String,1}()
  sta = Array{String,1}()
  loc = Array{String,1}()
  cha = Array{String,1}()

  for i = 1:length(ccfg)
    (n, s, lc) = split(ccfg[i], ' ', limit=3)
    push!(net, n)
    push!(sta, s)
    if !isempty(lc)
      if contains(lc, ".")
        (lc,d) = split(lc, '.')
      end
      if !isempty(lc)
        lc = strip(lc)
        if length(lc) > 3
          push!(loc, lc[1:2])
          push!(cha, lc[3:5])
        else
          push!(cha, lc[1:3])
        end
      end
    end
  end

  # Deal with sta
  sta = join(unique(sta), ',')
  if contains(sta, "???")
    error("Station wildcards disallowed by SeisIO to limit data request sizes")
  end

  # Deal with net
  net = join(unique(net), ',')
  if contains(net, "??")
    net = "*"
  end

  # Deal with cha
  cha = join(unique(cha), ',')
  if contains(cha, "???")
    cha = "*"
  end

  # Deal with loc
  if isempty(loc)
    loc = "*"
  else
    loc = join(unique(loc),',')
  end
  return (net, sta, loc, cha)
end
mkchstr(C::Array{String,1}) = mkchstr(join(C,','))

hashfname(str::Array{String,1}, ext::String) = string(hash(str), ".", ext)

function savereq(D::Array{UInt8,1}, ext::String, net::String, sta::String,
  loc::String, cha::String, s::DateTime, t::DateTime, q::String; c=false::Bool)
  if ext == "miniseed"
    ext = "mseed"
  elseif ext == "sacbl"
    ext = "SAC"
  end
  if c
    y = Dates.year(s)
    m = Dates.month(s)
    d = Dates.day(s)
    j = md2j(y,m,d)
    i = replace(split(string(s), 'T')[2],':','.')
    if loc == "--"
      loc = ""
    end
    fname = string(join([y, j, i, net, sta, loc, cha],'.'), ".", q, ".", ext)
  else
    fname = hashfname([net, sta, loc, cha, string(s), string(t), q], ext)
  end
  if isfile(fname)
    warn(string("File ", fname, " appears to contain an identical request. Not overwriting."))
  end
  f = open(fname, "w")
  write(f, D)
  close(f)
  return nothing
end
