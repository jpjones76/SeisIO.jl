using DelimitedFiles: readdlm
# =======================================================
# Auxiliary functions not for export

# stupid, but effective
function int4_2c(s::Array{Int32, 1})
  p = Int32[-8,4,2,1]
  return dot(p, s[1:4]), dot(p, s[5:8])
end

function win32dict(Nh::UInt16, cinfo::String, hexID::String, StartTime::Float64, orgID::String, netID::String)
  D = Dict{String,Any}(   "hexID" => hexID,
                          "orgID" => orgID,
                          "netID" => netID,
                          "data" => Array{Int32, 1}(undef, 0),
                          "OldTime" => 0,
                          "seisSum" => 0,
                          "seisN" => 0,
                          "seisNN" => 0,
                          "startTime" => StartTime,
                          "locID" => @sprintf("%i%i", Base.parse(Int64, orgID), Base.parse(Int64, netID)),
                          "gapStart" => Array{Int64, 1}(undef, 0),
                          "gapEnd" => Array{Int64, 1}(undef, 0),
                          "fs" => Float32(Nh)   )

  # Ensure my locID kluge doesn't produce garbage
  Meta.parse(D["locID"]) > 99 && (@warn(string("For hexID = ", hexID, ", locID > 99; location ID unset.")); D["locID"] = "")

  # Get local (Japanese) network and subnet
  nets = readdlm(string(Pkg.dir(),"/SeisIO/src/Formats/jpcodes.csv"), ';')
  i = findall((nets[:,1].==orgID).*(nets[:,2].==netID))
  D["netName"] = isempty(i) ? "Unknown" : nets[i[1],:]

  # Entries from channel line
  c = split(cinfo)
  D["scale"] = Float64(Meta.parse(c[13]) / (Meta.parse(c[8]) * 10.0^(Meta.parse(c[12])/20.0)))
  D["lineDelay"] = Base.parse(Float32,c[3]) / 1000.0f0
  D["unit"] = String(c[9])
  D["fc"] = 1.0f0 / Base.parse(Float32, c[10])
  D["hc"] = Base.parse(Float32,  c[11])
  D["loc"] = Float32[Base.parse(Float32, c[14]), Base.parse(Float32, c[15]), Base.parse(Float32, c[16])]
  D["pCorr"] = Base.parse(Float32, c[17])
  D["sCorr"] = Base.parse(Float32, c[18])
  D["comment"] = length(c) > 18 ? String(c[19]) : ""
  return D
end

function getcid(Chans::Array{String, 1}, hexID::String)
  for i = 1:length(Chans)
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

Read all win32 files matching pattern `filestr` into SeisData object `S`, with channel info stored in `chanfile`.
"""
function readwin32(filestr::String, cf::String; v=0::Int)
  Chans = readlines(cf)
  seis = Dict{String,Any}()
  files = SeisIO.ls(filestr)
  nf = 0
  for fname in files
    v>0 && println("Processing ", fname)
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
        x = Array{Int32, 1}(undef, N)
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
          for i = 1:length(V)
            x1,x2 = int4_2c(map(Int32, Vector{UInt8}(bits(V[i])) - 0x30)) # was: x1,x2 = int4_2c(map(Int32, bits(V[i]).data - 0x30))
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
          for i = 1:N
            xi = join([bits(V[3*i]),bits(V[3*i-1]),bits(V[3*i-2])])
            x[i+1] = Meta.parse(Int32, xi, 2)
          end
        else
          fmt = (C == 2 ? Int16 : Int32)
          V = read(fid, fmt, N)
          x[2:end] = [bswap(i) for i in V]
        end

        # cumsum doesn't work on Int32 in Julia as of 0.4.x
        [x[i] += x[i-1] for i in 2:length(x)]

        # Account for time gaps
        gap = NewTime - seis[id]["OldTime"] - 1
        if ((gap > 0) && (seis[id]["OldTime"] > 0))
          @warn(@sprintf("Time gap detected! (%.1f s at %s, beginning %s)",
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
      for j = 1:J
        si = seis[i]["gapStart"][j]
        ei = seis[i]["gapEnd"][j]
        seis[i]["data"][si:ei] = av
      end
    end
  end

  S = SeisData()
  K = sort(collect(keys(seis)))

  # Create SeisData object from this mess
  for k in K
    !isa(seis[k], Dict{String,Any}) && continue

    fs    = Float64(seis[k]["fs"])
    units = seis[k]["unit"]
    x     = map(Float64, seis[k]["data"])
    t     = [1 round(Int64,seis[k]["startTime"]/μs); length(seis[k]["data"]) 0]
    src   = filestr
    misc  = Dict{String,Any}(i => seis[k][i] for i in ("hexID", "orgID", "netID", "fc", "hc", "pCorr", "sCorr", "lineDelay", "comment"))

    if units == "m/s"
      resp = map(Complex{Float64}, fctopz(seis[k]["fc"], hc=seis[k]["hc"], units=units))
    else
      resp = Array{Complex{Float64}, 2}(undef, 0, 2)
    end

    # There will be issues here. Japanese files use NIED or local station
    # names, which don't necessarily use international station or network codes. See e.g.
    # http://data.sokki.jmbsc.or.jp/cdrom/seismological/catalog/appendix/apendixe.htm
    # for an example of the (lack of) correspondence
    (net, sta, chan_stub) = split(k, '.')
    b = getbandcode(fs, fc = seis[k]["fc"])       # Band code
    g = 'H'                                       # Gain code
    if chan_stub[1] == 'U'
      c = 'Z'                                     # Nope
    else
      c = chan_stub[1]                            # Channel code
    end
    id    = join(["JP", sta, seis[k]["locID"], string(b,g,c)], '.')

    C = SeisChannel(id=id, name=k, x=x, t=t, gain=seis[k]["scale"], fs=fs, units=units, loc=[seis[k]["loc"]; 0.0; 0.0], misc=misc, src=src, resp=resp)
    note!(C, string("+src: readwin32 ", fname))
    note!(C, string("channel file: ", cf))
    note!(C, string("location comment: ", seis[k]["comment"]))
    S += C
  end
  return S
end
