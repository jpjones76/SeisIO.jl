export readuw, readuw!, readuwevt, uwdf, uwpf, uwpf!

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

@doc """
    uwpf!(H, f[, v::Int64])

Read UW-format seismic pick info from pickfile `f` into SeisHdr object `S`.
`v` controls verbosity; set `v > 0` to dump verbose debug info. to STDOUT.

    H = uwpf(pf[, v])

Read UW-format seismic pick file `pf` into SeisHdr object `H`.

!!! caution

    Reader does *not* check that `S` and `f` are the same event!
""" uwpf!
function uwpf!(S::SeisEvent, pickfile::String; v::Int64=KW.v)
  setfield!(S, :hdr, uwpf(pickfile, v=v))
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

@doc (@doc uwpf!)
function uwpf(pickfile::String; v::Int64=KW.v)
  pf = open(pickfile, "r")
  seekstart(pf)
  D = Dict{String, Any}()

  # Initialize variables that will fill SeisHdr structure
  LOC = EQLoc()
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
  LOC.dep = Base.parse(Float64, ah[4])
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
  LOC.lat = (Base.parse(Float64, evla[1:3]) + Base.parse(Float64, evla[5:6])/60.0 + Base.parse(Float64, evla[7:8])/6000.0) * (evla[4] == 'S' ? -1.0 : 1.0)
  LOC.lon = (Base.parse(Float64, evlo[1:4]) + Base.parse(Float64, evlo[6:7])/60.0 + Base.parse(Float64, evlo[8:9])/6000.0) * (evlo[5] == 'W' ? -1.0 : 1.0)

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
        try
          D[k] = Base.parse(j == 5 ? Int32 : Float32, s)
        catch
          D[k*"_err"] = s
        end
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
  setfield!(H, :loc, LOC)
  MAG == -5.0f0   || setfield!(H, :mag, (MAG, "M_c (UW)"))
  ID == 0         || setfield!(H, :id, ID)
  OT == 0.0       || setfield!(H, :ot, u2d(OT))
  isempty(D)      || setfield!(H, :misc, D)
  setfield!(H, :src, pickfile)
  return H
end

"""
    D = uwdf(df)

Read University of Washington-format seismic data file `df` into SeisData structure `D`.

    D = uwdf(hf, v=true)

Specify verbose mode (for debugging).
"""
function uwdf(datafile::String;
              v::Int=KW.v,
              full::Bool=KW.full
              )
  fname = realpath(datafile)
  D = Dict{String,Any}()

  # Open data file
  fid = open(fname, "r")

  # Process master header
  N             = Int64(bswap(read(fid, Int16)))
  mast_fs       = bswap(read(fid, Int32))
  mast_lmin     = bswap(read(fid, Int32))
  mast_lsec     = bswap(read(fid, Int32))
  mast_nx       = bswap(read(fid, Int32))
  # mast_tape_no  = bswap(read(fid, Int16))
  # mast_event_no = bswap(read(fid, Int16))
  # flags         = read!(fid, Array{Int16, 1}(undef, 10))
  skip(fid, 24)
  extra         = read(fid, 10)
  skip(fid, 80)

  if v > 2
    println("mast_header:")
    println("N = ", N)
    println("mast_fs = ", mast_fs)
    println("mast_lmin = ", mast_lmin)
    println("mast_lsec = ", mast_lsec)
    println("mast_nx = ", mast_nx)
    println("extra = ", Char.(extra))
  end


  # Set M time with lmin and lsec GREGORIAN MINUTES JESUS CHRIST WTF
  # uw_ot = lmin*60 + lsec*1.0e-6 + uw_dconv

  # Seek EOF to get number of structures
  seekend(fid)
  skip(fid, -4)
  nstructs = bswap(read(fid, Int32))
  v>0 && println(stdout, "nstructs = ", nstructs)
  structs_os = (-12*nstructs)-4
  tc_os = 0
  v>1 && println(stdout, "structs_os = ", structs_os)

  # Set version of UW seismic data file (char may be empty, leave code as-is!)
  uw2::Bool = extra[3] == 0x32 ? true : false
  chno = Array{Int32, 1}(undef, N)
  corr = Array{Int32, 1}(undef, N)

  # Read in UW2 data structures from record end
  if uw2
    seekend(fid)
    skip(fid, structs_os)
    for j = 1:nstructs
      structtag     = read(fid, UInt8)
      skip(fid, 3)
      M             = bswap(read(fid, Int32))
      byteoffset    = bswap(read(fid, Int32))
      if structtag == 0x43 # 'C'
        N = Int64(M)
      elseif structtag == 0x54 # 'T'
        fpos        = position(fid)
        seek(fid, byteoffset)
        chno = Array{Int32, 1}(undef, M)
        corr = Array{Int32, 1}(undef, M)
        n = 0
        @inbounds while n < M
          n += 1
          chno[n]   = read(fid, Int32)
          corr[n]   = read(fid, Int32)
        end
        chno .= (bswap.(chno) .+ 1)
        corr .= bswap.(corr)
        tc_os = -8*M
        seek(fid, fpos)
      end
    end
  end
  v>0 && println(stdout, "Processing ", N , " channels.")

  # Write time corrections
  timecorr = zeros(Int64, N)
  if length(chno) > 0
    for n = 1:N
      # corr is in μs
      timecorr[chno[n]] = Int64(corr[n])
    end
  end

  # Read UW2 channel headers ========================================
  S = SeisData()

  if uw2
    seekend(fid)
    skip(fid, -56*N + structs_os + tc_os)
    I32 = Array{Int32, 2}(undef, 5, N)    # chlen, offset, lmin, lsec (μs), fs, expan1 (unused)
    I16 = Array{Int16, 2}(undef, 3, N)    # lta, trig, bias, fill (unused)
    U8  = Array{UInt8, 2}(undef, 24, N)   # name(8), tmp(4), compflg(4), chid(4), expan2(4)
    i = 0
    @inbounds while i < N
      i += 1
      I32[1,i] = read(fid, Int32)
      I32[2,i] = read(fid, Int32)
      I32[3,i] = read(fid, Int32)
      I32[4,i] = read(fid, Int32)
      I32[5,i] = read(fid, Int32)
      if full == true
        skip(fid, 4)
        I16[1,i] = read(fid, Int16)
        I16[2,i] = read(fid, Int16)
        I16[3,i] = read(fid, Int16)
        skip(fid, 2)
      else
        skip(fid, 12)
      end
      j = 0
      while j < 24
        j += 1
        U8[j,i] = read(fid, UInt8)
      end
    end
    I32 = I32'
    U8 = U8'

    # Parse I32 -------------------------------------------
    I32 .= bswap.(I32)
    ch_len  = view(I32, :, 1)     # "ch_len" is the length in samples of each channel
    ch_os   = view(I32, :, 2)     # "ch_os" is the byte offset of each channel
    lmin    = view(I32, :, 3)     # "lmin" is Gregorian minutes, which we'll correct with uw_dconv
    lsec    = view(I32, :, 4)     # "lsec" is in μs
    fs      = view(I32, :, 5)     # "fs" is in [1/1000 seconds], not Hz!

    # old time conversions
    # ch_time = (I32[:,3].*60.0 .+ I32[:,4]*1.0e-6 .+ timecorr .+ uw_dconv)
    # setindex!(t, round(Int64, ch_time[i]*1000000), 3)
    ch_time = lsec .+ 1000000*Int64.(lmin*60) .+ timecorr .+ uw_dconv

    # Parse I16 -------------------------------------------
    if full == true
      I16 = I16'
      I16 .= bswap.(I16)
    end

    # Parse U8 --------------------------------------------
    # cols 01:08    channel name
    # cols 09:12    format code
    # cols 13:16    compflg(4)
    # cols 17:20    chid
    # cols 21:24    expan2
    if full == true
      U8[U8.==0x00] .= 0x20
    end
    sta_u8  = view(U8, :, 1:8)
    fmt_u8  = view(U8, :, 9)
    cha_u8  = view(U8, :, 13:16)
    chid    = view(U8, :, 17:20)
    expan2  = view(U8, :, 21:24)

    seek(fid, ch_os[1])
    buf = getfield(BUF, :buf)
    checkbuf!(buf, 4*maximum(ch_len))
    id = zeros(UInt8, 15)
    i = 0
    os = 0
    @inbounds while i < N
      i += 1
      skip(fid, os)
      nx = getindex(ch_len, i)

      # Generate ID
      fill!(id, 0x00)
      id[1] = 0x55
      id[2] = 0x57
      id[3] = 0x2e
      id[12] = 0x2e
      fill_id!(id, sta_u8[i,:], 1, 8, 4, 8)
      fill_id!(id, cha_u8[i,:], 1, 4, 13, 15)
      id_str = String(id[id.!=0x00])

      # Save to SeisChannel
      C = SeisChannel()
      setfield!(C, :id, id_str)
      setfield!(C, :fs, Float64(getindex(fs, i))*1.0e-3)
      setfield!(C, :units, "m/s")
      setfield!(C, :src, fname)
      if full == true
        D = getfield(C, :misc)
        D["lta"]    = I16[i,1]
        D["trig"]   = I16[i,2]
        D["bias"]   = I16[i,3]
        D["chid"]   = String(chid[i,:])
        D["expan2"] = String(expan2[i,:])
        if i == 1
          D["mast_fs"]    = mast_fs*1.0f-3
          D["mast_lmin"]  = mast_lmin
          D["mast_lsec"]  = mast_lsec
          D["mast_nx"]    = mast_nx
          D["extra"]     = String(extra)

          # Go back to master header; grab what we skipped
          p = position(fid)
          seek(fid, 18)         # we have the first few fields already
          D["mast_tape_no"]   = bswap(read(fid, Int16))
          D["mast_event_no"]  = bswap(read(fid, Int16))
          D["flags"]          = bswap.(read!(fid, Array{Int16, 1}(undef, 10)))
          skip(fid, 10)         # we have "extra" already
          comment             = read(fid,80)
          D["comment"] = String(comment[comment.!=0x00])

          # Return to where we were
          seek(fid, p)
        end
      end

      # Generate T
      t = Array{Int64,2}(undef,2,2)
      setindex!(t, one(Int64), 1)
      setindex!(t, nx, 2)
      setindex!(t, ch_time[i], 3)
      setindex!(t, zero(Int64), 4)
      setfield!(C, :t, t)

      # Generate X
      x = Array{Float32,1}(undef, nx)
      if fmt_u8[i] == 0x53
        readbytes!(fid, buf, 2*nx)
        fillx_i16_be!(x, buf, nx, 0)
      elseif fmt_u8[i] == 0x4c
        readbytes!(fid, buf, 4*nx)
        fillx_i32_be!(x, buf, nx, 0)
      else
        readbytes!(fid, buf, 4*nx)
        x .= bswap.(reinterpret(Float32, buf))[1:nx]
      end
      setfield!(C, :x, x)

      # Push to SeisData
      push!(S,C)

      if i < N
        os = getindex(ch_os, i+1) - position(fid)
      end
    end
    note!(S, string("+src: readuw(", fname, ")"))
  end
  close(fid)
  return S
end

@doc """
    Ev = readuwevt(fpat)

Read University of Washington-format event data with file pattern stub `fpat`
into SeisEvent `Ev`. `fstub` can be a datafile name, a pickname, or a stub:
* A datafile name must end in 'W'
* A pickfile name must end in a lowercase letter (a-z except w) and should
describe a single event.
* A filename stub must be complete except for the last letter, e.g. "99062109485".
* Wild cards for multi-file read are not supported by `readuw` because the
data format is strictly an event-oriented design.
""" readuwevt
function readuwevt(filename::String; v::Int64=KW.v)

  df = String("")
  # Identify pickfile and datafile
  filename = Sys.iswindows() ? realpath(filename) : relpath(filename)
  pf = String("")
  ec = UInt8(filename[end])
  lc = vcat(collect(UInt8, 0x61:0x76), 0x78, 0x79, 0x7a) # skip 'w'
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
    Ev = SeisEvent(data = convert(EventTraceData, uwdf(df, v=v, full=true)))
    v>0 && println(stdout, "Done reading data file.")

    # Pickfile wrapper
    if safe_isfile(pf)
      v>0 && println(stdout, "Reading pickfile ", pf)
      uwpf!(Ev, pf)
      v>0 && println(stdout, "Done reading pick file.")

      # Move event keys to event header dict
      klist = ("extra", "flags", "mast_event_no", "mast_fs", "mast_lmin", "mast_lsec", "mast_nx", "mast_tape_no")
      D_data = getindex(getfield(Ev.data, :misc), 1)
      D_hdr = getfield(Ev.hdr, :misc)
      for k in klist
        D_hdr[k] = D_data[k]
        delete!(D_data, k)
      end
      D_hdr["comment_df"] = D_data["comment"]
      delete!(D_data, "comment")
    else
      v>0 && println(stdout, "Skipping pickfile (not found or not given)")
    end
  else
    # Pickfile only*
    Ev = SeisEvent(hdr = uwpf(pf, v=v))
  end

  return Ev
end

@doc """
    readuw!(S::SeisData, dfpat)

Read University of Washington-format seismic data files matching file pattern
`dfpat` into SeisData structure S. This syntax supports wildcards.

    S = readuw(dfpat)

As above, but creates a new SeisData object.
""" readuw
function readuw!(S::SeisData, filestr::String;
                  v::Int64=KW.v,
                  full::Bool=KW.full)

  if safe_isfile(filestr)
    append!(S, uwdf(filestr, v=v, full=full))
  else
    files = ls(filestr)
    nf = length(files)
    for fname in files
      append!(S, uwdf(fname, v=v))
    end
  end
  return nothing
end

@doc (@doc readuw)
function readuw(filestr::String;
                v::Int64=KW.v,
                full::Bool=KW.full)
  S = SeisData()
  readuw!(S, filestr, v=v, full=full)
  return S
end
