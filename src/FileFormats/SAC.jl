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

get_sac_fw(k::ASCIIString) = ((F, I, C) = get_sac_keys(); findfirst(F .== k))
get_sac_iw(k::ASCIIString) = ((F, I, C) = get_sac_keys(); findfirst(I .== k))

"""
    prunesac!(S::Dict{ASCIIString,Any})

Auto-prune unset SAC headers.
"""
function prunesac!(S::Dict{ASCIIString,Any})
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
    S = psac(s)

Parse SAC stream s, returning dictionary S with data in S["data"] and
SAC headers in other keys.

For generic xy data (IFTYPE==4), by convention, the first NPTS values are read
into S["data"]; the second NPTS values are returned in S["time"].
"""
function psac(f; p=false::Bool)
  S = Dict{ASCIIString,Any}()
  (fk,ik,ck) = get_sac_keys()
  fv = read(f, Float32, 70)
  iv = read(f, Int32, 40)
  cv = read(f, UInt8, 192)
  merge!(S, Dict(zip(fk,fv)), Dict(zip(ik,iv)))
  n = 1
  for k = 1:length(ck)
    nn = k == 2 ? 15 : 7
    S[ck[k]] = replace(strip(ascii(cv[n : n + nn])),"\0","")
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

"""
    S = rsac(fname)

Read SAC file fname into a dictionary. Header values are indexed by key, e.g.
S["delta"] for DELTA. S["data"] contains the trace data.

"""
rsac(fname::ASCIIString; p=false::Bool) = (S = psac(open(fname,"r"), p=p))

function sacwrite(fname::ASCIIString, sacFloats::Array{Float32,1},
  sacInts::Array{Int32,1}, sacChars::Array{Uint8,1}, x::Array{Float32,1};
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

"""
    chksac(S::Dict{ASCIIString,Any})

Check for required and recommended headers in SAC dictionary S.
"""
function chksac(S::Dict{ASCIIString,Any})
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
    sachdr(S::Dict{ASCIIString,Any})

Print SAC headers in SAC dictionary S to STDOUT.
"""
sachdr(S::Dict{ASCIIString,Any}) = [(i != "data" && (println(i, ": ", S[i])))
  for i in sort(collect(keys(S)))]

"""
    wsac(S::Dict{ASCIIString,Any})

Write SAC dictionary S to SAC file. Name convention is auto-determined by time
headers (NZYEAR--NZMSEC), KNETWK, KSTNM, and KCMPNM; default is sacfile.SAC.

    wsac(S, f=FNAME)

Write SAC dictionary S to SAC file FNAME.

    wsac(S, ts=true)

Specify ts=true to time stamp data. If S has a "time" key, all values in
S["time"] are written blindly as time stamps. Otherwise, time stamps are
written as delta-encoded integer multiples of S["delta"], with t[1] = 0.
"""
function wsac(S::Dict{ASCIIString,Any}; f="auto"::ASCIIString, ts=false::Bool)
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

function sactoseis(D::Dict{ASCIIString,Any})
  !haskey(D, "nvhdr") && error("Invalid SAC dictionary! (NVHDR not set)")
  D["nvhdr"] == 6 || error("Can't parse old SAC versions! (NVHDR != 6)")

  unitstrings = ["nm", "nm/s", "V", "nm/s/s", "unknown"]
  pha = Dict{ASCIIString,Float64}()
  if haskey(D, "idep")
    units = unitstrings[D["idep"]]
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
  t = map(Float64, [0 sac2epoch(D); D["npts"] 0])

  misc = prunesac(D)
  for k in [collect(pkeys); ["nvhdr", "knetwk", "kstnm", "kcmpnm", "scale",
    "nzyear", "nzjday", "nzhour", "nzmin", "nzsec", "nzmsec", "e", "b", "npts",
    "src", "data", "delta", "cmpaz", "cmpinc", "stla", "stlo", "stel", "idep"]]
    if haskey(misc, k); delete!(misc, k); end
  end

  # Turn this monstrosity into a SeisObj
  T = SeisObj(name=name, id=id, fs=fs, gain=gain, loc=loc, pha=pha, t=t, x=x,
              src="sac file", misc=misc, units=units)
  return T
end

"""
    S = readsac(fname)

Read SAC file `fname` into a SeisObj. 
"""
readsac(fname::ASCIIString; p=false::Bool) = sactoseis(psac(open(fname,"r"),
  v=v, p=p))
