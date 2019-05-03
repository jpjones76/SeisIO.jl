function hdrswap!(BUF::SeisIOBuf)
  u16 = getfield(BUF, :u16)
  @inbounds for i = 1:5
    u16[i] = bswap(u16[i])
  end
  setfield!(BUF, :n, bswap(getfield(BUF, :n)))
  setfield!(BUF, :r1, bswap(getfield(BUF, :r1)))
  setfield!(BUF, :r2, bswap(getfield(BUF, :r2)))
  setfield!(BUF, :tc, bswap(getfield(BUF, :tc)))
  return nothing
end

function update_dt!(BUF::SeisIOBuf)
  r1 = getfield(BUF, :r1)
  r2 = getfield(BUF, :r2)
  dt = 0.0
  if r1 > 0 && r2 > 0
    dt = 1.0/Float64(r1*r2)
  elseif r1 > 0
    dt = -1.0*Float64(r2/r1)
  elseif r2 > 0
    dt = -1.0*Float64(r1/r2)
  else
    dt = Float64(r1*r2)
  end
  setfield!(BUF, :dt, dt)
  setfield!(BUF, :Δ, round(Int64, sμ*dt))
  setfield!(BUF, :r1_old, r1)
  setfield!(BUF, :r2_old, r2)
  return nothing
end

function update_hdr!(BUF::SeisIOBuf)
  id_j = 0
  id = getfield(BUF, :id)
  hdr = getfield(BUF, :hdr)
  for p in id_positions
    if hdr[p] != 0x20
      id_j += 1
      id[id_j] = hdr[p]
    end
    if p == 12 || p == 5 || p == 7
      id_j += 1
      id[id_j] = id_spacer
    end
  end
  unsafe_copyto!(getfield(BUF, :hdr_old), 1, getfield(BUF, :hdr), 1, 12)
  setfield!(BUF, :id_str, unsafe_string(pointer(getfield(BUF, :id)), id_j))
  return nothing
end

###############################################################################
function parserec!(S::SeisData, BUF::SeisIOBuf, sid::IO, v::Int64, nx_new::Int64, nx_add::Int64)
  # =========================================================================
  u16 = getfield(BUF, :u16)
  u8 = getfield(BUF, :u8)
  xi = 0
  te = 0

  # Fixed section of data header (48 bytes)
  pos = position(sid)
  read!(sid, BUF.seq)
  read!(sid, BUF.hdr)
  if v > 2
      println(stdout, join(map(Char,BUF.seq), map(Char,BUF.hdr)))
  end
  u16[1]          = read(sid, UInt16)
  u16[2]          = read(sid, UInt16)
  hh              = read(sid, UInt8)
  mm              = read(sid, UInt8)
  ss              = read(sid, UInt8)
  skip(sid, 1)
  u16[3]          = read(sid, UInt16)
  BUF.n          = read(sid, UInt16)
  BUF.r1         = read(sid, Int16)
  BUF.r2         = read(sid, Int16)
  read!(sid, u8)
  BUF.tc         = read(sid, Int32)
  u16[4]          = read(sid, UInt16)
  u16[5]          = read(sid, UInt16)

  if getfield(BUF, :swap) == true
    hdrswap!(BUF)
  end

  # =========================================================================
  # Post-read header processing

  # This is the standard check for correct byte order...?
  yy = u16[1]
  jj = u16[2]
  if (jj > 0x0200 || ((jj == 0x0000 || jj == 0x0100) &&
      (yy > 0x0907 || yy < 0x707)) || yy>0x0bb8)
	  setfield!(BUF, :swap, !BUF.swap)
    if ((BUF.swap == true) && (BUF.wo == 0x01))
      BUF.xs = true
    end
    hdrswap!(BUF)
  end

  if BUF.r1 != BUF.r1_old || BUF.r2 != BUF.r2_old
    update_dt!(BUF)
  end

  n = getfield(BUF, :n)

  # =========================================================================
  # Channel handling for S

  # Check this SEED id and whether or not it exists in S
  if BUF.hdr != BUF.hdr_old
    update_hdr!(BUF)
  end
  id = getfield(BUF, :id_str)
  c = findid(id, S)

  if c == 0
    if v > 2
      println(stdout, "New channel; ID = ", id, ", S.id = ", S.id)
    end
    L = nx_new
    nt = 2
    C = SeisChannel(id = id,
                    name = id,
                    fs = 1.0/getfield(BUF, :dt),
                    x = Array{Float32, 1}(undef, L))
    push!(S, C)
    c = S.n
    (v > 1) && println(stdout, "Added channel: ", id)
    x = getindex(getfield(S, :x), c)
  else
    # assumes fs doesn't change within a SeisData structure
    t = getindex(getfield(S, :t), c)
    x = getindex(getfield(S, :x), c)
    L = lastindex(x)
    nt = div(lastindex(t), 2)
    if nt > 0
      xi = getindex(t, nt)
      te = endtime(t, getindex(getfield(S, :fs), c))
    end
    if xi + n > L
      resize!(x, xi + max(n, nx_add))
      v > 1 && println(stdout, id, ": ",
                               "resized from length ", L, " ",
                               "to length ", nx_new)
    end
  end

  # =========================================================================
  # Parse blockettes

  nsk = u16[4] - 0x0030
  u16[6] = u16[5] - 0x0030
  nblk = u8[4]
  v > 2 && println(string("Blockettes to read: ", nblk))
  @inbounds for i = 0x01:0x01:nblk

    # DND DND DND
    skip(sid, u16[6])
    nsk = nsk - u16[6]
    u16[5] = UInt16(position(sid) - pos)
    # DND DND DND

    bt            = read(sid, UInt16)
    u16[6]        = read(sid, UInt16)
    if getfield(BUF, :swap) == true
      bt = bswap(bt)
      setindex!(u16, bswap(u16[6]), 6)
    end

    # debug
    if v > 2
      printstyled(string("Position = ", position(sid), "\n"), color=:light_green)
      printstyled(string("Blockette type to read: ", bt, "\n"), color=:light_yellow)
      println(stdout, "Relative position u16[5] = ", u16[5], " bytes from record begin")
      println(stdout, "We are nsk = ", nsk, " bytes to data begin")
    end

    # Blockette parsing moved to individual functions
    if bt == 0x03e8
      blk_len = blk_1000(S, sid, c)
    elseif bt == 0x03e9
      blk_len = blk_1001(S, sid, c)
    elseif bt == 0x0064
      blk_len = blk_100(S, sid, c)
    elseif bt == 0x00c9
      blk_len = blk_201(S, sid, c)
    elseif bt == 0x01f4
      blk_len = blk_500(S, sid, c)
    elseif bt == 0x07d0
      blk_len = blk_2000(S, sid, c)
    elseif bt in BUF.calibs
      blk_len = blk_calib(S, sid, c, bt)
    else
      v > 1 && println(stdout, id, ": no support for Blockette Type ", bt, "; skipped.")
      blk_len = (u16[6] == 0x0000 ? nsk : u16[6])
      skip(sid, blk_len - 0x0004)
    end
    nsk = nsk - blk_len
    if u16[6] != 0x0000
      u16[6] = u16[6] - blk_len - u16[5]
    end
  end

  # =========================================================================
  # Data parsing: originally adapted from rdmseed.m by Francois Beauducel
  # (not very similar anymore)
  if nsk > 0x0000
    skip(sid, Int(nsk))
  end

  # Get data format
  fmt = getfield(BUF, :fmt)
  nb = getfield(BUF, :nx) - u16[4]

  # debug output
  if v > 2
    println(stdout, "To parse: nx = ", n, " sample blockette, ",
    "compressed size = ", nb, " bytes, fmt = ", fmt)
  end

  if fmt == 0x0a || fmt == 0x0b
    SEED_Steim!(sid, BUF, nb)
  elseif fmt == 0x00
    # ASCII is a special case as it's typically not data
    D = getindex(getfield(S, :misc), c)
    if !haskey(D, "seed_ascii")
      D["seed_ascii"] = Array{String,1}(undef,0)
    end
    push!(D["seed_ascii"], SEED_Char(sid, BUF, nb))
  elseif fmt in UInt8[0x01, 0x03, 0x04]
    SEED_Unenc!(sid, S, c, xi, nb)
  elseif fmt == 0x05
    SEED_Float64!(sid, S, c, xi, nb)
  elseif fmt == 0x0d || fmt == 0x0e
    SEED_Geoscope!(sid, BUF)
  elseif fmt == 0x10
    SEED_CDSN!(sid, BUF)
  elseif fmt == 0x1e
    SEED_SRO!(sid, BUF)
  elseif fmt == 0x20
    SEED_DWWSSN!(sid, BUF)
  else
    warn_str = string("readmseed, unsupported format = ", fmt, ", ", nb, " bytes skipped.")
    @warn(warn_str); note!(S, c, warn_str)
    skip(sid, nb)
    return nothing
  end

  if fmt > 0x00
    # Update S.x[c]
    if fmt > 0x05
      unsafe_copyto!(x, xi+1, getfield(BUF, :x), 1, getfield(BUF, :k))
    end

    # Update S.t[c]

    # Check for time correction
    is_tc = u8[2] >> 1 & 0x01
    tc = getfield(BUF, :tc)
    if is_tc == false && tc != zero(Int32)
      δt = Int64(tc)*100
    else
      δt = zero(Int64)
    end

    # Sample rate in μs
    Δ = getfield(BUF, :Δ)

    # Elapsed time since S.t[c] ended
    τ = y2μs(u16[1]) +
        Int64(u16[2]-one(UInt16))*86400000000 +
        Int64(hh)*3600000000 +
        Int64(mm)*60000000 +
        Int64(ss)*1000000 +
        Int64(u16[3])*100 +
        δt -
        te -
        Δ

    # New channel
    if te == 0
      setindex!(getfield(S, :t), Array{Int64, 2}(undef, 2, 2), c)
      t = getindex(getfield(S, :t), c)
      setindex!(t, one(Int64), 1)
      setindex!(t, n, 2)
      setindex!(t, τ + Δ, 3)
      setindex!(t, zero(Int64), 4)

    # Existing channel
    else
      # Time gap defined as more than half a sample
      if τ > div(Δ, 2)
        v > 1 && println(stdout, id, ": gap = ", τ, " μs (old end = ",
                                 te, ", New start = ", τ + te + Δ)
        setindex!(t, getindex(t, nt)+1, nt)
        setindex!(t, getindex(t, 2*nt)+τ, 2*nt)
        setindex!(getfield(S, :t), vcat(t, [xi+n zero(Int64)]), c)

      # No gap
      else
        setindex!(t, xi+n, nt)
      end
    end
  end
  return nothing
end
