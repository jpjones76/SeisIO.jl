"""
    seis = batch_read(FILESTR)

Batch read all SAC files matching string FILESTR. **All files matching FILESTR
must contain data from the same channel**.

    seis = batch_read(FILESTR, ftype="NMT")

Batch read all SEGY (PASSCAL) files matching string FILESTR. **All files matching
FILESTR must contain data from the same channel**.

FILESTR supports wildcard filenames, but not directories. Thus,
`batch_read("/data/PALM_EHZ_CC/2015.16*SAC")` will read all files in
/data/PALM_EHZ_CC/ that begin with "2015.16" and end with "SAC". However,
`batch_read("/data2/Hood/*/2015.16*SAC")` will result in an error.

    seis = batch_read(FILES, ftype=FTYPE, fs=FS)

Batch read and resample to FS Hz.
"""
function batch_read(files::Array{String,1}; ftype="SAC"::String, fs=0.0::Float64)
  NF = length(files)

  # Parallelize file info read into shared arrays
  ts = SharedArray(Int64, (NF,))
  nx = SharedArray(Int32, (NF,))
  rr = SharedArray(Float32, (NF,))
  gain = SharedArray(Float32, (NF,))
  loc = SharedArray(Float32, (NF,5))

  if ftype == "SAC"
    fmt = Array{Type,1}(collect(repeated(Float32, NF)))
    id = getsach(files, ts, nx, gain, loc, rr)
    os = 632
  elseif ftype == "NMT" || ftype == "PASSCAL"
    (id, fmt) = getsegh(files, ts, nx, gain, loc, rr)
    os = 240
  end

  # Check fs to see whether we resample
  if fs == 0.0
    dt = rr[1]
    fs = Float32(1/dt)
  else
    dt = Float32(1/fs)
  end
  DT = round(Int, dt*1.0e6)

  OS = Array{Int64,1}(collect(repeated(os, NF)))
  NN = ceil(Int, nx.*rr./dt)
  ei = cumsum(NN)
  si = convert(SharedArray{Int64,1}, [0; ei[1:end-1]])
  ll = ei[end]

  # Shared arrays
  xx = SharedArray(Float64, (ll,))
  tt = SharedArray(Int64, (ll,))

  # Parallel read into shared array
  rr = convert(SharedArray{Float64,1}, map(Int64, rr.*1.0e6) ./ DT)
  par_read(files, nx, rr, si, fmt, gain, ts, DT, os, tt, xx)

  # loop over each unique ID
  uid = unique(id)
  S = SeisData()
  for u in uid
    j = find(u .== id)

    # Preallocate t1, x1
    ll = sum(nx[j])
    t1 = zeros(Int64, ll)
    x1 = zeros(Float64, ll)
    chan_loc = zeros(5)

    ii = sortperm(ts[j])
    ij = j[ii]
    ss = 0
    for i in ij
      for k = 1:5
        if loc[i,k] != 0
          chan_loc[k] = loc[i,k]
        end
      end
      en = ei[i]
      st = si[i]
      lx = NN[i]
      t1[ss+1:ss+lx] = tt[st+1:en]
      x1[ss+1:ss+lx] = xx[st+1:en]
      ss += lx
    end

    # Remove null entries
    k = find(t1.==0)
    if !isempty(k)
      deleteat!(t1,k)
      deleteat!(x1,k)
    end

    # Rearrange and prune T, X
    xtjoin!((t1,x1), div(DT, 2))

    # Reassign, collapse to sparse, done.
    S += SeisObj(id=u, name=u, t=t_collapse(t1, fs), x=x1, src=ftype, fs=fs, loc=chan_loc)
  end
  return S
end
batch_read(filestr::String; ftype="SAC"::String, fs=0.0::Float64) = batch_read(lsw(filestr), ftype=ftype, fs = fs)
# batch_read(files::Array{String,1}; ftype="SAC"::String, fs=0.0::Float64) = (
#   tmp = convert(Array{String,1}, [bytestring(f) for f in files]);
#   batch_read(tmp, ftype=ftype, fs=fs))

# =============================================================================
function segy_geth(j::Int64,
  fname::String,
  ts::SharedArray{Int64,1},
  nx::SharedArray{Int32,1},
  gain::SharedArray{Float32,1},
  loc::SharedArray{Float32,2},
  rr::SharedArray{Float32,1})

  # SEGY data format was organized via. "shuffle" button
  f = open(fname, "r")
  seek(f, 12)
  chanN = read(f, Int32)
  seek(f, 52)
  ele = read(f, Float32)
  seek(f, 68)
  sc = read(f, Int16, 2)
  loc[j, 3] = ele*sc[1]
  skip(f, 8)
  loc[j,2] = read(f, Float32)*sc[2]
  loc[j,1] = read(f, Float32)*sc[2]
  seek(f, 102)
  vals = read(f, Int16, 9)
  seek(f, 156)
  ti = read(f, Int16, 5)
  seek(f, 180)
  sta = strip(ascii(read(f, UInt8, 6)),['\0', '\ '])
  skip(f, 8)
  cmp = strip(ascii(read(f, UInt8, 4)),['\0', '\ '])
  skip(f, 2)
  samp_rate = 1.0f6/read(f, Int32)
  fk  = read(f, Int16)
  fmt = fk == 0 ? Int16 : Int32
  ms  = read(f, Int16)
  seek(f, 220)
  scale_fac = read(f, Float32)
  skip(f, 4)
  npts = read(f, Int32)
  close(f)

  rr[j] = (vals[8] == 1 ? samp_rate : vals[8])*1.0f-6                       # fs
  if (isempty(cmp) || cmp == "NC")
    cmp = "YYY"
    lll = @sprintf("%02i",chanN)
  elseif cmp in ["Z","N","E"]
    cmp = string(getbandcode(1/rr[j]),'H',cmp[1])
    lll = ""
  else
    lll = ""
  end
  id   = join(["",sta,lll,cmp],'.')

  nx[j] = vals[7] == 32767 ? npts : vals[7]                                 # nx
  gain[j] = (scale_fac > 0 && vals[9] > 0) ? (scale_fac / vals[9]) : 1.0f0  # gain
  (m,d) = j2md(ti[1],ti[2])
  ts[j] = round(Int, d2u(DateTime(ti[1],m,d,ti[3],ti[4],ti[5]))*1.0e6
    + (ms+sum(vals[1:4]))*1000)                                             # t
  return (id,fmt)
end
# =============================================================================

function sac_geth(j::Int64, fname::String,
  ts::SharedArray{Int64,1},
  nx::SharedArray{Int32,1},
  gain::SharedArray{Float32,1},
  loc::SharedArray{Float32,2},
  rr::SharedArray{Float32,1})

  f = open(fname, "r")
  fv = read(f, Float32, 70)
  iv = read(f, Int32, 40)
  cv = read(f, UInt8, 176)
  close(f)

  # Parse chars
  sta = replace(strip(ascii(cv[1 : 8])),"\0","")
  cmp = replace(strip(ascii(cv[161 : 168])),"\0","")
  net = replace(strip(ascii(cv[169 : 176])),"\0","")
  id = join([sta,net,"",cmp],'.')

  # Parse floats
  rr[j] = fv[1]
  gain[j] = fv[4] == -12345.0f0 ? 1.0f0 : fv[4]
  for (i,v) in enumerate([32, 33, 34, 58, 59])
    if fv[v] != -12345.0f0
      loc[j,i] = fv[v]
    end
  end

  # Parse ints
  nx[j] = iv[10]
  (m,d) = j2md(iv[1],iv[2])
  ts[j] = round(Int, d2u(DateTime(iv[1],m,d,iv[3],iv[4],iv[5]))*1.0e6
            + (iv[6]*1000) + (fv[6] == -12345.0 ? 0.0 : fv[6])*1000)
  return id
end

# =============================================================================
function read_bat(j::Int64, fname::String, DT::Int64, os::Int64,
  fmt::Type,
  si::SharedArray{Int64,1},
  nx::SharedArray{Int32,1},
  rr::SharedArray{Float64,1},
  gain::SharedArray{Float32,1},
  ts::SharedArray{Int64,1},
  tt::SharedArray{Int64,1},
  xx::SharedArray{Float64,1})

    f = open(fname,"r")
    seek(f, os)
    x = map(Float64, read(f, fmt, nx[j])).*gain[j]
    close(f)
    r = rr[j]
    if !isapprox(r, 1.0)
      x = resample(x, r)
    end

    lx = length(x)
    i = si[j]
    xx[i+1:i+lx] = x
    tt[i+1:i+lx] = cumsum([ts[j]; collect(repeated(DT, lx-1))])
    return
  end

function getsach(
  files::Array{String,1},
  ts::SharedArray{Int64,1},
  nx::SharedArray{Int32,1},
  gain::SharedArray{Float32,1},
  loc::SharedArray{Float32,2},
  rr::SharedArray{Float32,1})
  np = nprocs()
  n = length(files)
  i = 1
  nextj() = (j=i; i+=1; j)    # Next index
  id = Array{String,1}(n)
  @sync begin
    for p=1:np
      if p != myid() || np == 1
        @async begin
          while true
            j = nextj()
            if j > n
              return
            end
            id[j] = remotecall_fetch(sac_geth, p, j, files[j], ts, nx, gain, loc, rr)
          end
        end
      end
    end
  end
  id
end

function par_read(
  files::Array{String,1},
  nx::SharedArray{Int32,1},
  rr::SharedArray{Float64,1},
  si::SharedArray{Int64,1},
  fmt::Array{Type,1},
  gain::SharedArray{Float32,1},
  ts::SharedArray{Int64,1},
  DT::Int64,
  os::Int64,
  tt::SharedArray{Int64,1},
  xx::SharedArray{Float64,1})
  #files, nx, rr, si, fmt, gain, ts, DT, os, tt, xx)
  np = nprocs()
  n = length(files)
  i = 1
  nextj() = (j=i; i+=1; j)    # Next index
  @sync begin
    for p=1:np
      if p != myid() || np == 1
        @async begin
          while true
            j = nextj()
            if j > n
              return
            end
            remotecall_fetch(read_bat, p, j, files[j], DT, os, fmt[j], si, nx, rr, gain, ts, tt, xx)
          end
        end
      end
    end
  end
end

function getsegh(
  files::Array{String,1},
  ts::SharedArray{Int64,1},
  nx::SharedArray{Int32,1},
  gain::SharedArray{Float32,1},
  loc::SharedArray{Float32,2},
  rr::SharedArray{Float32,1})
  np = nprocs()
  n = length(files)
  ftype = Array{Type,1}(n)
  id = Array{String,1}(n)
  i = 1
  nextj() = (j=i; i+=1; j)    # Next index
  @sync begin
    for p=1:np
      if p != myid() || np == 1
        @async begin
          while true
            j = nextj()
            if j > n
              break
            end
            (id[j], ftype[j]) = remotecall_fetch(segy_geth, p, j, files[j], ts, nx, gain, loc, rr)
          end
        end
      end
    end
  end
  return (id, ftype)
end
