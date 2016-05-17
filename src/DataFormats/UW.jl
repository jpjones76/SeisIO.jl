# REALLY slow...need to rewrite for 1 dict per channel, as with Win32
function nextline(pfid, c::Char)
  tmpstring = chomp(readline(pfid))
  while tmpstring[1] != c
    tmpstring = chomp(readline(pfid))
    if eof(pfid)
      tmpstring = -1
      break
    end
  end
  return tmpstring
end

function guess_nc(pfid, S)
  seekstart(pfid)
  nc = 0
  S["sta"] = Array{ASCIIString,1}()
  S["cha"] = Array{ASCIIString,1}()
  while !eof(pfid)
    L = readline(pfid)
    if startswith(L, '.')
      LL = split(L, '.')
      sta = LL[2]
      cmp = split(LL[3])[1]
      if isempty(find(((S["cha"].==cmp) & (S["sta"].==sta)) .== true))
        push!(S["sta"], sta)
        push!(S["cha"], cmp)
        nc+=1
      end
    end
  end
  seekstart(pfid)
  return nc, S
end

function procuwpf!(S, Nc::Int64, pickfile::AbstractString, v::Bool)
  has_datafile = true
  pfid = open(pickfile, "r")
  if Nc < 1
    Nc, S = guess_nc(pfid, S)
    S["Nc"] = Nc
    has_datafile = false
  end
  seekstart(pfid)
  A = nextline(pfid,'A')
  v && println(A)
  ycorr = 0
  if length(A) == 75 || length(A) == 12
    y2k = 0
    ycorr = 1900
  else
    y2k = 2
  end
  S["type"] = A[2]

  # Start time
  st = A[3:4+y2k]
  ycorr > 0 && (st = string(parse(st)+ycorr))
  ot = Dates.datetime2unix(DateTime(parse(st), parse(A[5+y2k:6+y2k]),
  parse(A[7+y2k:8+y2k]))) +
  parse(A[9+y2k:10+y2k])*3600 + parse(A[11+y2k:12+y2k])*60

  if length(A) > (14+y2k)
    if y2k == 0
      (sec, evla, evlo, S["evdp"], S["fix"], S["mag"], S["numsta"], S["numpha"],
      S["gap"], S["dmin"], S["rms"], S["err"], S["q"], S["vmod"]) =
      (A[13:18], A[19:26], A[27:35], A[36:41], A[42], A[43:46], A[47:49], A[51:53],
      A[54:57], A[58:60], A[61:65], A[66:70], A[71:72], A[74:75])
    else
      (sec, evla, evlo, S["evdp"], S["fix"], S["mag"], S["numsta"], S["numpha"],
      S["gap"], S["dmin"], S["rms"], S["err"], S["q"], S["vmod"]) =
      (A[15:20], A[21:28], A[29:37], A[38:43], A[44], A[45:48], A[49:51], A[53:55],
      A[56:59], A[60:62], A[63:67], A[68:72], A[73:74], A[76:77])
    end
    for i in ("evdp", "mag", "numsta", "numpha", "gap", "dmin", "rms", "err")
      S[i] = parse(S[i])
    end

    # Set start time of each channel
    ot += parse(sec)
    if has_datafile
      S["start"] = zeros(Float32,Nc)
      for n = 1:1:Nc
        S["start"][n] = ot - S["ctime"][n]
      end
    end
    S["ot"] = ot

    # Lat, Lon
    S["evla"] = (parse(evla[1:3]) + parse(evla[5:6])/60 + parse(evla[7:8])/6000)
    *(evla[4] == 'S' ? -1.0 : 1.0)
    S["evlo"] = (parse(evlo[1:4]) + parse(evlo[6:7])/60 + parse(evlo[8:9])/6000)
    *(evlo[5] == 'W' ? -1.0 : 1.0)

  elseif length(A) > 12+y2k
    S["reg"] = A[14+y2k]
  end

  # Error line...mostly pointless, left as a string w/limited parses for fast QC
  seekstart(pfid)
  E = nextline(pfid,'E')
  if E != -1
    #(S["meanRMS"], S["sdAbout0"], S["sswres"], S["ndfr"], S["fixxyzt"],
    #S["sdx"], S["sdy"], S["sdz"], S["sdt"], S["sdmag"], S["meanUncert"]) =
    #(E[12:17], E[18:23], E[24:29], E[30:37], E[38:41], E[42:45],
    #E[46:50], E[51:55], E[56:60], E[61:65], E[66:70], E[76:79])
    #for i in ("meanRMS", "sdAbout0", "sswres", "ndfr", "sdx", "sdy", "sdz",
    #  "sdt", "sdmag", "meanUncert")
    #  S[i] = parse(S[i])
    #end
    S["error_line"] = E
    (S["rms"], S["sdx"], S["sdy"], S["sdz"], S["sdmag"], S["meanUncert"]) =
      (parse(E[12:17]), E[46:50], E[51:55], E[56:60], E[66:70], E[76:79])
  end

  # Alternate magnitude line
  seekstart(pfid)
  sline = nextline(pfid, 'S')
  if sline != -1
    warn("Alternate magnitude found, M_d overwritten.")
    (S["mag"], S["magtype"]) = (parse(sline[1:5]), sline(6:8))
  end

  # Focal mechanism line(s)
  seekstart(pfid)
  mline = nextline(pfid,'M')
  m1 = 0
  if mline != -1
    S["mech_lines"] = Array{ASCIIString,1}()
    while mline != -1
      m1 += 1
      push!(S["mech_lines"], mline)
      mline = nextline(pfid,'M')
    end
    v && println("Processed ", m1, " focal mechanism lines.")
  end

  # Pick lines
  seekstart(pfid)
  m1 = 0
  pline = nextline(pfid,'.')
  if pline != -1
    S["P"] = ones(Float32, Nc, 4).*repmat([-1.0 9.0 9.9 99.9], Nc, 1)
    S["S"] = ones(Float32, Nc, 4).*repmat([-1.0 9.0 9.9 99.9], Nc, 1)
    S["D"] = -1.0*ones(Float32, Nc)
    S["P_pol"] = collect(repeated("_", Nc))
    #S["S_pol"] = collect(repeated("_", Nc))
    # Likely unneeded, AFAIK S polarities weren't used at UW (did SPONG even allow them?)

    while pline != -1
      m1 += 1
      sta = pline[2:4]
      cmp = pline[6:8]
      for j1 = 1:1:Nc
        if ((S["sta"][j1] == sta) && (S["cha"][j1] == cmp))
          # Process P pick if one exists
          try
            i = search(pline, "(P P")[1]
            pl = split(pline[i:end])
            S["P_pol"][j1] = pl[3]
            S["P"][j1,:] = [parse(pl[4]) parse(pl[5]) parse(pl[6]) parse(pl[7][1:end-1])]
          end
          try
            i = search(pline, "(P S")[1]
            pl = split(pline[i:end])
            S["S"][j1,:] = [parse(pl[4]) parse(pl[5]) parse(pl[6]) parse(pl[7][1:end-1])]
          end
          try
            i = search(pline, "(D")[1]
            pl = split(pline[i:end])
            S["D"][j1] = parse(pl[2][1:end-1])
          end
        end
      end
      pline = nextline(pfid,'.')
    end
  end
  v && println("Processed ", m1, " pick lines.")

  # Comment lines
  seekstart(pfid)
  m1 = 0
  cline = nextline(pfid,'C')
  if cline != -1
    S["comment"] = Array{ASCIIString,1}()
    while cline != -1
      m1 += 1
      push!(S["comment"], cline[3:end])
      cline = nextline(pfid,'C')
    end
    v && println("Processed ", m1, " comment lines.")
  end
  S["src"] = "uw df"
  close(pfid)
  return S
end

"""
  readuwpf(PFILE)

  Read UW-format pickfile PFILE into a dictionary containing pick information.
Only works correctly with single-event pickfiles.
"""
readuwpf(pickfile; v=false::Bool) = (procuwpf!(Dict{ASCIIString,Any}(), -1, pickfile, v))

function readuwdf(datafile::AbstractString; b=true::Bool, v=false::Bool)
  dconst = -11676096000

  # Open data file
  fid = open(datafile, "r")

  # Process master header
  M = Dict{ASCIIString,Any}()
  S = Dict{ASCIIString,Any}()
  M["nchan"]    = read(fid, Int16)
  M["lrate"]    = read(fid, Int32)
  lmin          = bswap(read(fid, Int32))
  lsec          = bswap(read(fid, Int32))
  M["length"]   = read(fid, Int32)
  M["tapenum"]  = read(fid, Int16)
  M["eventnum"]	= read(fid, Int16)
  [M[i] = bswap(M[i]) for i in collect(keys(M))]
  M["flags"]    = read(fid, Int16, 10)
  M["flags"] = [bswap(i) for i in M["flags"]]
  M["extra"]    = replace(ascii(read(fid, UInt8, 10)),"\0"," ")
  M["comment"]  = replace(ascii(read(fid, UInt8, 80)),"\0"," ")

  # Set M time using lmin and lsec WHICH USE GREGORIAN MINUTES JESUS CHRIST WTF
  uwdate = Dates.unix2datetime(lmin*60 + lsec*1.0e-6 + dconst)
  M["yr"] = Dates.Year(uwdate).value
  M["mo"] = Dates.Month(uwdate).value
  M["dy"] = Dates.Day(uwdate).value
  M["hr"] = Dates.Hour(uwdate).value
  M["mn"] = Dates.Minute(uwdate).value
  M["sc"] = Dates.Second(uwdate).value

  # Seek to end of file get number of structures
  seekend(fid)
  skip(fid, -4)
  nstructs = b ? bswap(read(fid, Int32)) : read(fid, Int32)
  #println("nstructs=", nstructs)
  structs_os = (-12*nstructs)-4
  tc_os = 0

  # Set version of UW seismic data file (char may be empty, leave code as-is!)
  uwformat = M["extra"][3] == '2' ? 2 : 1
  # Read in UW2 data structures
  chno = Array{Int32,1}()
  corr = Array{Int32,1}()
  if uwformat == 2
    seekend(fid)
    skip(fid, structs_os)
    for i1 = 1:1:nstructs
      structtag    = replace(ascii(read(fid, UInt8, 4)),"\0","")
      #println(structtag)
      nstructs     = read(fid, Int32)
      byteoffset   = read(fid, Int32)
      nstructs   = bswap(nstructs)
      byteoffset = bswap(byteoffset)
      if structtag == "CH2"
        Nc = nstructs
      elseif structtag == "TC2"
        fpos = position(fid)
        seek(fid, byteoffset)
        for n = 1:1:nstructs
          push!(chno,read(fid, Int32))
          push!(corr,read(fid, Int32))
        end
        bswap && [chno[n] = bswap(chno[n]) for n in chno]
        bswap && [corr[n] = bswap(corr[n]) for n in chno]
        chno .+= 1
        tc_os = -8*nstructs
        seek(fid, fpos)
      end
    end
  else
    Nc = M["nchan"]
  end
  v && println("Processing ", Nc , " channels.")
  Nc = Int(Nc)

  # Write time corrections
  timecorr = zeros(Nc)
  if length(chno) > 0
       for n = 1:1:length(chno)
           timecorr[chno[n]] = corr[n]*1.0e-6
       end
  end

  # Read UW2 channel headers
  if uwformat == 2
    seekend(fid)
    skip(fid, Int(-56*Nc + structs_os + tc_os))
    fmt = Array{DataType,1}(Nc)
    for i in ["chlen", "offset", "lmin", "lsec", "expan1"]
      S[i] = Array{Int32,1}()
    end
    for i in ["lta", "trig", "bias", "fill"]
      S[i] = Array{Int16,1}()
    end
    compflg = Array{ASCIIString,1}()
    chid = Array{ASCIIString,1}()
    expan2 = Array{ASCIIString,1}()
    name = Array{ASCIIString,1}()
    S["fs"] = Array{Int32,1}()

    for i1 = 1:1:Nc
      push!(S["chlen"], read(fid, Int32))
      push!(S["offset"], read(fid, Int32))
      push!(S["lmin"], read(fid, Int32))
      push!(S["lsec"], read(fid, Int32))
      push!(S["fs"], read(fid, Int32))
      push!(S["expan1"], read(fid, Int32))
      push!(S["lta"], read(fid, Int16))
      push!(S["trig"], read(fid, Int16))
      push!(S["bias"], read(fid, Int16))
      push!(S["fill"], read(fid, Int16))
      push!(name, replace(ascii(read(fid, UInt8, 8)),"\0",""))
      tmp = replace(ascii(read(fid, UInt8, 4)),"\0","")
      for j1 = 1:1:length(tmp)
        if tmp[j1] == 'F'
          fmt[i1] = Float32
        elseif tmp[j1]=='L'
          fmt[i1] = Int32
        elseif tmp[j1]=='S'
          fmt[i1] = Int16
        end
      end
      push!(compflg, replace(ascii(read(fid, UInt8, 4)),"\0",""))
      push!(chid, replace(ascii(read(fid, UInt8, 4)),"\0",""))
      push!(expan2, replace(ascii(read(fid, UInt8, 4)),"\0",""))
    end

    for i in collect(keys(S))
      for j=1:1:length(S[i])
        S[i][j] = bswap(S[i][j])
      end
    end
    S["cha"] = compflg
    S["chid"] = chid
    S["expan2"] = expan2
    S["sta"] = name
    S["fs"] = map(Float32, S["fs"]./1000)
    S["ctime"] = Array{Float64,1}(Nc)
    for i = 1:1:Nc
      S["ctime"][i] = S["lmin"][i]*60 + S["lsec"][i]*1.0e-6 + timecorr[i] + dconst
    end
  end

  #Read UW channel data
  if uwformat == 2
    S["data"] = Array{Array{Any,1},1}(Nc)
    for i = 1:1:Nc
      seek(fid, S["offset"][i])
      seis = read(fid, fmt[i], S["chlen"][i])
      b && (seis = [bswap(s) for s in seis])
      S["data"][i] = seis
    end
  end
  close(fid)
  S["src"] = "uw pf"
  return S, Nc
end

"""
    S = readuw(filename)

Read seismic data in "UW" format into dictionary S. The UW interface libraries
are NOT required. Byte order of data files is assumed to be big endian.

`filename` must be either a datafile, or a pickfile in the same directory
as the datafile to be read.

    S = readuw(filename)

"""
function readuw(filename::ASCIIString; v=false::Bool)
  # Identify pickfile and datafile
  filename = realpath(filename)
  pickfile = ""
  datafile = ""
  ec = UInt8(filename[end])
  lc = collect(0x61:1:0x7a)
  if Base.in(ec,lc)
    pickfile = filename
    datafile = string(filename[1:end-1],"W")
  elseif ec == 'W'
    datafile = filename
    froot = filename[1:end-1]
    for i in lc
      pickfile = string(froot, Char(i))
      if isfile(pickfile)
        break
      end
    end
  else
    datafile = string(filename,'W')
    !isfile(datafile) && error("Invalid UW datafile name (must end with 'W')!")
    for i=0x61:1:0x7a
      pickfile = string(filename, Char(i))
      if isfile(pickfile)
        break
      end
    end
  end
  src_stub = "uw "

  # Datafile wrapper
  if isfile(datafile)
    v && println("Reading datafile ", datafile)
    S, Nc = readuwdf(datafile, b=b, v=v)
    v && println("Done reading data file.")
    src_stub *= "df"
    S["Nc"] = Nc
  else
    v && println("Skipping datafile (not found or not given)")
    S = Dict{ASCIIString,Any}()
  end

  # Pickfile wrapper
  if isfile(pickfile)
    v && println("Reading pickfile ", pickfile)
    procuwpf!(S, Nc, pickfile, v)
    v && println("Done reading pick file.")
    contains(src_stub, "df") && (src_stub *= "+")
    src_stub *= "pf"
  else
    v && println("Skipping pickfile (not found or not given)")
  end

  # Clean up
  for i in ("ctime","lmin","lsec","offset")
    try
      delete!(S,i)
    end
  end
  S["src"] = src_stub
  return S
end

function uwtoseis(S::Dict{ASCIIString,Any})
  seis = SeisData()
  misc_keys = ("P_pol", "bias", "chid", "chlen",  "expan1", "expan2", "fill", "lta", "trig")
  pick_keys = ("D", "P", "S")
  event_keys = ("dmin", "err", "error_line", "evdp", "evla", "evlo", "fix",
  "gap", "mag", "meanUncert", "mech_lines", "numpha", "numsta", "q",
  "rms", "sdmag", "sdx", "sdy", "sdz", "type", "vmod")

  for i = 1:S["Nc"]
    name = join(["UW",S["sta"][i],"",S["cha"][i]],'.')
    id = join(["UW",S["sta"][i],"",S["cha"][i]],'.')
    fs = S["fs"][i]
    src = S["src"]
    x = map(Float64, S["data"][i])
    notes = S["comment"]
    t = map(Float64, [0 S["start"][i]+S["ot"]; length(x) 0])
    misc = Dict{ASCIIString,Any}()
    for k in misc_keys
      misc[k] = S[k][i]
    end
    S["P"][i,1] > 0 && (misc["P"] = S["P"][i,:])
    S["S"][i,1] > 0 && (misc["S"] = S["S"][i,:])
    S["D"][i] > 0 && (misc["D"] = S["D"][i])

    seis += SeisObj(name=name, id=id, fs=fs, x=x, t=t, src=src, notes=notes,
      misc=misc, units="counts")
  end
  return seis
end

r_uw(f::ASCIIString; v=false::Bool) = (S = readuw(f, v=v); uwtoseis(S::Dict{ASCIIString,Any}))
