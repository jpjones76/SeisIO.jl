settracecode(S::Dict{ASCIIString,Any}) = (tc = ["Local", "GMT", "Other", "UTC"];
  try S["tc"] = tc[S["tc"]]; end)

function getsegunit(i)
  i == -1 && return "other"
  i == 1 && return "Pa"
  i == 2 && return "V"
  i == 3 && return "mV"
  i == 4 && return "A"
  i == 5 && return "m"
  i == 6 && return "m/s"
  i == 7 && return "m/s^2"
  i == 8 && return "N"
  i == 9 && return "W"
  return "unknown"
end

function getsegchantype(i; fs=2000::Real, fc=15::Real)
  i == 11 && return string(getbandcode(fs, fc=fc), "DH")
  i == 12 && return string(getbandcode(fs, fc=fc), "HZ")
  i == 13 && return string(getbandcode(fs, fc=fc), "H1")
  i == 14 && return string(getbandcode(fs, fc=fc), "H2")
  i == 15 && return string(getbandcode(fs, fc=fc), "HZ")
  i == 16 && return string(getbandcode(fs, fc=fc), "HT")
  i == 17 && return string(getbandcode(fs, fc=fc), "HR")
  return "???"
end

function auto_coords(lat, lon, coord_scale, coord_units)
  if coord_scale < 0
    coord_scale = -1 / coord_scale
  end
  lat *= coord_scale
  lon *= coord_scale
  if coord_units == 1
      iflg = lon < 0 ? -1 : 1
      x = 111132.95
      D = sqrt(lat^2+lon^2) / x
      lat /= x
      d = cos(D * pi / 180)
      D = acos(d / cos(lat * pi / 180))
      lon = (iflg*D)*180/pi
  else
    lat = Float32(lat/3600)
    lon = Float32(lon/3600)
  end
  return lat, lon
end

function getHdrStrings()
  Trace = ["lineSeq", "reelSeq", "eventN", "chanN", "enSrcPt", "cdp", "cdpN"]
  Short1 = ["traceCode", "vertSum", "horSum", "dataUse"]
  SrcRec = ["stel", "evel", "evdp", "recDat", "srcDat", "srcWater", "grpWater"]
  Coord = ["stla", "stlo", "evla", "evlo"]
  Short2 = ["coordUnits", "weatherV", "subweatherV", "srcUpholeT",
    "recUpholeT", "srcStaticC", "recStaticC", "totalStatic", "lagA",
    "lagB", "delay", "muteS", "muteE", "sampLen", "sampDT",
    "gainType", "gainConst", "initGain", "correlated", "sweepSF",
    "sweepEF", "sweepL", "sweepType", "sweepTapS",
    "sweepTapE", "taperType", "aliasF", "aliasSlope",
    "notchF", "notchSlope", "fl", "fh", "lowCutSlope",
    "highCutSlope", "nzyear", "nzjday", "nzhour", "nzmin", "nzsec", "tc",
    "traceWtFac", "geopRollPos1", "geopFirstTr", "geophLastTr",
    "gapSize", "taperOvertravel"]
  return (Trace, Short1, SrcRec, Coord, Short2)
end

"""
    pruneseg!(S)

Prune irrelevant standard headers from a SEGY dictionary S.
"""
function pruneseg!(S)
  # Common headers
  for i in ["enSrcPt", "cdp", "cdpN", "vertSum", "horSum", "dataUse", "recDat",
    "srcDat", "srcWater", "grpWater", "coordUnits", "weatherV", "subweatherV",
    "srcUpholeT", "recUpholeT", "srcStaticC", "recStaticC", "totalStatic",
    "lagA", "lagB", "delay", "muteS", "muteE", "sampLen", "sampDT",
    "correlated", "sweepSF", "sweepEF", "sweepL", "sweepType", "sweepTapS",
    "sweepTapE", "taperType", "aliasF", "aliasSlope","notchF", "notchSlope",
    "fl", "fh", "lowCutSlope", "highCutSlope", "tc", "geopRollPos1",
    "geopFirstTrace", "geopLastTrace", "gapSize", "taperOvertravel"]
      delete!(S,i)
  end
  try
    # PASSCAL/NMT-specific headers
    for i in ["dataForm", "trigyear", "trigjday", "trighour", "statDelay",
              "trigmin", "trigsec", "trigmsec"]
      delete!(S,i)
    end
  end
  return S
end

"""
  F, S = psegstd(sid)

Parse standard-format SEG Y stream sid with values in big endian byte order.
This is the default for most industry SEG Y rev 1 data.

  F, S = psegstd(sid, b=false)

Parse standard-format SEGY stream sid in little endian byte order.
"""
function psegstd(fid; b=true::Bool)
  F = Dict{ASCIIString,Any}()
  types = [UInt32, Int32, Int16, Any, Float32, Any, Any, Int8]

  # Header strings
  h_s = ["nTrace", "nAux", "dt", "dtOrig", "ns",
    "nsOrig", "fmt", "ensFold", "traceSort", "vertSumCode",
    "sweepFS", "sweepFE", "sweepLen", "sweepType",
    "sweepCha", "sweepTapLS", "sweepTapLE",
    "taperType", "corrTraces", "binGain",
    "ampRecMethod", "measSys", "impSigPol",
    "vibPolCode"]

  # Trace strings
  reel_s, short_s_1, sr_s, coord_s, short_s_2 = getHdrStrings()
  long_s = ["cdpX", "cdpY", "inline3D", "crossline3D", "shotPoint"]
  short_s_3 = ["transConstExp", "transUnit", "traceID", "timeSc", "srcType"]

  txtHdr                    = join(read(fid, Cchar, 3200))
  F["job"]                  = read(fid, Int32)
  F["line"]                 = read(fid, Int32)
  F["reel"]                 = read(fid, Int32)
  h_v                       = read(fid, Int16, 24)
  skip(fid, 240)
  F["rev"]                  = read(fid, UInt16)
  F["fixedLen"]             = read(fid, Int16)
  nETH                      = read(fid, Int16)
  skip(fid, 94)
  merge!(F, Dict(zip(h_s,h_v)))
  b && [F[i] = bswap(F[i]) for i in collect(keys(F))]
  if nETH > 0
    extTxtHdr = Array{ASCIIString,1}(nETH)
    for i = 1:1:nETH
      extTxtHdr[i]          = replace(join(read(fid, Cchar, 3200)),"\0"," ")
    end
    F["extTxtHdr"] = extTxtHdr
  end

  # Process header
  F["rev"]     = min(F["rev"], 1)
  F["txtHdr"]  = replace(txtHdr,"\0"," ")
  F["fmt"]     = types[F["fmt"]]

  S = Array{Dict{ASCIIString,Any},1}(F["nTrace"])
  for k = 1:1:F["nTrace"]
    T = Dict{ASCIIString,Any}()
    reel_v                  = read(fid, Int32, 7)
    short_v_1               = read(fid, Int16, 4)
    sr_v                    = read(fid, Int32, 8)
    sr_scale                = read(fid, Int16)
    coord_scale             = read(fid, Int16)
    coord_v                 = read(fid, Int32, 4)
    short_v_2               = read(fid, Int16, 46)
    long_v                  = read(fid, Int32, 5)
    T["shotPtScalar"]       = read(fid, Int16)
    T["traceUnit"]          = read(fid, Int16)
    T["transConstMant"]     = read(fid, Int32)
    short_v_3               = read(fid, Int16, 5)
    T["srcEnDirMant"]       = read(fid, Int32)
    T["srcEnDirExp"]        = read(fid, Int16)
    T["srcMeasMant"]        = read(fid, Int32)
    T["srcMeasExp"]         = read(fid, Int16)
    T["srcMeasUnit"]        = read(fid, Int16)
    skip(fid, 8)
    merge!(T, Dict(zip(reel_s, reel_v)),
              Dict(zip(short_s_1, short_v_1)),
              Dict(zip(sr_s, sr_v.*sr_scale)),
              Dict(zip(coord_s, coord_scale.*coord_v)),
              Dict(zip(short_s_2, short_v_2)),
              Dict(zip(long_s, long_v)),
              Dict(zip(short_s_3, short_v_3)))
    b && [T[i] = bswap(T[i]) for i in collect(keys(T))]
    T["npts"] = F["ns"] > 0 ? F["ns"] : T["sampLen"]
    T["data"] = read(fid, F["fmt"], T["npts"])
    if b
      T["data"] = [bswap(i) for i in T["data"]]
    end

    # Processing
    settracecode(T)
    T["units"] = getsegunit(T["traceUnit"])
    T["stla"], T["stlo"] = auto_coords(T["stla"], T["stlo"], coord_scale,
      T["coordUnits"])
    T["nzmsec"] = T["lagA"] # msec is set here when converting from HNAS

    # Set sample rate
    T["delta"] = T["sampDT"]/1.0e6
    T["src"] = "segy"

    # Merge into S
    S[k] = T
  end
  close(fid)
  return F,S
end

""""
      S = pseg(f)

Parse SEGY stream f (Segy rev 0 mod_PASSCAL/NMT).

      S = pseg(f, fmt = "std")

Parse SEGY stream f (Segy rev 0 mod_PASSCAL/NMT).
"""
function pseg(fid; f="nmt"::ASCIIString)
  if Base.in(f,["passcal", "nmt"])
    S = Dict{ASCIIString,Any}()

    # Strings
    reel_s, short_s_1, sr_s,
      coord_s, short_s_2 = getHdrStrings()
    trig_s = ["dataForm", "nzmsec", "trigyear", "trigjday", "trighour",
              "trigmin", "trigsec", "trigmsec"]

    # Read channel header
    reel_v      = read(fid, Int32, 7)
    short_v_1   = read(fid, Int16, 4)
    sr_v        = read(fid, Int32, 8)
    sr_scale    = read(fid, Int16)
    coord_scale = read(fid, Int16)
    coord_v     = read(fid, Int32, 4)
    short_v_2   = read(fid, Int16, 46)
    merge!(S, Dict(zip(reel_s, reel_v)),
              Dict(zip(short_s_1, map(Int32, short_v_1))),
              Dict(zip(sr_s, map(Float32,sr_v.*sr_scale))),
              Dict(zip(coord_s, map(Float32, coord_scale.*coord_v))),
              Dict(zip(short_s_2, map(Int32, short_v_2))))
    S["kstnm"]      = replace(strip(ascii(read(fid, UInt8, 6))),"\0","")
    S["kinst"]      = replace(strip(ascii(read(fid, UInt8, 8))),"\0","")
    S["kcmpnm"]     = replace(strip(ascii(read(fid, UInt8, 4))),"\0","")
    S["statDelay"]  = read(fid, Int16)
    samp_rate       = 1.0e6/read(fid, Int32)
    trig_v          = read(fid, Int16, 8); merge!(S, Dict(zip(trig_s, trig_v)))
    scale_fac       = read(fid, Float32)
    S["iinst"]      = read(fid, UInt16)
    skip(fid, 2)
    S["npts"]       = read(fid, Int32)
    S["depmax"]     = read(fid, Int32)
    S["depmin"]     = read(fid, Int32)

    # Read data
    S["data"]       = read(fid, S["dataForm"] == 0 ? Int16 : Int32, S["npts"])
    close(fid)

    # Processing
    settracecode(S)
    if scale_fac != 0 && S["gainConst"] != 0
      S["scale"] = (scale_fac/S["gainConst"])
    end
    S["delta"] = Float32((S["sampDT"] == 1 ? samp_rate : S["sampDT"])/1.0e6)
    S["stla"], S["stlo"] = auto_coords(S["stla"], S["stlo"],
                                       coord_scale, S["coordUnits"])
    S["src"] = "segy_PASSCAL"
    return S
  else
    F, S = psegstd(fid)
    return F, S
  end
end


"""
    S = segytosac(SEG)

    Convert SEG Y dictionary SEG to SAC dictionary S. Only operates on a
single-channel dictionary; for standard SEG Y dictionaries, operate on one
channel `k` at a time with `S = segy2sac(SEG[k])`.
"""
function segytosac(SEG::Dict{ASCIIString,Any})
  S = Dict{ASCIIString,Any}()

  # Create SAC headers
  S["b"] = Float32(0)
  S["e"] = Float32(SEG["npts"] * SEG["delta"])
  S["internal4"] = Int32(0)
  S["iftype"] = Int32(1)
  S["leven"] = Int32(1)
  S["lpspol"] = Int32(0)
  S["lcalda"] = Int32(1)

  for i in ("delta", "evdp", "evel", "evla", "evlo", "kcmpnm", "kinst", "kstnm",
            "npts", "nzhour", "nzjday", "nzmin", "nzsec", "nzyear", "scale",
            "stdp", "stel", "stla", "stlo", "data")
    try; S[i] = SEG[i]; end
  end

  # Trigger time ==> P arrival
  if haskey(SEG, "trigyear")
    try
      m0, d0 = j2md(SEG["nzjday"], SEG["nzyear"])
      m1, d1 = j2md(SEG["trigjday"], SEG["trigyear"])
      d1 = DateTime(SEG["nzyear"], m0, d0, SEG["nzhour"],
                    SEG["nzmin"], SEG["nzsec"], SEG["nzmsec"])
      d2 = DateTime(SEG["trigyear"], m1, d1, SEG["trighour"],
                    SEG["trigmin"], SEG["trigsec"], SEG["trigmsec"])
      S["a"] = Float32((d1-d2).value * 1.0e-6)
    end
  end
  return S
end

"""
    readsegy(fid::ASCIIString; [f="nmt","std"])

Read a SEG Y file into a SeisData object. Specify f="nmt" for PASSCAL/NMT SEG
Y rev 0.
"""
readsegy(fid::ASCIIString; f="nmt"::ASCIIString) = psegy(open(fid,"r"), f=f)

"""
    segyhdr(S::Dict{ASCIIString,Any})

Print SEG Y headers to STDOUT.
"""
segyhdr(S::Dict{ASCIIString,Any}) = [(i != "data" && (println(i, ": ", S[i]))) for i in sort(collect(keys(S)))]

"""
    S = segytoseis(SEG::Dict{ASCIIString,Any})

Convert SEG Y dictionary `SEG` to a SeisData object.
"""
function segytoseis(S::Dict{ASCIIString,Any})
  fs = 1/S["delta"]
  if haskey(S, "kstnm")
    name = join([S["kstnm"],S["kcmpnm"],S["kinst"]],'.')
    id = join(["",S["kstnm"],"",S["kcmpnm"]],'.')
  else
    cmp = getsegchantype(S["traceCode"], fs=fs)
    sta = @sprintf("%04i", S["traceID"])
    name = join([sta,cmp],'.')
    id = join(["",sta,"",cmp],'.')
  end
  x = S["data"]
  t = map(Float64, [0 sac2epoch(S); length(x) 0])
  gain = 1.0
  units = "unknown"
  loc = zeros(5)

  if S["src"] == "segy_PASSCAL"
    # PASSCAL appears to just store this as a scalar
    gain = S["gainConst"]
  elseif haskey(S,"transConstMant")
    # I have little confidence in this formula; not sure about traceWtFac;
    # not sure if exponent uses gainConst/10 or gainConst/20 from dB
    gain = (2.0^S["traceWtFac"]) * S["transConstMant"] * 10.0^(S["transConstExp"]+(S["gainConst"]/10.0))
  end
  haskey(S,"transUnit") && (units = getsegunit(S["transUnit"]))
  haskey(S, "stla") && (loc = [S["stla"]; S["stlo"]; S["stel"]; 0; 0])

  # Not going to bother converting misc SEGY stuff for now
  return SeisObj(name=name, id=id, x=x, gain=gain, t=t, gain=gain, fs=fs,
    units=units, src=S["src"], loc=loc)
end
segytoseis(SEG::Array{Dict{ASCIIString,Any},1}) = (S = SeisData();
  [S += segytoseis(SEG[i]) for i=1:length(SEG)]; return S)


"""
    r_segy(fid::ASCIIString; [f="nmt","std"])

Read a SEG Y file into a SeisData object. Specify f="nmt" for PASSCAL/NMT SEG
Y rev 0.
"""
function r_segy(fid::ASCIIString; f="std"::ASCIIString)
  if Base.in(f,["passcal", "nmt"])
    SEG = pseg(open(fid,"r"), f=f)
  else
    F, SEG = pseg(open(fid,"r"), f=f)
  end
  return(segytoseis(SEG))
end
