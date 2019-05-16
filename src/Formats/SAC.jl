# import Base.merge!
export readsac, readsac!, sachdr, writesac

# ============================================================================
# Utility functions not for export

# Bytes 305:308 as a littleendian Int32 should read 0x06 0x00 0x00 0x00; compare each end to 0x0a to allow older SAC versions (if version in same place?)
function should_bswap(file::String)
  q::Bool = open(file, "r") do io
    skip(io, 304)
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
  cv = repeat(vcat(sac_nul_Int8, sac_nul_start, 0x20, 0x20), 24)
  cv[17:22] .= 0x20

  # Ints
  T = getfield(S, :t)
  tt = Int32[Base.parse(Int32, i) for i in split(string(u2d(T[1,2]*μs)),r"[\.\:T\-]")]
  length(tt) == 6 && append!(tt, zero(Int32))
  y = tt[1]
  j = Int32(md2j(y, tt[2], tt[3]))
  iv[1:6] = prepend!(tt[4:7], [y, j])
  iv[7] = Int32(6)
  iv[10] = Int32(length(S.x))
  iv[16] = Int32(ts ? 4 : 1)
  iv[36] = Int32(leven ? 1 : 0)

  # Floats
  dt = 1.0/S.fs
  fv[1] = Float32(dt)
  fv[4] = Float32(S.gain)
  fv[6] = rem(T[1,2], 1000)*1.0f-3
  fv[7] = Float32(dt*length(S.x) + sum(T[2:end,2])*μs)
  if !isempty(S.loc)
    loc = getfield(S, :loc)
    if typeof(loc) == GeoLoc
      fv[32] = Float32(getfield(loc, :lat))
      fv[33] = Float32(getfield(loc, :lon))
      fv[34] = Float32(getfield(loc, :el))
      fv[58] = Float32(getfield(loc, :az))
      fv[59] = Float32(getfield(loc, :inc))
    end
  end

  # Chars (ugh...)
  id = String.(split(S.id,'.'))
  ci = [169, 1, 25, 161]
  Lc = [8, 16, 8, 8]
  for i = 1:4
    if !isempty(id[i])
      L_max = Lc[i]
      si = ci[i]
      ei = ci[i] + L_max - 1
      s = codeunits(id[i])
      Ls = length(s)
      L = min(Ls, L_max)
      copyto!(cv, si, s, 1, L)
      if L < L_max
        cv[si+L:ei] .= 0x20
      end
    end
  end

  # Assign a filename
  y_s = string(y); y_s="0"^(4-length(y_s))*y_s
  j_s = string(j); j_s="0"^(3-length(j_s))*j_s
  h_s = string(tt[4]); h_s="0"^(2-length(h_s))*h_s
  m_s = string(tt[5]); m_s="0"^(2-length(m_s))*m_s
  s_s = string(tt[6]); s_s="0"^(2-length(s_s))*s_s
  ms_s = string(tt[7]); ms_s="0"^(3-length(ms_s))*ms_s
  fname = join([y_s, j_s, h_s, m_s, s_s, ms_s, id[1], id[2], id[3], id[4], "R.SAC"],'.')
  return (fv, iv, cv, fname)
end

function read_sac_stream(f::IO, fv::Array{Float32,1}, iv::Array{Int32,1}, cv::Array{UInt8,1}, full::Bool, swap::Bool)
  read!(f, fv)
  read!(f, iv)
  read!(f, cv)
  if swap == true
    fv .= bswap.(fv)
    iv .= bswap.(iv)
  end
  nx = getindex(iv, 10)
  x = Array{Float32,1}(undef, nx)
  read!(f, x)
  if swap == true
    x .= bswap.(x)
  end

  # floats
  gain = Float64(getindex(fv, 4))
  if gain == Float64(sac_nul_f)
    gain = one(Float64)
  end
  loc = GeoLoc()
  j = 0
  lf = (:lat, :lon, :el, :az, :inc)
  for k in (32,33,34,58,59)
    j += 1
    val = getindex(fv, k)
    if val != sac_nul_f
      setfield!(loc, lf[j], Float64(val))
    end
  end

  # ints
  ts = mktime(getindex(iv, 1),
              getindex(iv, 2),
              getindex(iv, 3),
              getindex(iv, 4),
              getindex(iv, 5),
              getindex(iv, 6)*Int32(1000))
  b = getindex(fv, 6)
  if b != sac_nul_f
    ts += round(Int64, b*1.0f3)
  end

  # chars
  id = zeros(UInt8, 15)
  i = 1
  while i < 193
    c = getindex(cv, i)
    if c == sac_nul_start && i < 188
      val = getindex(cv, i+1:i+5)
      if val == sac_nul_Int8
        cv[i:i+5] .= 0x20
      end
    elseif c == 0x00
      setindex!(cv, i, 0x20)
    end
    # fill ID
    if i == 1
      i = fill_id!(id, cv, i, 8, 4, 8)
    elseif i == 17
      i = fill_id!(id, cv, i, 24, 10, 11)
    elseif i == 161
      i = fill_id!(id, cv, i, 168, 13, 15)
    elseif i == 169
      i = fill_id!(id, cv, i, 176, 1, 2)
    else
      i = i+1
    end
  end
  deleteat!(id, id.==0x00)

  # Create a seischannel
  C = SeisChannel()
  setfield!(C, :id, String(id))
  setfield!(C, :fs, Float64(1.0f0/getindex(fv,1)))
  setfield!(C, :gain, Float64(gain))
  setfield!(C, :loc, loc)
  t = Array{Int64,2}(undef, 2, 2)
  setindex!(t, one(Int64), 1)
  setindex!(t, Int64(nx), 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)
  setfield!(C, :t, t)
  setfield!(C, :x, x)

  # Create dictionary if full headers are desired
  if full == true
    D = getfield(C, :misc)

    fk = getindex(sac_keys, 1)
    ik = getindex(sac_keys, 2)
    ck = getindex(sac_keys, 3)

    # Parse floats
    z = zero(Int16)
    o = one(Int16)
    k = ""
    m = z
    while m < Int16(70)
      m += o
      if fv[m] != sac_nul_f
        k = getindex(fk, m)
        D[k] = getindex(fv, m)
      end
    end

    # Parse ints
    m = z
    while m < Int16(40)
      m += o
      if iv[m] != sac_nul_i
        k = getindex(ik, m)
        D[k] = getindex(iv, m)
      end
    end

    m = z
    j = o
    while j < Int16(24)
      n = Int16(j == 2 ? 16 : 8)
      p = m + n
      ii = m
      while ii < p
        ii += o
        if getindex(cv,ii) != 0x20
          k = getindex(ck, j)
          D[k] = String(getindex(cv, m+o:p))
          break
        end
      end
      m += n
      j += o
    end
  end

  return C
end

function read_sac_file!(S::SeisData, fname::String, fv::Array{Float32,1}, iv::Array{Int32,1}, cv::Array{UInt8,1}, full::Bool)
  f = open(fname, "r")
  q = should_bswap(fname)
  C = read_sac_stream(f, fv, iv, cv, full, q)
  setfield!(C, :src, fname)
  note!(C, string("+src: readsac ", fname))
  close(f)
  push!(S,C)
  return nothing
end

# ============================================================================
# NOTE: Leave keyword arguments, even though they aren't type-stable!
# Use of "optional" variables instead is a 5x **slowdown**

@doc """
    S = readsac(fpat[, full=true])

Read SAC files matching file pattern `fpat` into a new SeisData object. `fpat`
is a string pattern that can use wild cards.

Specify `full=true` to read all non-empty headers into S.misc. Header names
will be keys that contain the corresponding values.

    readsac!(S, fpat)

Read SAC files matching file pattern `fpat` into an existing SeisData object.
`fpat` is a string pattern that can use wild cards.
""" readsac
function readsac!(S, filestr::String; full::Bool=KW.full)
  fv = getfield(BUF, :sac_fv)
  iv = getfield(BUF, :sac_iv)
  cv = getfield(BUF, :sac_cv)
  checkbuf!(fv, 70)
  checkbuf!(iv, 40)
  checkbuf!(cv, 192)

  if safe_isfile(filestr)
    read_sac_file!(S, filestr, fv, iv, cv, full)
  else
    files = ls(filestr)
    nf = length(files)
    for fname in files
      read_sac_file!(S, fname, fv, iv, cv, full)
    end
  end
  return nothing
end

@doc (@doc readsac)
function readsac(filestr::String; full::Bool=KW.full)
  S = SeisData()
  readsac!(S, filestr, full=full)
  return S
end


"""
    sachdr(f)

Print formatted SAC headers from file `f` to stdout. Does not accept wildcard
file strings.
"""
function sachdr(fname::String)
  S = readsac(fname, full=true)
  for i = 1:S.n
    D = getindex(getfield(S, :misc), i)
    src = getindex(getfield(S, :src), i)
    printstyled(string(src, "\n"), color=:light_green, bold=true)
    for k in sort(collect(keys(D)))
      println(stdout, uppercase(k), ": ", string(D[k]))
    end
  end
  return nothing
end

"""
    writesac(S::Union{SeisData,SeisEvent}[; ts=false, v=0])

Write all data in SeisData structure `S` to auto-generated SAC files. If S is
a SeisEvent, event header information is also written to the header of each SAC
file.
"""
function writesac(S::Union{SeisEvent,SeisData}; ts::Bool=false, v::Int64=KW.v)
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32}(undef, 0)
  if isa(S, SeisEvent)
    evt_info = map(Float32, vcat(S.hdr.loc, sac_nul_f, S.hdr.mag[1]))
    t_evt = d2u(S.hdr.ot)
    evid  = S.hdr.id == 0 ? "-12345  " : String(S.hdr.id)
    EvL   = length(evid)
    N     = S.data.n
  else
    N     = S.n
  end
  for i = 1:N
    T = isa(S, SeisEvent) ? S.data[i] : S[i]
    b = T.t[1,2]
    dt = 1.0/T.fs
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
