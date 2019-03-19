const SEED = SeedVol()

cleanSEED() = (setfield!(SEED, :k, 0); setfield!(SEED, :dt, 0.0))

function hdrswap()
  for f in Symbol[:u16, :r, :tc, :n]
     setfield!(SEED, f, ntoh.(getfield(SEED, f)))
   end
   return nothing
 end

###############################################################################
function parserec!(S::SeisData, sid::IO, v::Int)
  # =========================================================================
  cleanSEED()

  # Fixed section of data header (48 bytes)
  pos = position(sid)
  @inbounds for i = 1:20
    SEED.hdr[i]   = read(sid, UInt8)
  end
  if v > 2
      println(stdout, join(map(Char,SEED.hdr)))
  end
  SEED.u16[1]     = read(sid, UInt16)
  SEED.u16[2]     = read(sid, UInt16)
  SEED.t[4]       = Int32(read(sid, UInt8))
  SEED.t[5]       = Int32(read(sid, UInt8))
  SEED.t[6]       = Int32(read(sid, UInt8))
  skip(sid, 1)
  SEED.u16[3]     = read(sid, UInt16)
  SEED.n          = read(sid, UInt16)
  SEED.r[1]       = read(sid, Int16)
  SEED.r[2]       = read(sid, Int16)
  @inbounds for i = 1:4
    SEED.u8[i]    = read(sid, UInt8)
  end
  SEED.tc         = read(sid, Int32)
  SEED.u16[4]     = read(sid, UInt16)
  SEED.u16[5]     = read(sid, UInt16)

  SEED.swap && hdrswap()

  # =========================================================================
  # Post-read header processing

  # This is the standard check for correct byte order...?
  yy = SEED.u16[1]
  jj = SEED.u16[2]
  if (jj > 0x0200 || ((jj == 0x0000 || jj == 0x0100) &&
      (yy > 0x0907 || yy < 0x707)) || yy>0x0bb8)
	  setfield!(SEED, :swap, !SEED.swap)
    if ((SEED.swap == true) && (SEED.wo == 0x01))
      SEED.xs = true
    end
    hdrswap()
  end

  # Time
  SEED.t[1] = Int32(SEED.u16[1])
  (SEED.t[2], SEED.t[3]) = j2md(SEED.t[1], Int32(SEED.u16[2]))
  SEED.t[7] = Int32(SEED.u16[3])*Int32(100)

  # dt, SEED.n, tc (correct the time correction! hurr!)
  if SEED.r[1] > 0.0 && SEED.r[2] > 0.0
    SEED.dt = 1.0/Float64(SEED.r[1]*SEED.r[2])
  elseif SEED.r[1] > 0.0
    SEED.dt = -1.0*SEED.r[2]/SEED.r[1]
  elseif SEED.r[2] > 0.0
    SEED.dt = -1.0*SEED.r[1]/SEED.r[2]
  else
    SEED.dt = Float64(SEED.r[1]*SEED.r[2])
  end

  # =========================================================================
  # Channel handling for S

  # Check this SEED id and whether or not it exists in S
  unsafe_copyto!(SEED.id, 1, SEED.hdr, 19, 2)
  unsafe_copyto!(SEED.id, 4, SEED.hdr, 9, 5)
  unsafe_copyto!(SEED.id, 10, SEED.hdr, 14, 2)
  unsafe_copyto!(SEED.id, 13, SEED.hdr, 16, 3)
  id = unsafe_string(pointer(SEED.id), 15)
  id = replace(id, ' ' => "")
  c = findid(id, S)

  if c == 0
    if v > 2
      println(stdout, "New channel; ID = ", id, ", S.id = ", S.id)
    end
    C = SeisChannel()
    C.name = id
    C.id = id
    C.fs = 1.0/SEED.dt
    C.x = Array{Float64, 1}(undef, SEED.def.nx)
    push!(S, C)

    L = SEED.def.nx
    te = 0
    c = S.n
    nt = 2
    xi = 0

    (v > 1) && println(stdout, "Added channel: ", S.id[c])
  else
    # assumes fs doesn't change within a SeisData structure
    L = length(S.x[c])
    nt = size(S.t[c], 1)
    xi = nt > 0 ? S.t[c][nt, 1] : 0
    te = endtime(S.t[c], S.fs[c])
    if xi + SEED.n > L
      nx_new = xi + SEED.def.nx
      resize!(S.x[c], nx_new)
      v > 1 && println( stdout, S.id[c], ": resized from length ", L,
                        " to length ", nx_new )
    end
  end

  # =========================================================================
  # Parse blockettes

  SEED.nsk = SEED.u16[4] - 0x0030
  SEED.u16[6] = SEED.u16[5] - 0x0030
  v > 2 && println(string("Blockettes to read: ", SEED.u8[4]))
  @inbounds for i = 0x01:0x01:SEED.u8[4]

    # DND DND DND
    skip(sid, SEED.u16[6])
    SEED.nsk -= SEED.u16[6]
    SEED.u16[5] = UInt16(position(sid) - pos)
    # DND DND DND

    bt = SEED.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)
    if v > 2
      printstyled(string("Position = ", position(sid), "\n"), color=:light_green)
      printstyled(string("Blockette type to read: ", bt, "\n"), color=:light_yellow)
      println(stdout, "Skipped SEED.u16[6] = ", SEED.u16[6], " bytes since last blockette")
      println(stdout, "Relative position SEED.u16[5] = ", SEED.u16[5], " bytes from record begin")
      println(stdout, "We are SEED.nsk = ", SEED.nsk, " bytes to data begin")
    end
    SEED.u16[6] = (SEED.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16))

    # Blockette parsing moved to individual functions named blk_####, e.g., blk_200
    if bt in SEED.parsable
      blk_len = getfield(SeisIO, Symbol(string("blk_", bt)))(S, sid, c)
    elseif bt in SEED.calibs
      blk_len = blk_calib(S, sid, c, bt)
    else
      v > 1 && println(stdout, id, ": no support for Blockette Type ", bt, "; skipped.")
      blk_len = (SEED.u16[6] == 0x0000 ? SEED.nsk : SEED.u16[6])
      skip(sid, blk_len - 0x0004)
    end
    SEED.nsk -= blk_len
    if SEED.u16[6] != 0x0000
      SEED.u16[6] -= (blk_len + SEED.u16[5])
    end
  end

  # =========================================================================
  # Data parsing: Adapted from rdmseed.m by Francois Beauducel
  if SEED.nsk > 0x0000
    skip(sid, Int(SEED.nsk))
    SEED.nsk = 0x0000
  end

  if v > 2
    println(stdout, "To parse: nx = ", SEED.n, " sample blockette, ",
    "compressed size = ", SEED.nx-SEED.u16[4], " bytes, fmt = ", SEED.fmt)
  end
  dec = get(SEED.dec, SEED.fmt, "DecErr")
  val = getfield(SeisIO, Symbol(string("SEED_", dec)))(sid)

  if dec == "Char"
    # ASCII is a special case as it's typically not data
    if !haskey(S.misc[c], "seed_ascii")
      S.misc[c]["seed_ascii"] = Array{String,1}(undef,0)
    end
    push!(S.misc[c]["seed_ascii"], val)

  else
    # Update S.x[c]
    unsafe_copyto!(getfield(S,:x)[c], xi+1, SEED.x, 1, SEED.k)

    # Correct time matrix
    nt = size(S.t[c], 1)
    tc = SEED.u8[2] == 0x01 ? 0 : Int64(SEED.tc)*100
    Δ = round(Int64, sμ/S.fs[c])
    τ = round(Int64, sμ*(d2u(DateTime(SEED.t[1:6]...)))) + SEED.t[7] + tc - te - Δ
    if te == 0
      S.t[c] = Array{Int64, 2}(undef, 2, 2)
      setindex!(S.t[c], one(Int64), 1)
      setindex!(S.t[c], SEED.n, 2)
      setindex!(S.t[c], τ+Δ, 3)
      setindex!(S.t[c], zero(Int64), 4)
    else
      if τ > div(Δ,2)
        v > 1 && println(stdout, S.id[c], ": gap = ", τ, " μs (old end = ",
                                          te, ", New start = ", τ + te + Δ)
        S.t[c][nt,1] += 1
        S.t[c][nt,2] += τ
        S.t[c] = vcat(S.t[c], [xi+SEED.n 0])
        nt += 1
      else
        S.t[c][nt,1] = xi+SEED.n
      end
    end
  end
  return nothing
end
