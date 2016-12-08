# =======================================================
# Auxiliary functions not for export

# stupid, but effective
function int4_2c(s::Array{Int32,1})
  p = Int32[-8,4,2,1]
  return dot(p, s[1:4]), dot(p, s[5:8])
end

function win32dict(Nh::UInt16, cinfo::String, hexID::String, StartTime::Float64, orgID::String, netID::String)
  k = Dict{String,Any}("hexID" => hexID, "orgID" => orgID, "netID" => netID, "data" => Array{Int32,1}(),
    "OldTime" => 0, "seisSum" => 0, "seisN" => 0, "seisNN" => 0, "startTime" => StartTime,
    "locID" => @sprintf("%i%i", parse(orgID), parse(netID)), "gapStart" => Array{Int64,1}(0), "gapEnd" => Array{Int64,1}(0), "fs" => Float32(Nh))

  # Ensure my locID kluge doesn't produce garbage
  parse(k["locID"]) > 99 && (warn(string("For hexID = ", hexID, ", locID > 99; location ID unset.")); k["locID"] = "")

  # Get local (Japanese) network and subnet
  nets = readdlm(string(Pkg.dir(),"/SeisIO/src/Formats/jpcodes.csv"), ';')
  i = find((nets[:,1].==orgID).*(nets[:,2].==netID))
  k["netName"] = isempty(i) ? "Unknown" : nets[i[1],:]

  # Entries from channel line
  c = split(cinfo)
  k["scale"] = Float64(parse(c[13]) / (parse(c[8]) * 10^(parse(c[12])/20)))
  k["lineDelay"] = Float32(parse(c[3])/1000)
  k["unit"] = c[9]
  k["fc"] = Float32(1/parse(c[10]))
  k["hc"] = Float32(parse(c[11]))
  k["loc"] = [parse(c[14]), parse(c[15]), parse(c[16])]
  k["pCorr"] = parse(Float32, c[17])
  k["sCorr"] = parse(Float32, c[18])
  k["comment"] = length(c) > 18 ? c[19] : ""
  return k
end

function getcid(Chans::Array{String,1}, hexID::String)
  for i = 1:1:length(Chans)
    L = split(Chans[i])
    if L[1] == hexID
      return i, join(L[4:5],'.')
    end
  end
  return -1, ""
end
# =======================================================

"""
    S = readwin32(filestr, chanfile)

Read all win32 files matching pattern `filestr` into SeisData object `S` using channel file `chanfile`.
"""
function readwin32(filestr::String, cf::String; v=false::Bool)
  Chans = readlines(cf)
  seis = Dict{String,Any}()
  files = lsw(filestr)
  nf = 0
  for fname in files
    v && println("Processing ", fname)
    fid = open(fname, "r")
    skip(fid, 4)
    while !eof(fid)
      # Start time: matches file info despite migraine-inducing nesting
      stime = DateTime(bytes2hex(read(fid, UInt8, 8)), "yyyymmddHHMMSSsss")
      NewTime = Dates.datetime2unix(stime)
      skip(fid, 4)
      lsecb = bswap(read(fid, UInt32))
      y = 0

      while y < lsecb
        orgID = bytes2hex(read(fid, UInt8, 1))
        netID = bytes2hex(read(fid, UInt8, 1))
        hexID = bytes2hex(read(fid, UInt8, 2))
        c = string(bits(read(fid, UInt8)),bits(read(fid, UInt8)))
        C = parse(UInt8, c[1:4], 2)
        N = parse(UInt16, c[5:end], 2)
        x = Array{Int32,1}(N)
        Nh = copy(N)

        # Increment bytes read (this file), decrement N if not 4-bit
        if C == 0
          B = N/2
        else
          N -= 1
          B = C*N
        end
        y += (10 + B)

        c, id = getcid(Chans, hexID)
        haskey(seis, id) || (seis[id] = win32dict(Nh, Chans[c], hexID, NewTime, orgID, netID))
        x[1] = bswap(read(fid, Int32))

        if C == 0
          V = read(fid, UInt8, Int(N/2))
          for i = 1:1:length(V)
            x1,x2 = int4_2c(map(Int32, bits(V[i]).data - 0x30))
            if i < N/2
              x[2*i:2*i+1] = [x1 x2]
            else
              x[N] = x1
            end
          end
          N+=1
        elseif C == 1
          x[2:end] = read(fid, Int8, N)
        elseif C == 3
          V = read(fid, UInt8, 3*N)
          for i = 1:1:N
            xi = join([bits(V[3*i]),bits(V[3*i-1]),bits(V[3*i-2])])
            x[i+1] = parse(Int32, xi, 2)
          end
        else
          fmt = (C == 2 ? Int16 : Int32)
          V = read(fid, fmt, N)
          x[2:end] = [bswap(i) for i in V]
        end

        # cumsum doesn't work on Int32 in Julia as of 0.4.x
        [x[i] += x[i-1] for i in 2:1:length(x)]

        # Account for time gaps
        gap = NewTime - seis[id]["OldTime"] - 1
        if ((gap > 0) && (seis[id]["OldTime"] > 0))
          warn(@sprintf("Time gap detected! (%.1f s at %s, beginning %s)",
                gap, id,  Dates.unix2datetime(seis[id]["OldTime"])))
          push!(seis[id]["gapStart"], 1+length(seis[id]["data"]))
          P = seis[id]["fs"]*gap
          seis[id]["seisNN"] += P
          append!(seis[id]["data"], zeros(Int32, Int(P)))
          push!(seis[id]["gapEnd"], length(seis[id]["data"]))
        end

        # Update times
        seis[id]["OldTime"] = NewTime
        append!(seis[id]["data"], x)
        seis[id]["seisSum"] += sum(x)
        seis[id]["seisN"] += Nh
      end
    end
    close(fid)
    nf += 1
  end

  # Fill data gaps
  for i in collect(keys(seis))
    J = length(seis[i]["gapStart"])
    if J > 0
      av = round(Int32, seis[i]["seisSum"]/seis[i]["seisN"])
      for j = 1:1:J
        si = seis[i]["gapStart"][j]
        ei = seis[i]["gapEnd"][j]
        seis[i]["data"][si:ei] = av
      end
      warn(@sprintf("Replaced %i missing data in %s with %0.2f",
            seis[i]["seisNN"], i, av))
    end
    for j in ("seisN", "seisNN", "seisSum", "OldTime", "gapStart", "gapEnd")
      delete!(seis[i],j)
    end
  end
  seis["fname"] = filestr
  seis["cfile"] = cf

  S = SeisData()
  K = sort(collect(keys(seis)))

  # Create SeisData object from this mess
  for k in K
    !isa(seis[k], Dict{String,Any}) && continue

    fs    = seis[k]["fs"]
    units = seis[k]["unit"]
    x     = map(Float64, seis[k]["data"])
    t     = [1 round(Int,seis[k]["startTime"]/μs); length(seis[k]["data"]) 0]
    src   = string("Win32,", u2d(time()), ",", filestr)
    notes = [string(" Channel file ", seis["cfile"]); string("  Location comment: ", seis[k]["comment"])]
    misc  = Dict{String,Any}(i => seis[k][i] for i in ("hexID", "orgID", "netID", "fc", "hc", "pCorr", "sCorr", "lineDelay", "comment"))

    if units == "m/s"
      resp = fctopz(seis[k]["fc"], hc=seis[k]["hc"], units=units)
    else
      resp = Array{Complex{Float64},2}(0,2)
    end

    # There will be issues here. Japanese files use NIED or local station
    # names, which don't necessarily match international station names. See e.g.
    # http://data.sokki.jmbsc.or.jp/cdrom/seismological/catalog/appendix/apendixe.htm
    # for an example of the (lack of) correspondence
    (net, sta, chan_stub) = split(k, '.')
    b = getbandcode(fs, fc = seis[k]["fc"])       # Band code
    g = 'H'                                       # Gain code
    c = chan_stub[1]                              # Channel code
    c == 'U' && (c = 'Z')                         # Nope

    id    = join(["JP", sta, seis[k]["locID"], string(b,g,c)], '.')

    S += SeisChannel(id=id, name=k, x=x, t=t, gain=seis[k]["scale"], fs=fs, units=units, loc=[seis[k]["loc"]; 0; 0], misc=misc, src=src, resp=resp, notes=notes)
  end
  return S
end
