getcha(cf) = (f = open(cf, "r"); F = readlines(f); close(f); return F)

function lsw(filestr::ASCIIString)
  d, f = splitdir(filestr)
  i = search(f, '*')
  if !isempty(i)
    ff = f[1:i[1]-1]
    for j = 1:1:length(i)
      ei = j == length(i) ? length(f) : i[j+1]
      ff = join([ff, '.', '*', f[i[j]+1:ei]])
    end
  else
    ff = f
  end
  fff = Regex(ff)
  files = [joinpath(d, j) for j in filter(i -> ismatch(fff,i), readdir(d))]
  return files
end

# stupid, but effective
function int4_2c(s::Array{Int32,1})
  p = map(Int32, [-8,4,2,1])
  return dot(p, s[1:4]), dot(p, s[5:8])
end

function win32dict(Nh::UInt16, cinfo::ASCIIString, hexID::ASCIIString)
  k = Dict{ASCIIString,Any}()
  k["hexID"] = hexID
  k["data"] = Array{Int32,1}()
  k["OldTime"] = 0
  k["seisSum"] = 0
  k["seisN"] = 0
  k["seisNN"] = 0
  k["gapStart"] = Array{Int64,1}(0)
  k["gapEnd"] = Array{Int64,1}(0)
  k["fs"] = Float32(Nh)
  c = split(cinfo)
  k["scale"] = parse(c[13]) / (parse(c[8]) * 10^(parse(c[12])/20))
  k["lineDelay"] = Float32(parse(c[3])/1000)
  k["unit"] = c[9]
  k["fc"] = Float32(1/parse(c[10]))
  k["hc"] = Float32(parse(c[11]))
  k["loc"] = [parse(c[14]), parse(c[15]), parse(c[16])]
  k["pCorr"] = parse(Float32, c[17])
  k["sCorr"] = parse(Float32, c[18])
  # A comment column isn't strictly required by the win format specs
  k["comment"] = length(c) > 18 ? c[19] : ""
  return k
end

function getcid(Chans, ch)
  for i = 1:1:length(Chans)
    L = split(Chans[i])
    if L[1] == ch
      return i, join(L[4:5],'.')
    end
  end
  return -1, ""
end

"""
    S = readwin32(filestr, chanfile)

Read all win32 data matching string pattern `filestr`, with corresponding
channel file `chanfile`, into dictionary S. Keys correspond to win32


"""
function readwin32(filestr::ASCIIString, cf::ASCIIString; v=false)
  Chans = getcha(cf)
  seis = Dict{ASCIIString,Any}()
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
        skip(fid, 2)
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
        haskey(seis, id) || (seis[id] = win32dict(Nh, Chans[c], hexID))
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
        # cumsum doesn't work on int32...?
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
  seis["src"] = "win32 file"
  return seis
end

function win32toseis(D = Dict{ASCIIString,Any}())
  K = sort(collect(keys(D)))
  seis = SeisData()
  for k in K
    !isa(D[k],Dict{ASCIIString,Any}) && continue
    id_stub = split(k, '.')
    id = join(["JP",id_stub[2],id_stub[1],id_stub[3]], '.')
    # There will be some issues here; Japanese files use their own station
    # names, which don't necessarily correspond to their international names
    # See e.g. http://data.sokki.jmbsc.or.jp/cdrom/seismological/catalog/appendix/apendixe.htm
    # for an example of poor correspondence
    misc = Dict{ASCIIString,Any}()
    [misc[sk] = D[k][sk] for sk in ("hexID", "fc", "hc", "pCorr", "sCorr", "lineDelay")]
    seis += SeisObj(name=k, id=id, x=map(Float64, D[k]["data"]),
      gain=1/D[k]["scale"], fs=D[k]["fs"], units=D[k]["unit"],
      loc=[D[k]["loc"]; 0; 0], misc=misc, notes=[string("src=", D["src"])])
  end
  return seis
end

"""
    S = r_win32(filestr, chanfile)

Read all win32 data matching string pattern `filestr`, with corresponding
channel file `chanfile`; return a seisdata object S.

"""
r_win32(f::ASCIIString, c::ASCIIString; v=false::Bool) = (
  D = procwin32(f, c, v=v); return(win32toseis(D)))
