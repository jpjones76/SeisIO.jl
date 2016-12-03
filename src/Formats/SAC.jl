function get_sac_keys()
  sacFloatKeys = ["delta", "depmin", "depmax", "scale", "odelta",
                "b", "e", "o", "a", "internal1",
                "t0", "t1", "t2", "t3", "t4",
                "t5", "t6", "t7", "t8", "t9",
                "f", "resp0", "resp1", "resp2", "resp3",
                "resp4", "resp5", "resp6", "resp7", "resp8",
                "resp9", "stla", "stlo", "stel", "stdp",
                "evla", "evlo", "evel", "evdp", "mag",
                "user0", "user1", "user2", "user3", "user4",
                "user5", "user6", "user7", "user8", "user9",
                "dist", "az", "baz", "gcarc", "internal2",
                "internal3", "depmen", "cmpaz", "cmpinc", "xminimum",
                "xmaximum", "yminimum", "ymaximum", "unused1", "unused2",
                "unused3", "unused4", "unused5", "unused6", "unused7"]
  sacIntKeys = ["nzyear", "nzjday", "nzhour", "nzmin", "nzsec",
              "nzmsec", "nvhdr", "norid", "nevid", "npts",
              "internal4", "nwfid", "nxsize", "nysize", "unused8",
              "iftype", "idep", "iztype", "unused9", "iinst",
              "istreg", "ievreg", "ievtyp", "iqual", "isynth",
              "imagtyp", "imagsrc", "unused10", "unused11", "unused12",
              "unused13", "unused14", "unused15", "unused16", "unused17",
              "leven", "lpspol", "lovrok", "lcalda", "unused18"]
  sacCharKeys = ["kstnm", "kevnm", "khole", "ko", "ka", "kt0", "kt1", "kt2",
               "kt3", "kt4", "kt5", "kt6", "kt7", "kt8", "kt9", "kf", "kuser0",
               "kuser1", "kuser2", "kcmpnm", "knetwk", "kdatrd", "kinst"]
  return (sacFloatKeys,sacIntKeys, sacCharKeys)
end

"""
    prunesac!(S::Dict{String,Any})

Auto-prune unset SAC headers.
"""
function prunesac!(S::Dict{String,Any})
  (sacFloatKeys,sacIntKeys, sacCharKeys) = get_sac_keys()
  for i in cat(1,sacFloatKeys,sacIntKeys)
    if haskey(S, i)
      if (S[i] - -12345) < eps(Float32)
        delete!(S,i)
      end
    end
  end
  for i in sacCharKeys
    if haskey(S, i)
      if (S[i] == "-12345")
        delete!(S,i)
      end
    end
  end
  return S
end
function prunesac(S)
  T = deepcopy(S)
  prunesac!(T)
  return(T)
end

"""
    S = parse_sac(s)

Parse SAC stream s, returning dictionary S with data in S["data"] and
SAC headers in other keys.

For generic xy data (IFTYPE==4), by convention, the first NPTS values are read
into S["data"]; the second NPTS values are returned in S["time"].
"""
function parse_sac(f; p=false::Bool)
  S = Dict{String,Any}()
  (fk,ik,ck) = get_sac_keys()
  fv = read(f, Float32, 70)
  iv = read(f, Int32, 40)
  cv = read(f, UInt8, 192)
  merge!(S, Dict(zip(fk,fv)), Dict(zip(ik,iv)))
  n = 1
  for k = 1:length(ck)
    nn = k == 2 ? 15 : 7
    S[ck[k]] = replace(strip(ascii(String(cv[n : n + nn]))),"\0","")
    n += (nn+1)
  end

  S["data"] = read(f, Float32, S["npts"])
  if S["iftype"] == 4
    S["time"] = deepcopy(S["data"])
    S["data"] = read(f, Float32, S["npts"])
  elseif S["iftype"] > 1
    S["data"] = complex(S["data"], read(f, Float32, S["npts"]))
  end
  close(f)
  S["src"] = "sac"
  p && prunesac!(S)
  return(S)
end

# ===========================================================================
# SAC read methods
# ===========================================================================
"""
    S = r_sac(fname)

Read SAC file fname into a dictionary. Header values are indexed by key, e.g.
S["delta"] for DELTA. S["data"] contains the trace data.

"""
r_sac(fname::String; p=false::Bool) = (S = parse_sac(open(fname,"r"), p=p))

"""
    chksac(S::Dict{String,Any})

Check for required and recommended headers in SAC dictionary S.
"""
function chksac(S::Dict{String,Any})
  req = ["nzyear","nzjday","nzhour","nzmin","nzsec","nzmsec",
         "npts","nvhdr", "b", "e", "iftype", "leven", "delta"]
  nrec = ["stla", "stlo", "stel"]
  crec = ["knetwk", "kstnm", "kcmpnm"]
  @printf(STDOUT, "\nRequired headers\n================\n")
  for i in sort(req)
    flag = false
    try
      isapprox(-12345, S[i]) && (flag=true)
    catch
      flag = true
    end
    if flag
      warn(@sprintf("%s: NOT set", i))
    else
      @printf(STDOUT, "%5s: set\n", i)
    end
  end
  @printf(STDOUT, "\nRecommended headers\n-------------------\n")
  for i in sort(crec)
    flag = false
    try
      (S[i] == "-12345") && (flag=true)
    catch
      flag = true
    end
    if flag
      @printf(STDOUT, "%5s: NOT set (filename autogen won't work)\n", i)
    else
      @printf(STDOUT, "%5s: set\n", i)
    end
  end
  for i in sort(nrec)
    flag = false
    try
      isapprox(-12345, S[i]) && (flag=true)
    catch
      flag = true
    end
    if flag
      @printf(STDOUT, "%5s: NOT set\n", i)
    else
      @printf(STDOUT, "%5s: set\n", i)
    end
  end
  return
end

"""
    sachdr(S::Dict{String,Any})

Print SAC headers in SAC dictionary S to STDOUT.
"""
sachdr(S::Dict{String,Any}) = [(i != "data" && (println(i, ": ", S[i])))
  for i in sort(collect(keys(S)))]

function sactoseis(D::Dict{String,Any})
  !haskey(D, "nvhdr") && error("Invalid SAC dictionary! (NVHDR not set)")
  D["nvhdr"] == 6 || error("Can't parse old SAC versions! (NVHDR != 6)")

  unitstrings = ["nm", "nm/s", "V", "nm/s/s", "unknown"]
  pha = Dict{String,Float64}()
  if haskey(D, "idep")
    try
      units = unitstrings[D["idep"]]
    catch
      units = "unknown"
    end
  else
    units = "m/s"
  end

  name = join([D["knetwk"],D["kstnm"],D["kcmpnm"]],".")
  id = join([D["knetwk"],D["kstnm"],"",D["kcmpnm"]],".")
  gain = D["scale"] == -12345.0 ? 1.0 : D["scale"]
  fs = 1/D["delta"]
  if haskey(D, "cmpaz") && haskey(D, "cmpinc")
    loc = [D["stla"], D["stlo"], D["stel"], D["cmpaz"], D["cmpinc"]]
  else
    loc = [D["stla"], D["stlo"], D["stel"], 0, 0]
  end
  x = map(Float64, D["data"])
  t = map(Float64, [1 sac2epoch(D)/μs; D["npts"] 0])

  misc = prunesac(D)
  for k in ["nvhdr", "knetwk", "kstnm", "kcmpnm", "scale",
    "nzyear", "nzjday", "nzhour", "nzmin", "nzsec", "nzmsec", "e", "b", "npts",
    "src", "data", "delta", "cmpaz", "cmpinc", "stla", "stlo", "stel", "idep"]
    if haskey(misc, k); delete!(misc, k); end
  end

  # Turn this monstrosity into a SeisChannel
  T = SeisChannel(name=name, id=id, fs=fs, gain=gain, loc=loc, t=t, x=x,
              src="sac file", misc=misc, units=units)
  return T
end

"""
    S = rsac(fname)

Read SAC file `fname` into a SeisChannel.
"""
rsac(fname::String) = (src = fname;
  S = sactoseis(parse_sac(open(fname,"r"), p=false)); note(S, fname); return S)
readsac(fname::String) = rsac(fname)

# ===========================================================================
# SAC write methods
# ===========================================================================
function fillSacVals(S::SeisChannel, ts::Bool, leven::Bool)
  # Initialize values
  sacFloatVals = Float32(-12345).*ones(Float32, 70)
  sacIntVals = Int32(-12345).*ones(Int32, 40)
  sacCharVals = repmat("-12345  ".data, 24)
  sacCharVals[17:24] = (" "^8).data

  # Ints
  t = S.t[1,2]*μs
  tt = [parse(Int32, i) for i in split(string(u2d(t)),r"[\.\:T\-]")]
  length(tt) == 6 && append!(tt,0)
  y = tt[1]
  j = Int32(md2j(y, tt[2], tt[3]))
  sacIntVals[1:6] = prepend!(tt[4:7], [y, j])
  sacIntVals[7] = 6
  sacIntVals[10] = Int32(length(S.x))
  sacIntVals[16] = ts ? 4 : 1
  sacIntVals[36] = leven ? 1 : 0

  # Floats
  dt = 1/S.fs
  sacFloatVals[1] = Float32(dt)
  sacFloatVals[4] = Float32(S.gain)
  sacFloatVals[6] = Float32(0)
  sacFloatVals[7] = Float32(dt*length(S.x) + sum(S.t[2:end,2])*μs)
  if !isempty(S.loc)
    if maximum(abs(S.loc)) > 0.0
      sacFloatVals[32] = Float32(S.loc[1])
      sacFloatVals[33] = Float32(S.loc[2])
      sacFloatVals[34] = Float32(S.loc[3])
      sacFloatVals[58] = Float32(S.loc[4])
      sacFloatVals[59] = Float32(S.loc[5])
    end
  end

  # Chars (ugh...)
  id = split(S.id,'.')
  ci = [169, 1, 25, 161]
  Lc = [8, 16, 8, 8]
  ss = Array{String,1}(4)
  for i = 1:1:4
    ss[i] = String(id[i])
    s = ss[i].data
    Ls = length(s)
    L = Lc[i]
    c = ci[i]
    sacCharVals[c:c+L-1] = cat(1, s, repmat(" ".data, L-Ls))
  end

  # Assign a filename
  fname = @sprintf("%04i.%03i.%02i.%02i.%02i.%04i.%s.%s.%s.%s.R.SAC", y, j,
  tt[4], tt[5], tt[6], tt[7], ss[1], ss[2], ss[3], ss[4])
  return (sacFloatVals, sacIntVals, sacCharVals, fname)

end

function sacwrite(fname::String, sacFloats::Array{Float32,1},
  sacInts::Array{Int32,1}, sacChars::Array{UInt8,1}, x::Array{Float32,1};
  t=[Float32(0)]::Array{Float32,1}, ts=true::Bool)
  f = open(fname, "w")
  write(f, sacFloats)
  write(f, sacInts)
  write(f, sacChars)
  write(f, x)
  if ts
    write(f, t)
  end
  close(f)
  return
end

# ============================================================================
# SAC write
"""
    wsac(S::SeisData; ts=false, v=true)

Write all data in S to auto-generated SAC files.
"""
function wsac(S::Union{SeisEvent,SeisData}; ts=false::Bool, v=true::Bool)
  (sacFloatKeys,sacIntKeys, sacCharKeys) = get_sac_keys()
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32}(0)
  if isa(S, SeisEvent)
    evt_info = Array{Float32,1}([S.hdr.lat, S.hdr.lon, S.hdr.dep, -12345.0f0, S.hdr.mag])
    t_evt = d2u(S.hdr.time)
    evid  = S.hdr.id == 0 ? "-12345" : String(S.hdr.id)
    EvL   = length(evid)
    N     = S.data.n
  else
    N     = S.n
  end
  for i = 1:1:N
    T = isa(S, SeisEvent) ? S.data[i] : S[i]
    b = T.t[1,2]
    dt = 1/T.fs
    (sacFloatVals, sacIntVals, sacCharVals, fname) = fillSacVals(T, ts, leven)

    # Values from event header
    if isa(S, SeisEvent)
      sacFloatVals[40:44] = evt_info
      sacFloatVals[8] = t_evt - b*μs
      sacCharVals[9+EvL:24] = cat(1, nn.data, repmat(" ".data, 16-EvL))
    end

    # Data
    x = map(Float32, T.x)
    ts && (tdata = map(Float32, μs*(t_expand(T.t, dt) .- b)))

    # Write to file
    sacwrite(fname, sacFloatVals, sacIntVals, sacCharVals, x, t=tdata, ts=ts)
    v && @printf(STDOUT, "%s: Wrote file %s from SeisData channel %i\n", string(now()), fname, i)
  end
end
writesac(S::Union{SeisData,SeisEvent}; ts=false::Bool, v=true::Bool) = wsac(S::SeisData, ts=ts, v=v)
writesac(S::SeisChannel; ts=false::Bool, v=true::Bool) = wsac(SeisData(S), ts=ts, v=v)

"""
    wsac(D::Dict{String,Any})

Write SAC dictionary D to SAC file. Name convention is auto-determined by time
headers (NZYEAR--NZMSEC), KNETWK, KSTNM, and KCMPNM; default is sacfile.SAC.

    wsac(D, f=FNAME)

Write SAC dictionary S to SAC file FNAME.

    wsac(D, ts=true)

Specify ts=true to time stamp data. If D has a "time" key, all values in
D["time"] are written blindly as time stamps. Otherwise, time stamps are
written as delta-encoded integer multiples of D["delta"], with t[1] = 0.
"""
function wsac(S::Dict{String,Any}; f="auto"::String, ts=false::Bool)
  prunesac!(S)
  tdata = Array{Float32}(0)
  !haskey(S, "iftype") && (S["iftype"] = Int32(1))  # Unset in SAC from IRISws
  !haskey(S,"leven") && error("Invalid SAC Dict!")
  if ts
    S["leven"] = Int32(0)
    S["iftype"] = Int32(4)
  end
  (fk, ik, ck) = get_sac_keys()
  fv = Float32(-12345).*ones(Float32, 70)
  iv = Int32(-12345).*ones(Int32, 40)
  cv = repmat("-12345  ".data, 24)
  cv[17:24] = collect(repeated(0x20, 8))  # second half of kevnm

  # Set whatever we can
  [(try(fv[k] = S[fk[k]]); end) for k=1:1:length(fk)]
  [(try(iv[k] = S[ik[k]]); end) for k=1:1:length(ik)]

  # Fill cv
  n = 0
  for i = 1:1:length(ck)
    k = ck[i]
    j = i == 2 ? 16 : 8
    if haskey(S,k)
      cv[n+1:n+j] = collect(repeated(0x20, j))
      s = S[k].data
      L = minimum([j, length(s)])
      cv[n+1:n+L] = s[1:L]
    end
    n += j
  end

  # Data and time stamps
  x = S["data"]
  if ts
    if haskey(S,"time")
      tdata = S["time"]
    else
      tdata = cumsum([Float32(0); repmat([S["delta"]], Int32(S["npts"])-1)])
    end
  end

  # Set filename
  if f == "auto"
    try
      f = @sprintf("%04i.%03i.%02i.%02i.%02i.%04i.%s.%s..%s.R.SAC",
      S["nzyear"], S["nzjday"], S["nzhour"], S["nzmin"], S["nzsec"],
      S["nzmsec"], S["knetwk"], S["kstnm"], S["kcmpnm"])
    catch
      f = "sacfile.SAC"
    end
  end
  sacwrite(f, fv, iv, cv, x, t=tdata, ts=ts)
  return
end
writesac(S::Dict{String,Any}; f="auto"::String, ts=false::Bool) = wsac(S,f=f,ts=ts)
