import Base.merge!
export readsac, rsac, sachdr, writesac, wsac

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


# Bytes 305:308 as a littleendian Int32 should read 0x06 0x00 0x00 0x00; compare each end to 0x0a to allow older SAC versions (if version in same place?)
function should_bswap(file::String)
  q::Bool = open(file, "r") do io
    seek(io, 304)
    u = read(io, UInt8)
    skip(io, 2)
    v = read(io, UInt8)
    # Least significant byte in u
    if 0x00 < u < 0x0a && v == 0x00
      return false
    # Most significant byte in u
    elseif u == 0x00 && 0x00 < v < 0x0a
      return true
    else
      error("Invalid SAC file.")
    end
  end
end

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

function fill_sac(S::SeisChannel, ts::Bool, leven::Bool)
  fv = sac_nul_f.*ones(Float32, 70)
  iv = sac_nul_i.*ones(Int32, 40)
  cv = repeat(codeunits(sac_nul_s), 24)
  cv[17:24] = codeunits(" "^8)

  # Ints
  tt = Int32[Base.parse(Int32, i) for i in split(string(u2d(S.t[1,2]*μs)),r"[\.\:T\-]")]
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
    if maximum(abs.(S.loc)) > 0.0
      fv[32:34] = S.loc[1:3]
      fv[58:59] = S.loc[4:5]
    end
  end

  # Chars (ugh...)
  id = split(S.id,'.')
  ci = [169, 1, 25, 161]
  Lc = [8, 16, 8, 8]
  ss = Array{String, 1}(undef, 4)
  for i = 1:4
    ss[i] = String(id[i])
    s = codeunits(ss[i])
    Ls = length(s)
    L = Lc[i]
    c = ci[i]
    cv[c:c+L-1] .= 0x20
  end

  # Assign a filename
  y_s = string(y); y_s="0"^(4-length(y_s))*y_s
  j_s = string(j); j_s="0"^(3-length(j_s))*j_s
  h_s = string(tt[4]); h_s="0"^(2-length(h_s))*h_s
  m_s = string(tt[5]); m_s="0"^(2-length(m_s))*m_s
  s_s = string(tt[6]); s_s="0"^(2-length(s_s))*s_s
  ms_s = string(tt[7]); ms_s="0"^(3-length(ms_s))*ms_s
  fname = join([y_s, j_s, h_s, m_s, s_s, ms_s, ss[1], ss[2], ss[3], ss[4], "R.SAC"],'.')
  return (fv, iv, cv, fname)
end

function read_sac_stream(f::IO, full=false::Bool, swap=false::Bool)
  S = SeisChannel()
  fv = read!(f, Array{Float32, 1}(undef, 70))
  iv = read!(f, Array{Int32, 1}(undef, 40))
  cv = read!(f, Array{UInt8, 1}(undef, 192))
  if swap == true
    for (i, v) in enumerate(fv)
      fv[i] = bswap(v)
    end
    for (i, v) in enumerate(iv)
      iv[i] = bswap(v)
    end
    setfield!(S, :x, Float32[bswap(i) for i in read!(f, Array{Float32, 1}(undef, iv[10]))])
  else
    setfield!(S, :x, read!(f, Array{Float32, 1}(undef, iv[10])))
  end

  # floats
  setfield!(S, :fs, Float64(1/fv[1]))
  setfield!(S, :gain, Float64(fv[4] == sac_nul_f ? 1.0f0 : fv[4]))
  loc = [(fv[i] == sac_nul_f ? 0.0 : Float64(fv[i])) for i in [32, 33, 34, 58, 59]]
  setfield!(S, :loc, loc)

  # ints
  (m,d) = j2md(iv[1],iv[2])
  ts = round(Int64, d2u(DateTime(iv[1], m, d, iv[3], iv[4], iv[5], iv[6]))*sμ + Float64((fv[6] == sac_nul_f ? 0.0f0 : fv[6])*1.0f3))
  setfield!(S, :t, Array{Int64,2}([1 ts; iv[10] 0]))

  # chars
  bads = ['\0',' ']
  cs = replace(String(cv), "-12345" => "      ")
  sta = join(split(strip(cs[1:8], bads),'.')); sta = sta[1:min(length(sta),5)]
  ll = join(split(strip(cs[17:24], bads),'.')); ll = ll[1:min(length(ll),2)]
  cc = join(split(strip(cs[161:168], bads),'.')); cc = cc[1:min(length(cc),3)]
  nn = join(split(strip(cs[169:176], bads),'.')); nn = nn[1:min(length(nn),2)]
  setfield!(S, :id, join([nn,sta,ll,cc],'.'))



  # Create dictionary if full headers are desired
  if full
    (fk, ik, ck) = get_sac_keys()
    ii = findall(fv .!= sac_nul_f)
    jj = findall(iv .!= sac_nul_i)
    S.misc = Dict{String,Any}(zip(fk[ii], fv[ii]))
    merge!(S.misc, Dict{String,Any}(zip(ik[jj], iv[jj])))
    m = Int32(0)
    for k = 1:length(ck)
      n = Int32(k == 2 ? 16 : 8)
      s = strip(String(cs[m+Int32(1):m+n]), bads)
      if length(s) > 0 && s != "-12345"
        S.misc[ck[k]] = s
      end
      m += n
    end
  end

  return S
end

# ============================================================================
# NOTE: Leave keyword arguments, even though they aren't type-stable!
# Use of "optional" variables instead is a 5x **slowdown**

"""
    S = readsac(file)

Read SAC file `file` into a SeisChannel object.

    S = readsac(file, full=true)

Specify `full=true` to read all non-empty headers into S.misc. Header names will be keys that contain the corresponding values.
"""
function readsac(fname::String; full=false::Bool)
  f = open(realpath(fname), "r")
  q = should_bswap(fname)
  seis = read_sac_stream(f, full, q)
  close(f)
  seis.src = fname
  note!(seis, string("+src: readsac ", fname))
  return seis
end


"""
    sachdr(f)

Print formatted SAC headers from file `f` to stdout.
"""
function sachdr(fname::String)
  seis = readsac(fname, full=true)
  for k in sort(collect(keys(seis.misc)))
    println(stdout, uppercase(k), ": ", string(seis.misc[k]))
  end
  return nothing
end

"""
    writesac(S::Union{SeisData,SeisEvent}[; ts=false, v=0])

Write all data in SeisData structure `S` to auto-generated SAC files. If S is a
SeisEvent, event header information is also written.
"""
function writesac(S::Union{SeisEvent,SeisData}; ts=false::Bool, v::Int64=KW.v)
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32}(undef, 0)
  if isa(S, SeisEvent)
    evt_info = map(Float32, vcat(S.hdr.loc, sac_nul_f, S.hdr.mag[1]))
    t_evt = d2u(S.hdr.ot)
    evid  = S.hdr.id == 0 ? sac_nul_s : String(S.hdr.id)
    EvL   = length(evid)
    N     = S.data.n
  else
    N     = S.n
  end
  for i = 1:N
    T = isa(S, SeisEvent) ? S.data[i] : S[i]
    b = T.t[1,2]
    dt = 1/T.fs
    (fv, iv, cv, fname) = fill_sac(T, ts, leven)

    # Values from event header
    if isa(S, SeisEvent)
      fv[40:44] = evt_info
      fv[8] = t_evt - b*μs
      cv[9+EvL:24] = cat(1, codeunits(nn), codeunits(" "^(16-EvL)))
    end

    # Data
    x = map(Float32, T.x)
    ts && (tdata = map(Float32, μs*(t_expand(T.t, dt) .- b)))

    # Write to file
    write_sac_file(fname, fv, iv, cv, x, t=tdata, ts=ts)
    v > 0  && @printf(stdout, "%s: Wrote file %s from SeisData channel %i\n", string(now()), fname, i)
  end
end
writesac(S::SeisChannel; ts=false::Bool, v::Int64=KW.v) = writesac(SeisData(S), ts=ts, v=v)

rsac(fname::String; full=false::Bool) = readsac(fname, full=full)
