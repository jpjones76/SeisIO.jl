const nul_f = -12345.0f0
const nul_i = Int32(-12345)
const nul_s = "-12345  "

# ============================================================================
# Utility functions not for export
get_sac_keys() = ["delta", "depmin", "depmax", "scale", "odelta",
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
                "unused3", "unused4", "unused5", "unused6", "unused7"],
                ["nzyear", "nzjday", "nzhour", "nzmin", "nzsec",
                "nzmsec", "nvhdr", "norid", "nevid", "npts",
                "internal4", "nwfid", "nxsize", "nysize", "unused8",
                "iftype", "idep", "iztype", "unused9", "iinst",
                "istreg", "ievreg", "ievtyp", "iqual", "isynth",
                "imagtyp", "imagsrc", "unused10", "unused11", "unused12",
                "unused13", "unused14", "unused15", "unused16", "unused17",
                "leven", "lpspol", "lovrok", "lcalda", "unused18"],
                ["kstnm", "kevnm", "khole", "ko", "ka", "kt0", "kt1", "kt2",
                "kt3", "kt4", "kt5", "kt6", "kt7", "kt8", "kt9", "kf", "kuser0",
                "kuser1", "kuser2", "kcmpnm", "knetwk", "kdatrd", "kinst"]


function write_sac_file(fname::String, fv::Array{Float32,1}, iv::Array{Int32,1}, cv::Array{UInt8,1}, x::Array{Float32,1}; t=[Float32(0)]::Array{Float32,1}, ts=true::Bool)
  f = open(fname, "w")
  write(f, fv)
  write(f, iv)
  write(f, cv)
  write(f, x)
  if ts
    write(f, t)
  end
  close(f)
  return
end

function read_sac_stream(f::IO; fast=true::Bool)
  if fast
    fv = read(f, Float32, 59)
    skip(f, 44)
    iv = read(f, Int32, 10)
    skip(f, 120)
  else
    fv = read(f, Float32, 70)
    iv = read(f, Int32, 40)
  end
  cv = read(f, UInt8, 192)

  # floats
  loc = zeros(Float64,5)
  fs = Float64(1/fv[1])
  if fv[4] == nul_f
    gain = 1.0
  else
    gain = Float64(fv[4])
  end
  for (i,v) in enumerate([32, 33, 34, 58, 59])
    if fv[v] != nul_f
      loc[i] = fv[v]
    end
  end

  # ints
  nx = iv[10]
  (m,d) = j2md(iv[1],iv[2])
  ts = round(Int64, d2u(DateTime(iv[1],m,d,iv[3],iv[4],iv[5]))*sμ + Float64(iv[6] + fv[6] == nul_f ? 0.0f0 : fv[6])*sm)
  t = Array{Int64,2}([1 ts; nx 0])

  # chars
  cv = replace(replace(String(cv),"\0"," "), "-12345","      ")
  sta = strip(cv[1:8]); sta = sta[1:min(length(sta),5)]
  ll = strip(cv[17:24]); ll = ll[1:min(length(ll),2)]
  cc = strip(cv[161:168]); cc = cc[1:min(length(cc),3)]
  nn = strip(cv[169:176]); nn = nn[1:min(length(nn),2)]
  id = join([nn,sta,ll,cc],'.')

  # Read data
  x = read(f, Float32, nx)
  close(f)

  seis = SeisChannel(id=id, name=id, fs=fs, gain=gain, loc=loc, t=t, x=x)
  if fast
    return seis
  else
    return (fv, iv, cv, seis)
  end
end

function fill_sac(S::SeisChannel, ts::Bool, leven::Bool)
  fv = nul_f.*ones(Float32, 70)
  iv = nul_i.*ones(Int32, 40)
  cv = repmat(nul_s.data, 24)
  cv[17:24] = (" "^8).data

  # Ints
  t = S.t[1,2]*μs
  tt = [parse(Int32, i) for i in split(string(u2d(t)),r"[\.\:T\-]")]
  length(tt) == 6 && append!(tt,0)
  y = tt[1]
  j = Int32(md2j(y, tt[2], tt[3]))
  iv[1:6] = prepend!(tt[4:7], [y, j])
  iv[7] = 6
  iv[10] = Int32(length(S.x))
  iv[16] = ts ? 4 : 1
  iv[36] = leven ? 1 : 0

  # Floats
  dt = 1/S.fs
  fv[1] = Float32(dt)
  fv[4] = Float32(S.gain)
  fv[6] = 0.0f0
  fv[7] = Float32(dt*length(S.x) + sum(S.t[2:end,2])*μs)
  if !isempty(S.loc)
    if maximum(abs(S.loc)) > 0.0
      fv[32:34] = S.loc[1:3]
      fv[58:59] = S.loc[4:5]
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
    cv[c:c+L-1] = cat(1, s, repmat(" ".data, L-Ls))
  end

  # Assign a filename
  fname = @sprintf("%04i.%03i.%02i.%02i.%02i.%04i.%s.%s.%s.%s.R.SAC", y, j,
  tt[4], tt[5], tt[6], tt[7], ss[1], ss[2], ss[3], ss[4])
  return (fv, iv, cv, fname)
end
# ============================================================================

function readsac(fname::String; fast=true::Bool)
  fname = realpath(fname)
  if fast
    seis = read_sac_stream(open(fname, "r"), fast=true)
    seis.src = join(["readsac",timestamp(),fname],',')
    return seis
  else
    (fv, iv, cv, seis) = read_sac_stream(open(fname, "r"), fast=false)
    seis.src = join(["readsac",timestamp(),fname],',')
  end

  # Create dictionary
  (fk, ik, ck) = get_sac_keys()
  i = find(fv .!= nul_f)
  j = find(iv .!= nul_i)
  misc = Dict{String,Any}(zip(fk[i], fv[i]))
  merge!(misc, Dict{String,Any}(zip(ik[j], iv[j])))
  m = 0
  for k = 1:length(ck)
    n = k == 2 ? 16 : 8
    s = strip(String(cv[m+1:m+n]))
    if length(s) > 0
      misc[ck[k]] = s
    end
  end
  seis.misc = misc
  return seis
end
rsac(fname::String; fast=true::Bool) = readsac(fname, fast=fast)

"""
    sachdr(f)

Print formatted SAC headers from file `f` to STDOUT.
"""
function sachdr(fname::String)
  seis = readsac(fname, fast=false)
  for k in sort(collect(keys(misc)))
    @printf(STDOUT, "%10s: %s\n", uppercase(k), string(misc[k]))
  end
  return nothing
end

"""
    wsac(S::SeisData; ts=false, v=true)

Write all data in SeisData structure `S` to auto-generated SAC files.
"""
function writesac(S::Union{SeisEvent,SeisData}; ts=false::Bool, v=true::Bool)
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32}(0)
  if isa(S, SeisEvent)
    evt_info = Array{Float32,1}([S.hdr.lat, S.hdr.lon, S.hdr.dep, nul_f, S.hdr.mag])
    t_evt = d2u(S.hdr.time)
    evid  = S.hdr.id == 0 ? nul_s : String(S.hdr.id)
    EvL   = length(evid)
    N     = S.data.n
  else
    N     = S.n
  end
  for i = 1:1:N
    T = isa(S, SeisEvent) ? S.data[i] : S[i]
    b = T.t[1,2]
    dt = 1/T.fs
    (fv, iv, cv, fname) = fill_sac(T, ts, leven)

    # Values from event header
    if isa(S, SeisEvent)
      fv[40:44] = evt_info
      fv[8] = t_evt - b*μs
      cv[9+EvL:24] = cat(1, nn.data, repmat(" ".data, 16-EvL))
    end

    # Data
    x = map(Float32, T.x)
    ts && (tdata = map(Float32, μs*(t_expand(T.t, dt) .- b)))

    # Write to file
    write_sac_file(fname, fv, iv, cv, x, t=tdata, ts=ts)
    v && @printf(STDOUT, "%s: Wrote file %s from SeisData channel %i\n", string(now()), fname, i)
  end
end
writesac(S::SeisChannel; ts=false::Bool, v=true::Bool) = writesac(SeisData(S), ts=ts, v=v)
wsac(S::Union{SeisEvent,SeisData}; ts=false::Bool, v=true::Bool) = writesac(S, ts=ts, v=v)
wsac(S::SeisChannel; ts=false::Bool, v=true::Bool) = writesac(SeisData(S), ts=ts, v=v)
