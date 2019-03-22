export readuw, uwdf, uwpf, uwpf!

# ============================================================================
# Utility functions not for export
function nextline(pf::IO, c::Char)
    eof(pf) && return "-1"
    s = "\0"
    while s[1] != c
        eof(pf) && return "-1"
        s = chomp(readline(pf))
    end
    return s
end

function getpf(froot::String, lc::Array{UInt8,1})
  for i in lc
    p = string(froot, Char(i))
    if safe_isfile(p)
      return p
    end
  end
  return froot*"\0"
end
# ============================================================================

"""
    uwpf!(S, f)

Read University of Washington-format seismic pick info from pickfile `f` into header of SeisEvent `S`.

*Caution*: Low-level reader. *No* sanity checks are done to ensure `S` and `f` are the same event!
"""
function uwpf!(S::SeisEvent, pickfile::String; v=0::Int)
  setfield!(S, :hdr, uwpf(pickfile, v))
  N = S.data.n

  # Pick lines (requires reopening/rereading file)
  pf = open(pickfile, "r")
  m = 0
  pline = nextline(pf,'.')
  v>2 && println(stdout, pline)
  while pline != "-1"
    m += 1
    sta = pline[2:4]
    cmp = pline[6:8]
    for j = 1:N
      if occursin(sta, S.data.id[j]) && occursin(cmp, S.data.id[j])
        p = something(findfirst("(P P", pline), 0:-1) #search(pline, "(P P")
        if !isempty(p)
          pl = split(pline[p[1]:end])
          S.data.misc[j]["p_pol"] = pl[3]
          S.data.misc[j]["t_p"] = [Meta.parse(pl[4]), Meta.parse(pl[5]), Meta.parse(pl[6]), Meta.parse(pl[7][1:end-1])]
        end
        s = something(findfirst("(P S", pline), 0:-1) #search(pline, "(P S")
        if !isempty(s)
          pl = split(pline[s[1]:end])
          S.data.misc[j]["s_pol"] = pl[3]
          S.data.misc[j]["t_s"] = [Meta.parse(pl[4]), Meta.parse(pl[5]), Meta.parse(pl[6]), Meta.parse(pl[7][1:end-1])]
        end
        d = something(findfirst("(D", pline), 0:-1) #search(pline, "(D")
        if !isempty(d)
          pl = split(pline[d[1]:end])
          S.data.misc[j]["t_d"] = Meta.parse(pl[2][1:end-1])
        end
      end
    end
    pline = nextline(pf,'.')
  end
  v>0 && println(stdout, "Processed ", m, " pick lines.")
  close(pf)

  return S
end

"""
    H = uwpf(pf, v::Int)

Read University of Washington-format seismic pick file `pf` into SeisHdr struct `H`. `v` controls verbosity; set `v > 0` to dump verbose debug info. to STDOUT.

"""
function uwpf(pickfile::String, v::Int)
  pf = open(pickfile, "r")
  seekstart(pf)
  D = Dict{String, Any}()

  # Initialize variables that will fill SeisHdr structure
  LOC = Array{Float64, 1}(undef, 3); LOC[1:3] .= NaN;
  MAG = -5.0f0
  ID = zero(Int64)
  OT = zero(Float64)

  # Read begins --------------------------------------------------------------
  A = nextline(pf, 'A')
  (v > 1)  && println(stdout, A)
  c = 0
  if length(A) == 75 || length(A) == 12
    y = zero(Int8)
    c = 1900
  else
    y = Int8(2)
  end
  D["type"] = A[2]

  # Start time
  OT = d2u(DateTime(string(Base.parse(Int64, A[3:4+y]) + c)*A[5+y:12+y], "yyyymmddHHMM"))

  si = Int8[13, 19, 27, 36, 42, 43, 47, 51, 54, 58, 61, 66, 71, 74] .+ y
  ei = Int8[18, 26, 35, 41, 42, 46, 49, 53, 57, 60, 65, 70, 72, 75] .+ y
  L = length(si)

  # Parse reset of Acard line
  ah = String[A[si[i]:ei[i]] for i = 1:L]

  # origin time, event depth, and magnitude
  OT += Base.parse(Float64, ah[1])
  LOC[3] = Base.parse(Float64, ah[4])
  MAG = Base.parse(Float32, ah[6])

  # record whether depth is fixed
  D["fixdepth"] = ah[5] == "F" ? true : false

  # Keep these as strings; we'll convert them below
  evla = ah[2]
  evlo = ah[3]

  # Rest become dictionary entries
  aline_keys = String["numsta", "numpha", "gap", "dmin", "rms", "err", "qual", "vmod"]
  for (j, k) in enumerate(aline_keys)
      if j < 3
          D[k] = Base.parse(Int32, ah[j+6])
      elseif j > 6
          D[k] = ah[j+6]
      else
          D[k] = Base.parse(Float32, ah[j+6])
      end
  end

  # Convert lat and lon to decimal degrees
  LOC[1] = (Base.parse(Float64, evla[1:3]) + Base.parse(Float64, evla[5:6])/60.0 + Base.parse(Float64, evla[7:8])/6000.0) * (evla[4] == 'S' ? -1.0 : 1.0)
  LOC[2] = (Base.parse(Float64, evlo[1:4]) + Base.parse(Float64, evlo[6:7])/60.0 + Base.parse(Float64, evlo[8:9])/6000.0) * (evlo[5] == 'W' ? -1.0 : 1.0)

  # Error line
  seekstart(pf)
  eline = nextline(pf, 'E')
  if eline != "-1"
    # Effectively: 10x MeanRMS SDabout0 SDaboutMean SSWRES NDFR FIXXYZT SDx  SDy  SDz  SDt  Mag  5x MeanUncert
    #              10x f6.3    f6.3     f6.3        f8.2   i4   a4      f5.2 f5.2 f5.2 f5.2 f5.2 5x f4.2
    eline_keys = String["MeanRMS", "SDabout0", "SDaboutMean", "SSWRES", "NDFR", "FIXXYZT", "SDx", "SDy", "SDz", "SDt", "Mag", "MeanUncert"]
    si =           Int8[       11,         17,            23,       29,     37,        42,    46,     51,    56,   61,    66,           76]
    ei =           Int8[       16,         22,            28,       36,     40,        45,    50,     55,    60,   65,    70,           79]
    for (j, k) in enumerate(eline_keys)
      s = strip(eline[si[j]:ei[j]])
      if k == "FIXXYZT"
        D[k] = s
      elseif !isempty(s)
          D[k] = Base.parse(j == 5 ? Int32 : Float32, s)
      end
    end
  end

  # Focal mechanism line(s)
  seekstart(pf)
  mline = nextline(pf,'M')
  m = 0
  if mline != "-1"
      D["mech_lines"] = Array{String, 1}(undef, 0)
      while mline != "-1"
          m += 1
          push!(D["mech_lines"], mline)
          mline = nextline(pf,'M')
      end
      v>0 && println(stdout, "Processed ", m, " focal mechanism lines.")
  end

  # Comment lines
  seekstart(pf)
  m = 0
  cline = nextline(pf,'C')
  if cline != "-1"
      D["comment"] = Array{String, 1}(undef, 0)
      while cline != "-1"
          m += 1
          if occursin("NEAR", cline)
              D["loc_name"] = strip(cline[8:end])
          elseif occursin("EVENT ID", cline)
              ID = Base.parse(Int64, strip(cline[13:end]))
          else
              push!(D["comment"], cline[3:end])
          end
          cline = nextline(pf,'C')
      end
      v>0 && println(stdout, "Processed ", m, " comment lines.")
  end

  # Done reading
  close(pf)

  # Create SeisHdr struct
  H = SeisHdr()
  isnan(LOC[1]) || setfield!(H, :loc, LOC)
  MAG == -5.0f0 || setfield!(H, :mag, (MAG, "M_c (UW)"))
  ID == 0       || setfield!(H, :id, ID)
  OT == 0.0     || setfield!(H, :ot, u2d(OT))
  isempty(D)    || setfield!(H, :misc, D)
  setfield!(H, :src, pickfile)
  return H
end

"""
    D = uwdf(df)

Read University of Washington-format seismic data file `df` into SeisData structure `D`.

    D = uwdf(hf, v=true)

Specify verbose mode (for debugging).
"""
function uwdf(datafile::String; v=0::Int)
  fname = realpath(datafile)
  D = Dict{String,Any}()

  # Open data file
  fid = open(fname, "r")

  # Process master header
  N = bswap(read(fid, Int16))
  skip(fid, 4)
  lmin = bswap(read(fid, Int32))
  lsec = bswap(read(fid, Int32))
  skip(fid, 8)
  flags = [bswap(i) for i in read!(fid, Array{Int16, 1}(undef, 10))]
  extras = replace(String(read!(fid, Array{UInt8, 1}(undef, 10))), "\0" => " ")
  comment = replace(String(read!(fid, Array{UInt8, 1}(undef, 80))), "\0" => " ")

  # Set M time with lmin and lsec GREGORIAN MINUTES JESUS CHRIST WTF
  # uw_ot = lmin*60 + lsec*1.0e-6 + uw_dconv

  # Seek EOF to get number of structures
  seekend(fid)
  skip(fid, -4)
  nstructs = bswap(read(fid, Int32))
  v>0 && println(stdout, "nstructs=", nstructs)
  structs_os = (-12*nstructs)-4
  tc_os = 0
  v>0 && println(stdout, "structs_os=", structs_os)

  # Set version of UW seismic data file (char may be empty, leave code as-is!)
  uwformat = extras[3] == '2' ? 2 : 1

  # Read in UW2 data structures
  chno = Array{Int32, 1}(undef, 0)
  corr = Array{Int32, 1}(undef, 0)
  if uwformat == 2
    seekend(fid)
    skip(fid, structs_os)
    for i1 = 1:nstructs
      structtag     = replace(String(read!(fid, Array{UInt8, 1}(undef, 4))), "\0" => "")
      nstructs      = bswap(read(fid, Int32))
      byteoffset    = bswap(read(fid, Int32))
      if structtag == "CH2"
        N = nstructs
      elseif structtag == "TC2"
        fpos = position(fid)
        seek(fid, byteoffset)
        for n = 1:nstructs
          push!(chno, read(fid, Int32))
          push!(corr, read(fid, Int32))
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
  v>0 && println(stdout, "Processing ", N , " channels.")

  # Write time corrections
  timecorr = zeros(Float32, N)
  if length(chno) > 0
    for n = 1:length(chno)
      timecorr[chno[n]] = corr[n]*Float32(1.0e-6)
    end
  end

  # Read UW2 channel headers
  if uwformat == 2
    seekend(fid)
    skip(fid, Int(-56*N + structs_os + tc_os))
    f = Array{DataType, 1}(undef, N)
    I32 = Array{Int32, 2}(undef, 6, N)  # chlen, offset, lmin, lsec, fs, expan1
    U8 = Array{UInt8, 2}(undef, 32, N)  # (8 = 4*int16, unused) + name(8), tmp(4), compflg(4), chid(4)
    for i = 1:N
      I32[1:6,i] = read!(fid, Array{Int32,1}(undef, 6))
      U8[1:32,i] = read!(fid, Array{UInt8,1}(undef, 32))
    end
    I32 = [bswap(i) for i in I32]'
    U8 = U8'

    # Parse I32
    ch_len = I32[:,1]
    ch_os = I32[:,2]
    ch_time = I32[:,3].*60.0 .+ I32[:,4]*1.0e-6 .+ timecorr .+ uw_dconv
    fs = map(Float64, I32[:,5])./1000.0

    # Divide up U8
    sta_u8 = U8[:,09:16]
    fmt_u8 = U8[:,17:20]'
    cha_u8 = U8[:,21:24]

    # Format codes
    c = reverse(fmt_u8, dims=1)
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

    s = cat(repeat([0x55 0x57 0x2e], N, 1), sta_u8, repeat([0x2e 0x2e], N, 1), cha_u8, dims=2)'
    id = [replace(String(s[:,i]), "\0" => "") for i = 1:N]
    X = Array{Union{Array{Float32,1}, Array{Float64,1}},1}(undef, N)
    T = Array{Array{Int64, 2}, 1}(undef, N)
    for i = 1:N
      seek(fid, ch_os[i])
      X[i] = Float32[bswap(j) for j in read!(fid, Array{f[i], 1}(undef, ch_len[i]))]
      T[i] = Int64[1 round(Int64, ch_time[i]*1000000); length(X[i]) 0]
    end
  end
  close(fid)

  S = SeisData(N)
  setfield!(S, :name, id)
  setfield!(S, :id, id)
  setfield!(S, :fs, fs)
  setfield!(S, :x, X)
  setfield!(S, :t, T)
  setfield!(S, :src, repeat([fname], N))
  setfield!(S, :units, repeat(["counts"], N))
  note!(S, string("+src: readuw ", fname))
  return S
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
function readuw(filename::String; v=0::Int)

  # Identify pickfile and datafile
  filename = Sys.iswindows() ? realpath(filename) : relpath(filename)
  pf = String("")
  df = String("")
  ec = UInt8(filename[end])
  lc = collect(UInt8, 0x61:0x7a)
  if Base.in(ec, lc)
    pf = filename
    df = filename[1:end-1]*"W"
  elseif ec == 0x57
    df = filename
    pf = getpf(filename[1:end-1], lc)
  else
    df = filename*"W"
    safe_isfile(df) || error("Invalid filename stub (no corresponding data file)!")
    pf = getpf(filename, lc)
  end

  # File read wrappers
  if safe_isfile(df)
    # Datafile wrapper
    v>0 && println(stdout, "Reading datafile ", df)
    S = SeisEvent(data=uwdf(df, v=v))
    v>0 && println(stdout, "Done reading data file.")

    # Pickfile wrapper
    if safe_isfile(pf)
      v>0 && println(stdout, "Reading pickfile ", pf)
      uwpf!(S, pf)
      v>0 && println(stdout, "Done reading pick file.")
    else
      v>0 && println(stdout, "Skipping pickfile (not found or not given)")
    end
  else
    # Pickfile only
    S = SeisEvent(hdr=uwpf(pf, v))
  end
  return S
end
