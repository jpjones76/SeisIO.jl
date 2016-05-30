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
function batch_read(files::Array{ByteString,1}; ftype="SAC"::ASCIIString, fs=0.0::Float64)
  file0 = files[1]
  files = files[2:end]
  NF = length(files)

  if ftype == "SAC"
    S = readsac(ascii(file0))
  elseif ftype == "NMT" || ftype == "PASSCAL"
    S = readsegy(ascii(file0), f="nmt")
  else
    error(@sprintf("File format %s not yet supported", ftype))
  end
  isempty(files) && return(S)

  # Check fs to see whether we resample
  if fs == 0.0
    fs = S.fs
  else
    if S.fs != fs
      S.x = resample(S.x, fs/S.fs)
      S.fs = fs
    end
  end
  dt = 1/fs

  # Parallelize file read into a shared array
  DT = Array{Int64,1}(collect(repeated(round(Int, dt*1.0e6),NF)))
  ts = Array{Int64,1}(NF)
  nx = Array{Int64,1}(NF)
  rr = Array{Float64,1}(NF)
  gain = Array{Float64,1}(NF)

  if ftype == "SAC"
    fmt = Array{Type,1}(collect(repeated(Float32, NF)))
    for i = 1:NF
      (ts[i], nx[i], gain[i], rr[i]) = sac_geth(files[i])
    end
    os = 632
  elseif ftype == "NMT" || ftype == "PASSCAL"
    fmt = Array{Type,1}(NF)
    for i = 1:NF
      (ts[i], nx[i], fmt[i], gain[i], rr[i]) = segy_geth(files[i])
    end
    os = 240
  end

  # Indices and counters
  OS = Array{Int64,1}(collect(repeated(os, NF)))
  rr ./= dt
  lx = length(S.x)
  NN = ceil(Int, nx.*rr)
  ei = lx + cumsum(NN)
  si = [lx; ei[1:end-1]]
  ll = ei[end]

  # Shared arrays
  xx = SharedArray(Float64, (ll,))
  tt = SharedArray(Int64, (ll,))

  # Place data from first file
  xx[1:lx] = S.x
  tt[1:lx] = S.t[1,2] .+ cumsum(collect(repeated(DT[1], lx)))

  # Parallel read into shared array
  pmap(read_bat_1, files, nx, rr, si, fmt, gain, ts,
    DT, OS, collect(repeated(tt, NF)), collect(repeated(xx, NF)))

  # Rearrange and prune T, X
  t1 = sdata(tt)
  i = sortperm(t1)
  t1 = t1[i]
  x1 = sdata(xx)[i]
  j = find(t1.==0)
  if !isempty(j)
    deleteat!(t1,j)
    deleteat!(x1,j)
  end
  half_samp = round(Int, 0.5*DT[1])
  xtjoin!((t1,x1), half_samp)

  # Reassign, collapse to sparse, done.
  S.t = t_collapse(t1, fs)
  S.x = x1
  return S
end
batch_read(filestr::ASCIIString; ftype=ftype::ASCIIString, fs=0.0::Float64) = batch_read(lsw(filestr), ftype=ftype, fs = fs)
# =============================================================================

function segy_geth(fname::ByteString)
  f = open(fname, "r")
  seek(f, 102)
  vals = read(f, Int16, 9)
  seek(f, 156)
  ti = read(f, Int16, 5)
  seek(f, 200)
  samp_rate = 1.0e6/read(f, Int32)
  fk  = read(f, Int16)
  fmt = fk == 0 ? Int16 : Int32
  ms  = read(f, Int16)
  seek(f, 220)
  scale_fac = read(f, Float32)
  skip(f, 4)
  npts = read(f, Int32)
  close(f)
  nx = Int64(vals[7] == 32767 ? npts : vals[7])                             # nx
  g = Float64((scale_fac > 0 && vals[9] > 0) ? (scale_fac / vals[9]) : 1.0) # gain
  dt = Float64((vals[8] == 1 ? samp_rate : vals[8])*1.0e-6)                 # fs
  (m,d) = j2md(ti[1],ti[2])
  t = round(Int, d2u(DateTime(ti[1],m,d,ti[3],ti[4],ti[5]))*1.0e6
    + (ms+sum(vals[1:4]))*1000)                                             # t
  return (t, nx, fmt, g, dt)
end
# =============================================================================

function sac_geth(fname::ByteString)
  f = open(fname, "r")
  fv = read(f, Float32, 70)
  iv = read(f, Int32, 16)
  g = Float64(fv[4] == -12345.0f0 ? 1.0 : fv[4])
  (m,d) = j2md(iv[1],iv[2])
  t = round(Int, d2u(DateTime(iv[1],m,d,iv[3],iv[4],iv[5]))*1.0e6
    + (iv[6]*1000) + (fv[6] == -12345.0 ? 0.0 : fv[6])*1000)
  close(f)
  return (t, Int64(iv[10]), g, Float64(fv[1]))
end

# =============================================================================
function read_bat_1(fname::ByteString, nx::Int64, rr::Float64, i::Int64,
  fmt::Type, gain::Float64, ts::Int64, dt::Int64, os::Int64, tt::SharedArray{Int64,1},
  xx::SharedArray)
  f = open(fname,"r")
  seek(f, os)
  x = map(Float64, read(f, fmt, nx)).*gain
  close(f)
  if !isapprox(rr, 1.0)
    x = resample(x, rr)
  end
  lx = length(x)
  xx[i+1:i+lx] = x
  tt[i+1:i+lx] = cumsum([ts; collect(repeated(dt, lx-1))])
  return
end
