export sachdr, writesac, writesacpz

# ============================================================================
# Utility functions not for export

# Bytes 305:308 as a littleendian Int32 should read 0x06 0x00 0x00 0x00; compare each end to 0x0a to allow older SAC versions (if version in same place?)
function should_bswap(io::IO)
  skip(io, 304)
  u = read(io, UInt8)
  skip(io, 2)
  v = read(io, UInt8)
  q::Bool = (
    # Least significant byte in u
    if 0x00 < u < 0x0a && v == 0x00
      false
    # Most significant byte in u
    elseif u == 0x00 && 0x00 < v < 0x0a
      true
    else
      error("Invalid SAC file.")
    end
    )
  return q
end

function write_sac_file(fname::String, fv::Array{Float32,1}, iv::Array{Int32,1}, cv::Array{UInt8,1}, x::Array{Float32,1};
                        t::Array{Float32,1}=Float32[],
                        ts::Bool=true)
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

function fill_sac(S::GphysChannel, ts::Bool, leven::Bool)
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
  q = should_bswap(f)
  seekstart(f)
  C = read_sac_stream(f, fv, iv, cv, full, q)
  setfield!(C, :src, fname)
  note!(C, string("+src: ", fname))
  close(f)
  push!(S,C)
  return nothing
end

# ============================================================================
# NOTE: Leave keyword arguments, even if some aren't type-stable!
# Use of "optional" variables instead is a 5x **slowdown**

"""
    sachdr(f)

Print formatted SAC headers from file `f` to stdout. Does not accept wildcard
file strings.
"""
function sachdr(fname::String)
  S = read_data("sac", fname, full=true)
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
    writesac(S::Union{SeisData}[; ts=false, v=0])

Write all data in SeisData structure `S` to auto-generated SAC files.
"""
function writesac(S::GphysData; ts::Bool=false, v::Int64=KW.v)
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32,1}(undef, 0)
  N     = S.n
  for i = 1:N
    T = getindex(S, i)
    b = T.t[1,2]
    dt = 1.0/T.fs
    (fv, iv, cv, fname) = fill_sac(T, ts, leven)

    # Data
    x = eltype(T.x) == Float32 ? getfield(T, :x) : map(Float32, T.x)
    ts && (tdata = map(Float32, μs*(t_expand(T.t, dt) .- b)))

    # Write to file
    write_sac_file(fname, fv, iv, cv, x, t=tdata, ts=ts)
    v > 0  && @printf(stdout, "%s: Wrote file %s from channel %i\n", string(now()), fname, i)
  end
  return nothing
end

function writesac(S::GphysChannel;
  fname::String="",
  ts::Bool=false,
  v::Int64=KW.v)

  b = S.t[1,2]
  dt = 1.0/S.fs
  if ts
    ift = Int32(4)
    leven = false
    tdata = Float32.(μs*(t_expand(S.t, dt) .- b))
  else
    ift = Int32(1)
    leven = true
    tdata = Array{Float32,1}(undef, 0)
  end
  (fv, iv, cv, fn) = fill_sac(S, ts, leven)

  # Data
  x = getfield(S, :x)
  if eltype(x) != Float32
    x = Float32.(x)
  end

  # Write to file
  fstr = String(
    if fname == ""
      fn
    else
      if endswith(lowercase(fname), ".sac")
        fname
      else
        fname * ".sac"
      end
    end
    )
  write_sac_file(fstr, fv, iv, cv, x, t=tdata, ts=ts)
  v > 0  && println(stdout, timestamp(), ": Wrote file ", fstr)
  return nothing
end

function add_pzchan!(S::GphysData, D::Dict{String, Any}, file::String)
  id  = D["NETWORK   (KNETWK)"] * "." *
        D["STATION    (KSTNM)"] * "." *
        D["LOCATION   (KHOLE)"] * "." *
        D["CHANNEL   (KCMPNM)"]
  i = findid(id, S)
  loc   = GeoLoc( lat = parse(Float64, D["LATITUDE"]),
                  lon = parse(Float64, D["LONGITUDE"]),
                  el  = parse(Float64, D["ELEVATION"]),
                  dep = parse(Float64, D["DEPTH"]),
                  az  = parse(Float64, D["AZIMUTH"]),
                  inc = parse(Float64, D["DIP"])-90.0
                )
  fs    = parse(Float64, D["SAMPLE RATE"])

  # gain, units; note, not "INSTGAIN", that's just a scalar multipler
  gu    = split(D["SENSITIVITY"], limit=2, keepempty=false)
  gain  = parse(Float64, gu[1])
  units = lowercase(String(gu[2]))
  if startswith(units, "(")
    units = units[2:end]
  end
  if endswith(units, ")")
    units = units[1:end-1]
  end
  units = fix_units(units2ucum(units))

  #= fix for poorly-documented fundamental shortcoming:
    "INPUT UNIT"         => "M"
    I have no idea why SACPZ uses displacement PZ =#
  u_in = fix_units(units2ucum(D["INPUT UNIT"]))
  Z = get(D, "Z", ComplexF32[])
  if u_in != units
    if u_in == "m" && units == "m/s"
      deleteat!(Z, 1)
    elseif u_in == "m" && units == "m/s2"
      deleteat!(Z, 1:2)
    end
  end

  resp = PZResp(parse(Float32, D["A0"]),
                0.0f0,
                get(D, "P", ComplexF32[]),
                Z
                )

  if i == 0
    # resp
    C = SeisChannel()
    setfield!(C, :id, id)
    setfield!(C, :name, D["DESCRIPTION"])
    setfield!(C, :loc, loc)
    setfield!(C, :fs, fs)
    setfield!(C, :gain, gain)
    setfield!(C, :resp, resp)
    setfield!(C, :units, units)
    setfield!(C, :src, file)
    setfield!(C, :misc, D)
    note!(C, "+src : read_sacpz " * file * ")")
    push!(S, C)
  else
    ts = Dates.DateTime(get(D, "START", "1970-01-01T00:00:00")).instant.periods.value*1000 - dtconst
    te = Dates.DateTime(get(D, "END", "2599-12-31T23:59:59")).instant.periods.value*1000 - dtconst
    t0 = isempty(S.t[i]) ? ts : S.t[i][1,2]
    if ts ≤ t0 ≤ te
      if S.fs[i] == 0.0
        S.fs[i] = fs
      end

      if isempty(S.units[i])
        S.units[i] = units
      end

      if S.gain[i] == 1.0
        S.gain[i] = gain
      end

      if typeof(S.resp[i]) == GenResp || isempty(S.resp[i])
        S.resp[i] = resp
      end

      if isempty(S.name[i])
        S.name[i] = D["DESCRIPTION"]
      end

      if isempty(S.loc[i])
        S.loc[i]  = loc
      end

      S.misc[i] = merge(D, S.misc[i])
    end
  end
  return nothing
end

@doc """
    read_sacpz!(S::GphysData, pzfile::String)

Read sacpz file `pzfile` into SeisIO struct `S`.

If an ID in the pz file matches channel `i` at times in `S.t[i]`:
* Fields :fs, :gain, :loc, :name, :resp, :units are overwritten if empty/unset
* Information from the pz file is merged into :misc if the corresponding keys
aren't in use.
""" read_sacpz!
function read_sacpz!(S::GphysData, file::String)
  io = open(file, "r")
  read_state = 0x00
  D = Dict{String, Any}()
  kv = Array{String, 1}(undef, 2)

  # Do this for each channel
  while true

    # EOF
    if eof(io)
      add_pzchan!(S, D, file)
      break
    end

    line = readline(io)

    # Header section
    if startswith(line, "*")
      if endswith(strip(line), "**")
        read_state += 0x01
        if read_state == 0x03
          add_pzchan!(S, D, file)
          read_state = 0x01
          D = Dict{String, Any}()
        end
      else
        kv .= strip.(split(line[2:end], ":", limit=2, keepempty=false))
        D[kv[1]] = kv[2]
      end

    # Zeros section
    elseif startswith(line, "ZEROS")
      N = parse(Int64, split(line, limit=2, keepempty=false)[2])
      D["Z"] = Array{Complex{Float32},1}(undef, N)
      for i = 1:N
        try
          mark(io)
          zc = split(readline(io), limit=2, keepempty=false)
          D["Z"][i] = complex(parse(Float32, zc[1]), parse(Float32, zc[2]))
        catch
          D["Z"][i:N] .= zero(ComplexF32)
          reset(io)
        end
      end

    # Poles section
    elseif startswith(line, "POLES")
      N = parse(Int64, split(line, limit=2, keepempty=false)[2])
      D["P"] = Array{Complex{Float32},1}(undef, N)
      for i = 1:N
        pc = split(readline(io), limit=2, keepempty=false)
        D["P"][i] = complex(parse(Float32, pc[1]), parse(Float32, pc[2]))
      end

    # Constant section
    elseif startswith(line, "CONSTANT")
      D["CONSTANT"] = String(split(line, limit=2, keepempty=false)[2])
    end
  end
  close(io)
  return S
end

@doc (@doc read_sacpz)
function read_sacpz(file::String)
  S = SeisData()
  read_sacpz!(S, file)
  return S
end

@doc """
    writesacpz(S::GphysData, pzfile::String)

Write fields from SeisIO struct `S` into sacpz file `pzfile`. Uses information
from fields :fs, :gain, :loc, :misc, :name, :resp, :units.
""" writesacpz
function writesacpz(S::GphysData, file::String)
  io = open(file, "w")
  for i in 1:S.n
    id = split(S.id[i], ".")
    created   = get(S.misc[i], "CREATED", string(u2d(time())))
    ts_str    = isempty(S.t[i]) ? "1970-01-01T00:00:00" : string(u2d(S.t[i][1,2]*1.0e-6))
    t_start   = get(S.misc[i], "START", ts_str)
    t_end     = get(S.misc[i], "END", "2599-12-31T23:59:59")
    unit_in   = get(S.misc[i], "INPUT UNIT", "?")
    unit_out  = get(S.misc[i], "OUTPUT UNIT", "?")

    Y = typeof(S.resp[i])
    if Y == GenResp
      a0 = 1.0
      P = S.resp[i][:,1]
      Z = deepcopy(S.resp[i][:,2])
    elseif Y in (PZResp, PZResp64)
      a0 = getfield(S.resp[i], :a0)
      P = getfield(S.resp[i], :p)
      Z = deepcopy(getfield(S.resp[i], :z))
    elseif Y == MultiStageResp
      j = 0
      for k = 1:length(S.resp[i].stage)
        stg = S.resp[i].stage[k]
        if typeof(stg) in (PZResp, PZResp64)
          j = k
          break
        end
      end
      if j == 0
        @warn(string("Skipped channel ", i, " (", id, "): incompatible response Type"))
        continue
      else
        a0 = getfield(S.resp[i].stage[j], :a0)
        P = getfield(S.resp[i].stage[j], :p)
        Z = deepcopy(getfield(S.resp[i].stage[j], :z))
      end
    end

    write(io, 0x2a)
    write(io, 0x20)
    write(io, fill!(zeros(UInt8, 34), 0x2a))
    write(io, 0x0a)

    write(io, "* NETWORK   (KNETWK): ", id[1], 0x0a)
    write(io, "* STATION    (KSTNM): ", id[2], 0x0a)
    write(io, "* LOCATION   (KHOLE): ", isempty(id[3]) ? "  " : id[3], 0x0a)
    write(io, "* CHANNEL   (KCMPNM): ", id[4], 0x0a)

    write(io, "* CREATED           : ", created, 0x0a)
    write(io, "* START             : ", t_start, 0x0a)
    write(io, "* END               : ", t_end, 0x0a)
    write(io, "* DESCRIPTION       : ", S.name[i], 0x0a)
    write(io, "* LATITUDE          : ", @sprintf("%0.6f", S.loc[i].lat), 0x0a)
    write(io, "* LONGITUDE         : ", @sprintf("%0.6f", S.loc[i].lon), 0x0a)
    write(io, "* ELEVATION         : ", string(S.loc[i].el), 0x0a)
    write(io, "* DEPTH             : ", string(S.loc[i].dep), 0x0a)
    write(io, "* DIP               : ", string(S.loc[i].inc+90.0), 0x0a)
    write(io, "* AZIMUTH           : ", string(S.loc[i].az), 0x0a)
    write(io, "* SAMPLE RATE       : ", string(S.fs[i]), 0x0a)

    for j in ("INPUT UNIT", "OUTPUT UNIT", "INSTTYPE", "INSTGAIN", "COMMENT")
      write(io, 0x2a, 0x20)
      write(io, rpad(j, 18))
      write(io, 0x3a, 0x20)
      v = get(S.misc[i], j, "")
      write(io, v)
      if j == "INSTGAIN" && v == ""
        write(io, "1.0E+00 (", S.units[i], ")")
      end
      write(io, 0x0a)
    end

    write(io, "* SENSITIVITY       : ", @sprintf("%12.6e", S.gain[i]), 0x20, 0x28, uppercase(S.units[i]), 0x29, 0x0a)
    NZ = length(Z)
    NP = length(P)
    write(io, "* A0                : ", @sprintf("%12.6e", a0), 0x0a)
    CONST = get(S.misc[i], "CONSTANT", string(a0*S.gain[i]))

    write(io, 0x2a)
    write(io, 0x20)
    write(io, fill!(zeros(UInt8, 34), 0x2a))
    write(io, 0x0a)

    # fix for units_in always being m
    if S.units[i] == "m/s"
      NZ += 1
      pushfirst!(Z, zero(ComplexF32))
    elseif S.units[i] == "m/s2"
      NZ += 2
      prepend!(Z, zeros(ComplexF32, 2))
    end
    write(io, "ZEROS\t", string(NZ), 0x0a)
    for i = 1:NZ
      write(io, 0x09, @sprintf("%+12.6e", real(Z[i])), 0x09, @sprintf("%+12.6e", imag(Z[i])), 0x09, 0x0a)
    end

    write(io, "POLES\t", string(NP), 0x0a)
    for i = 1:NP
      write(io, 0x09, @sprintf("%+12.6e", real(P[i])), 0x09, @sprintf("%+12.6e", imag(P[i])), 0x09, 0x0a)
    end

    write(io, "CONSTANT\t", CONST, 0x0a)
    write(io, 0x0a, 0x0a)
  end
  close(io)
  return nothing
end
