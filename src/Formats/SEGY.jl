# ============================================================================
# Utility functions not for export
function trid(i::Int16; fs=2000::Real)
  S = ["DH", "HZ", "H1", "H2", "HZ", "HT", "HR"]
  return string(getbandcode(fs, fc=10.0), S[i])
end

function auto_coords(xy::Array{Int32,1}, c::Array{Int16,1})
  xy == Int32[0,0] && return (0.0, 0.0)
  lon = xy[1]
  lat = xy[2]
  coord_scale = c[1]
  coord_units = c[2]
  if coord_scale < 0
    coord_scale = -1 / coord_scale
  end
  lat *= coord_scale
  lon *= coord_scale
  if coord_units == 1
      iflg = lon < 0 ? -1 : 1
      x = 111132.95
      D = sqrt(lat^2+lon^2) / x
      lat = lat/x
      d = cosd(D)
      D = acosd(d / cosd(lat))
      lon = (iflg*D)
  else
    lat = Float64(lat/3600.0)
    lon = Float64(lon/3600.0)
  end
  return lat, lon
end

function do_trace(f::IO, fast::Bool, nmt::Bool; fh=zeros(Int16, 4)::Array{Int16,1}, fname=""::String)
  ftypes = Array{DataType,1}([UInt32, Int32, Int16, Any, Float32, Any, Any, Int8]) # Note: type 1 is IBM Float32
  shorts = Array{Int16, 1}(53)
  ints   = Array{Int32, 1}(19)

  # First part of trace header is quite standard
  ints[1:7]   = read(f, Int32, 7)
  shorts[1:4] = read(f, Int16, 4)
  ints[8:15]  = read(f, Int32, 8)
  shorts[5:6] = read(f, Int16, 2)
  ints[16:19] = read(f, Int32, 4)
  shorts[7:52]= read(f, Int16, 46)
  if !nmt
    shorts = [bswap(i) for i in shorts]
    ints = [bswap(i) for i in ints]
  end
  if !fast
    shorts_k = ["trid", "nvs", "nhs", "duse", "scalel", "scalco", "counit", "wevel", "swevel", "sut", "gut", "sstat", "gstat", "tstat", "laga", "lagb", "delrt", "muts", "mute", "ns", "dt", "gain", "igc", "igi", "corr", "sfs", "sfe", "slen", "styp", "stas", "stae", "tatyp", "afilf", "afils", "nofilf", "nofils", "lcf", "hcf", "lcs", "hcs", "year", "day", "hour", "min", "sec", "timbas", "trwf", "grnors", "grnofr", "grnlof", "gaps", "otrav"]
    ints_k   = ["tracl", "tracr", "fldr", "tracf", "ep", "cdp", "cdpt", "offset", "gelev", "selev", "sdepth", "gdel", "sdel", "swdep", "gwdep", "sx", "sy", "gx", "gy"]
    misc = Dict(zip([shorts_k; ints_k],[shorts; ints]))
  end

  # Here, PASSCAL/NMT wants to be a unique, special snowflake.
  if nmt
    chars       = read(f, UInt8, 20)
    dt          = read(f, Int32)
    fmt         = read(f, Int16)
    shorts[53]  = read(f, Int16)
    skip(f, 12)
    scale_fac   = read(f, Float32)
    skip(f, 4)
    n           = read(f, Int32)
    skip(f, 8)
    x           = read(f, fmt == 1 ? Int32 : Int16, shorts[20] == 32767 ? n : shorts[20])
    close(f)

    # trace processing
    fs    = 1.0e6 / Float64(shorts[21] == 1 ? dt: shorts[21])
    gain  = Float64((shorts[23]*10.0^(shorts[24]/10.0))/scale_fac)
    lat, lon  = auto_coords(ints[18:19], shorts[6:7])
    el    = Float64(ints[8]*shorts[5])
    sta   = String(chars[1:6])
    #inst  = String(chars[7:14])
    inst  = "00"

    c = strip(replace(String(chars[15:18]),"\0",""))
    if uppercase(c) in ["Z","N","E"]
      cha = string(getbandcode(fs), 'H', c[1])
    elseif length(c) < 2
      cha = "YYY"
    else
      cha = c
    end
  else
    (dt, n, fmt) = fh
    skip(f, 22)
    trace_unit  = bswap(read(f, Int16))
    trans_mant  = bswap(read(f, Int32))
    shorts2     = [bswap(i) for i in read(f, Int16, 5)]
    skip(f, 22)
    x           = [bswap(i) for i in read(f, ftypes[fmt], n)]

    # not sure about this; where did this formula come from...?
    gain  = trans_mant*10.0^(shorts2[1] + sum(shorts[23:24])/10.0) # *2.0^shorts[47]
    fs    = 1.0e6 / Float64(shorts[21])
    lat   = 0.0
    lon   = 0.0
    el    = Float64(ints[12]*shorts[5])
    sta   = @sprintf("%04i", shorts2[3])
    inst  = "00"
    cha   = shorts[1] in 11:1:17 ? trid(shorts[1]-10, fs=fs) : "YYY"
  end

  # Trace info
  (m,d)     = j2md(shorts[41], shorts[42])
  ts        = round(Int, d2u(DateTime(shorts[41], m, d, shorts[43], shorts[44], shorts[45]))*1000000 +
                   (shorts[53] + sum(shorts[15:17]))*1000)
  loc       = [0.0, 0.0, el, 0.0, 0.0]
  t         = [1 ts; length(x) 0]
  x         = map(Float64, x)
  src       = join([string("readsegy/", nmt ? "PASSCAL " : "", "SEG-Y,"), timestamp(), fname],',')
  id        = uppercase(replace(join(["", sta, inst, cha], '.'), "\0", ""))
  chan      = SeisChannel(name=id, id=id, loc=loc, gain=gain, fs=fs, src=src, t=t, x=x, units="unknown")
  if !fast
    if !nmt
      merge!(misc, Dict{String,Any}(zip(["trans_ex", "trans_un", "dev_id", "time_c", "src_typ"], shorts2)))
      misc["trace_un"] = trace_unit
      misc["trans_ma"] = trace_unit
    end
    chan.misc = deepcopy(misc)
  end
  return chan
end
# ============================================================================

"""
    seis = readsegy(fname)

Read SEG-Y file `fname` into SeisData object `seis`.

### Keywords
* `nmt=true` for PASSCAL/NMT modified SEG-Yr0
* `fast=false` to store full SEG-Y headers as a dictionary in `seis.misc`.
"""
function readsegy(fname::String; nmt=false::Bool, fast=true::Bool)
  fname = realpath(fname)
  f = open(fname, "r")
  if nmt
    seis = do_trace(f, fast, true, fname=fname)
  else
    if !fast
      fhd = Dict{String,Any}()
    end
    fh = Array{Int16,1}(27)
    seis = SeisData()

    # File header
    txthdr        = join(read(f, Cchar, 3200))
    ids           = read(f, Int32, 3)
    fh[1:24]      = read(f, Int16, 24)

    # My sample files have the last three Int16s stored in little endian order...???
    fh = [bswap(i) for i in fh]

    skip(f, 240)
    fh[25:27]     = read(f, Int16, 3)
    skip(f, 94)

    # Process file header
    ids = [bswap(i) for i in ids]

    if fh[end] > 0
      nh = fh[end]
      if fast
        skip(f, 3200*nh)
      else
        fhd["exthdr"] = [replace(join(read(f, Cchar, 3200)),"\0"," ") for i = 1:1:nh]
      end
    end

    # Done
    if !fast
      merge!(fhd, Dict{String,Any}(zip(["jobid", "lineid", "reelid", "ntr", "naux", "filedt", "origdt", "filenx",
      "orignx", "fmt", "cdpfold", "trasort", "vsum", "swst", "swen0", "swlen", "swtyp", "tapnum", "swtapst", "swtapen",
      "taptyp", "corrtra", "bgainrec", "amprec", "msys", "zupdn", "vibpol", "segyver", "isfixed", "ntxthdr"],
      [ids; fh])))
    end

    # Channel headers
    for i = 1:1:fh[1]
      seis += do_trace(f, fast, false, fh=fh[[3,5,7]])
      merge!(seis.misc[1], fhd)
    end
  end
  close(f)
  return seis
end

"""
    segyhdr(f)

Print formatted, sorted SEG-Y headers of file `f` to STDOUT. Pass keyword argument `nmt=true` for PASSCAL/NMT modified SEG-Yr0 files.
"""
function segyhdr(fname::String; nmt=false::Bool)
  seis = readsegy(fname::String; nmt=nmt, fast=false)
  if nmt
    @printf(STDOUT, "NMT SEG-Y HEADER: %s\n", realpath(fname))
    for k in sort(collect(keys(seis.misc)))
      @printf(STDOUT, "%10s: %s\n", k, string(seis.misc[k]))
    end
  else
    W = displaysize(STDOUT)[2]-2
    S = fill("", length(seis.misc[1])+1)
    p = 1
    w = 22
    @printf(STDOUT, "SEG-Y HEADER: %s\n", realpath(fname))
    for i = 1:1:seis.n
      if p > 1
        s = @sprintf("       %3i/%i", i, seis.n)
      else
        s = @sprintf(" Trace %3i/%i", i, seis.n)
      end
      S[1] *= s
      S[1] *= " "^(22-length(s))
      for (j,k) in enumerate(sort(collect(keys(seis.misc[i]))))
        s = string(seis.misc[i][k])
        S[j+1] *= @sprintf("%10s: %s%s", k, s, " "^(10-length(s)))
      end
      if p+2*w > W || i == seis.n
        [println(S[j]) for j=1:length(S)]
        println("")
        S = fill("", length(seis.misc[i])+1)
        p = 1
      else
        p += w
      end
    end
  end
  return nothing
end
