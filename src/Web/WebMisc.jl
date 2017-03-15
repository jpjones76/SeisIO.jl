# ============================================================================
# Utility functions not for export
webhdr() = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.0.1")
hashfname(str::Array{String,1}, ext::String) = string(hash(str), ".", ext)
# chansplit(C::String) = map(String, split(C,['.','_'],limit=4,keep=true))

function get_uhead(src::String)
  if src == "IRIS"
    uhead = "http://service.iris.edu/fdsnws/"
  elseif src == "GFZ"
    uhead = "http://geofon.gfz-potsdam.de/fdsnws/"
  elseif src == "RESIF"
    uhead = "http://ws.resif.fr/fdsnws/"
  elseif src == "NCEDC"
    uhead = "http://service.ncedc.org/fdsnws/"
  else
    uhead = src
  end
  return uhead
end

function savereq(D::Array{UInt8,1}, ext::String, net::String, sta::String,
  loc::String, cha::String, s::String, t::String, q::String)
  if ext == "miniseed"
    ext = "mseed"
  elseif ext == "sacbl"
    ext = "SAC"
  end
  ymd = split(s, r"[A-Z]")
  (y,m,d) = split(ymd[1],"-")
  j = md2j(parse(y),parse(m),parse(d))
  i = replace(split(s, 'T')[2],':','.')
  if loc == "--"
    loc = ""
  end
  fname = string(join([y, string(j), i, namestrip!(net), namestrip!(sta), namestrip!(loc), namestrip!(cha)],'.'), ".", q, ".", ext)
  if isfile(fname)
    warn(string("File ", fname, " contains an identical request. Overwriting."))
  end
  f = open(fname, "w")
  write(f, D)
  close(f)
  return nothing
end
