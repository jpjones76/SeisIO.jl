# ============================================================================
# Utility functions not for export
function nextline(pf::IO, c::Char)
  tmpstring = chomp(readline(pf))
  while tmpstring[1] != c
    tmpstring = chomp(readline(pf))
    if eof(pf)
      tmpstring = -1
      break
    end
  end
  return tmpstring
end

function getpf(froot::String, lc::Array{UInt8,1})
  for i in lc
    p = string(froot, Char(i))
    if isfile(p)
      return p
    end
  end
  return froot*".nope"
end
# ============================================================================

"""
    uwpf!(S, f)

Read University of Washington-format seismic pick info from pickfile `f` into header of SeisEvent `S`.

*Caution*: Low-level reader. *No* sanity checks are done to ensure `S` and `f` are the same event!
"""
function uwpf!(S::SeisEvent, pickfile::String; v=false::Bool)
  (pf, H) = uwpf(pickfile, v=v, u=true)
  N = S.data.n

  # Pick lines
  seekstart(pf)
  m = 0
  pline = nextline(pf,'.')
  while pline != -1
    m += 1
    sta = pline[2:4]
    cmp = pline[6:8]
    for j = 1:1:N
      if contains(S.data.id[j], sta) && contains(S.data.id[j], cmp)
        p = search(pline, "(P P")
        if !isempty(p)
          pl = split(pline[p[1]:end])
          S.data.misc[j]["p_pol"] = pl[3]
          S.data.misc[j]["t_p"] = [parse(pl[4]), parse(pl[5]), parse(pl[6]), parse(pl[7][1:end-1])]
        end
        s = search(pline, "(P S")
        if !isempty(s)
          pl = split(pline[s[1]:end])
          S.data.misc[j]["s_pol"] = pl[3]
          S.data.misc[j]["t_s"] = [parse(pl[4]), parse(pl[5]), parse(pl[6]), parse(pl[7][1:end-1])]
        end
        d = search(pline, "(D")
        if !isempty(d)
          pl = split(pline[d[1]:end])
          S.data.misc[j]["t_d"] = parse(pl[2][1:end-1])
        end
      end
    end
    pline = nextline(pf,'.')
  end
  v && println("Processed ", m, " pick lines.")
  close(pf)
  S.hdr = deepcopy(H)
  return S
end

"""
    H = uwpf(hf)

Read University of Washington-format seismic pick file `hf` into SeisHdr `H`.

    H = uwpf(hf, v=true)

Specify verbose mode (for debugging).
"""
function uwpf(pickfile::String; v=false::Bool, u=false::Bool)
  pf = open(pickfile, "r")
  seekstart(pf)
  A = nextline(pf,'A')
  v && println(A)
  c = 0
  if length(A) == 75 || length(A) == 12
    y = 0
    c = 1900
  else
    y = 2
  end
  D = Dict{String,Any}()
  D["type"] = A[2]

  # Start time
  ot = d2u(DateTime(string(parse(Int, A[3:4+y]) + c)*A[5+y:12+y],"yyyymmddHHMM"))

  si = [13,19,27,36,42,43,47,51,54,58,61,66,71,74]+y
  ei = [18,26,35,41,42,46,49,53,57,60,65,70,72,75]+y
  L = length(si)

  if length(A) > (14+y)
    ah = [A[si[i]:ei[i]] for i=1:1:L]
    # Parse numeric and string headers
    nh = [parse(ah[i]) for i in [1,4,6,7,8,9,10,11,12]]
    #    [sec, evdp, mag, numsta, numpha, gap, dmin, rms, err]
    (evla,evlo,qual,vmod) = (ah[2],ah[3],ah[13],ah[14])

    # Set start time of each channel
    ot += nh[1]
    dep = nh[2]
    mag = nh[3]

    # Lat, Lon, Dep, Mag
    lat = (parse(evla[1:3]) + parse(evla[5:6])/60 + parse(evla[7:8])/6000) * (evla[4] == 'S' ? -1.0 : 1.0)
    lon = (parse(evlo[1:4]) + parse(evlo[6:7])/60 + parse(evlo[8:9])/6000) * (evlo[5] == 'W' ? -1.0 : 1.0)
    mag_typ = "M_d (UW)"

  elseif length(A) > 12+y
    reg = A[14+y]
    close(pf)
    error(string("Teleseism, source region: ", reg, "; pickfile unusable! (use `uwdf` for datafile)"))
  end

  # Error line...mostly pointless crap, left as a string w/limited parses for fast QC
  seekstart(pf)
  eline = nextline(pf,'E')
  if eline != -1
    (D["meanRMS"], D["sdAbout0"], D["sswres"], D["ndfr"], D["fixxyzt"],
    D["sdx"], D["sdy"], D["sdz"], D["sdt"], D["sdmag"], D["meanUncert"]) =
    (eline[12:17], eline[18:23], eline[24:29], eline[30:37], eline[38:41], eline[42:45],
    eline[46:50], eline[51:55], eline[56:60], eline[61:65], eline[66:70], eline[76:79])
    for i in ("meanRMS", "sdAbout0", "sswres", "ndfr", "sdx", "sdy", "sdz",
      "sdt", "sdmag", "meanUncert")
      D[i] = parse(D[i])
    end
  end

  # Alternate magnitude line
  seekstart(pf)
  sline = nextline(pf, 'S')
  if sline != -1
    warn("Alternate magnitude found, M_d overwritten.")
    (mag, mag_typ) = (parse(sline[1:5]), sline(6:8))
  end

  # Focal mechanism line(s)
  seekstart(pf)
  mline = nextline(pf,'M')
  m = 0
  if mline != -1
    D["mech_lines"] = Array{String,1}()
    while mline != -1
      m += 1
      push!(D["mech_lines"], mline)
      mline = nextline(pf,'M')
    end
    v && println("Processed ", m, " focal mechanism lines.")
  end

  # Comment lines
  loc_name = ""
  event_id = 0
  seekstart(pf)
  m = 0
  cline = nextline(pf,'C')
  if cline != -1
    D["comment"] = Array{String,1}()
    while cline != -1
      m += 1
      if contains(cline, "NEAR")
        loc_name = strip(cline[8:end])
      elseif contains(cline, "EVENT ID")
        event_id = parse(Int, strip(cline[13:end]))
      else
        push!(D["comment"], cline[3:end])
      end
      cline = nextline(pf,'C')
    end
    v && println("Processed ", m, " comment lines.")
  end
  H = SeisHdr(time=u2d(ot), lat=lat, lon=lon, dep=dep, mag=mag, mag_typ=mag_typ, loc_name=loc_name, id=event_id)
  if u
    return (pf, H)
  else
    close(pf)
    return (D, H)
  end
end

"""
    D = uwdf(df)

Read University of Washington-format seismic data file `df` into SeisData structure `D`.

    D = uwdf(hf, v=true)

Specify verbose mode (for debugging).
"""
function uwdf(datafile::String; v=false::Bool)
  fname = realpath(datafile)
  dconst = -11676096000
  D = Dict{String,Any}()

  # Open data file
  fid = open(fname, "r")

  # Process master header
  N = bswap(read(fid, Int16))
  skip(fid, 4)
  lmin = bswap(read(fid, Int32))
  lsec = bswap(read(fid, Int32))
  skip(fid, 8)
  flags = [bswap(i) for i in read(fid, Int16, 10)]
  extras = replace(String(read(fid, UInt8, 10)),"\0"," ")
  comment = replace(String(read(fid, UInt8, 80)),"\0"," ")

  # Set M time using lmin and lsec GREGORIAN MINUTES JESUS CHRIST WTF
  uw_ot = lmin*60 + lsec*1.0e-6 + dconst

  # Seek EOF to get number of structures
  seekend(fid)
  skip(fid, -4)
  nstructs = bswap(read(fid, Int32))
  v && println("nstructs=", nstructs)
  structs_os = (-12*nstructs)-4
  tc_os = 0
  v && println("structs_os=", structs_os)

  # Set version of UW seismic data file (char may be empty, leave code as-is!)
  uwformat = extras[3] == '2' ? 2 : 1

  # Read in UW2 data structures
  chno = Array{Int32,1}()
  corr = Array{Int32,1}()
  if uwformat == 2
    seekend(fid)
    skip(fid, structs_os)
    for i1 = 1:1:nstructs
      structtag     = replace(String(read(fid, UInt8, 4)),"\0","")
      nstructs      = bswap(read(fid, Int32))
      byteoffset    = bswap(read(fid, Int32))
      if structtag == "CH2"
        N = nstructs
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
  end
  N = Int64(N)
  v && println("Processing ", N , " channels.")

  # Write time corrections
  timecorr = zeros(Float32, N)
  if length(chno) > 0
    for n = 1:1:length(chno)
      timecorr[chno[n]] = corr[n]*Float32(1.0e-6)
    end
  end

  # Read UW2 channel headers
  if uwformat == 2
    seekend(fid)
    skip(fid, Int(-56*N + structs_os + tc_os))
    f = Array{DataType,1}(N)
    I32 = Array{Int32,2}(6,N)  # chlen, offset, lmin, lsec, fs, expan1
    U8 = Array{UInt8,2}(32,N)  # (8 = 4*int16, unused) + name(8), tmp(4), compflg(4), chid(4)
    for i = 1:1:N
      I32[1:6,i] = read(fid, Int32,  6)
      U8[1:32,i] = read(fid, UInt8, 32)
    end
    I32 = [bswap(i) for i in I32]'
    U8 = U8'

    # Parse I32
    ch_len = I32[:,1]
    ch_os = I32[:,2]
    ch_time = I32[:,3].*60.0 .+ I32[:,4]*1.0e-6 .+ timecorr .+ dconst
    fs = map(Float64, I32[:,5])./1000.0

    # Divide up U8
    sta_u8 = U8[:,09:16]
    fmt_u8 = U8[:,17:20]'
    cha_u8 = U8[:,21:24]

    # Format codes
    c = flipdim(fmt_u8, 1)
    for i = 1:N
      f[i] = Int16
      for j = 1:4
        if c[j,i] == 0x46 # 'F'
          f[i] = Float32
          break
        elseif c[j,i] == 0x4c # 'L'
          f[i] = Int32
          break
        elseif c[j,i] == 0x53 # 'S'
          f[i] = Int16
          break
        end
      end
    end

    s = cat(2, repmat([0x55 0x57 0x2e], N, 1), sta_u8, repmat([0x2e 0x2e], N, 1), cha_u8)'
    id = [replace(String(s[:,i]),"\0","") for i=1:N]
    X = Array{Array{Float64,1},1}(N)
    T = Array{Array{Int64,2},1}(N)
    #println("To read: ", N, " channels")
    for i = 1:1:N
      #println("Channel ", i, ": ", id[i], " (offset =", ch_os[i],", Nx=", ch_len[i], ")")
      seek(fid, ch_os[i])
      X[i] = [bswap(j) for j in read(fid, f[i], ch_len[i])]
      T[i] = [1 round(Int, ch_time[i]*1000000); length(X[i]) 0]
    end
  end
  close(fid)

  src = join(["readuw",timestamp(),fname],',')
  return SeisData(n=N, name=id, id=id, fs=fs, x=X, t=T,
    loc=repmat([zeros(Float64,5)],N),
    resp=repmat([complex(zeros(Float64,2,2))],N),
    misc=[Dict{String,Any}() for i = 1:N],
    notes=[[""] for i = 1:N],
    gain=ones(Float64,N),
    src=repmat([src],N),
    units=repmat(["counts"],N))
end

"""
    S = readuw(f)

Read University of Washington-format seismic data in file `f` into SeisEvent `S`. `f` can be a data file, a pick file, or a stub for one or both.

### Requirements
* A data file must end in 'W'
* A pick file must end in [a-z] and contain exactly one event. Pick files from teleseisms aren't read.
* A filename stub must be complete except for the last letter, e.g. "99062109485".

### Example
    S = readuw("99062109485")

Read data file 99062109485W and pick file 99062109485o in the current working directory.
"""
function readuw(filename::String; v=false::Bool)

  # Identify pickfile and datafile
  filename = realpath(filename)
  pf = ""
  df = ""
  ec = UInt8(filename[end])
  lc = collect(UInt8, 0x61:1:0x7a)
  if Base.in(ec, lc)
    pf = filename
    df = filename[1:end-1]*"W"
  elseif ec == 0x57
    df = filename
    froot = filename[1:end-1]
    pf = getpf(froot, lc)
  else
    df = filename*"W"
    isfile(df) || error("Invalid filename stub (no corresponding data file)!")
    pf = getpf(froot, lc)
  end

  # File read wrappers
  if isfile(df)
    # Datafile wrapper
    v && println("Reading datafile ", df)
    S = SeisEvent(data=uwdf(df, v=v))
    v && println("Done reading data file.")

    # Pickfile wrapper
    if isfile(pf)
      v && println("Reading pickfile ", pf)
      uwpf!(S, pf)
      v && println("Done reading pick file.")
    else
      v && println("Skipping pickfile (not found or not given)")
    end
  else
    # Pickfile only
    S = SeisEvent(hdr=uwpf(pf, v=v))
  end
  return S
end
