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
    te = getindex(sum(S.t[c], dims=1),2) + round(Int64, L*SEED.dt*sμ)
  end
  if xi + SEED.n > L
    v > 1 && println(stdout, "Resize S.x[", c, "] from length ",
                    length(S.x[c]), " to length ",
                    length(S.x[c]) + SEED.def.nx)
    resize!(S.x[c], length(S.x[c]) + SEED.def.nx)
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
      println(stdout, "Skipped SEED.u16[6] = ", SEED.u16[6], " bytes")
      println(stdout, "Relative position SEED.u16[5] = ", SEED.u16[5],
                      " bytes from record begin")
      println(stdout, "Will seek SEED.nsk = ", SEED.nsk,
                      " bytes from last blockete's end to data begin")
      println(stdout, "Position = ", position(sid))
      println(stdout, string("Blockette type to read: ", bt))
    end

    SEED.u16[6] = (SEED.swap ? ntoh(read(sid, UInt16)) : read(sid, UInt16)) -
                    SEED.u16[5]

    # Blockette parsing moved to individual functions named blk_####, e.g., blk_200
    if bt in UInt16[0x0064, 0x00c9, 0x01f4, 0x03e8, 0x03e9, 0x07d0]
      blk_len = getfield(SeisIO, Symbol(string("blk_", bt)))(S, sid, c)
      SEED.nsk -= blk_len
      SEED.u16[6] -= blk_len
      v > 2 && println(stdout, "Done reading blockette type ", bt, ".")
    else
      # This is only for mini-SEED.
      v > 1 && println(stdout, id, ": no support for Blockette Type ", bt, "; skipped.")
      skip(sid, SEED.u16[5] - 0x0004)
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
  if length(SEED.x) < SEED.n
    resize!(SEED.x, SEED.n)
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
    tc = SEED.u8[2] == 0x01 ? 0 : Int64(SEED.tc)*100
    dts = round(Int64, sμ*(d2u(DateTime(SEED.t[1:6]...)))) + SEED.t[7] + tc - te
    if te == 0
      S.t[c] = Array{Int64, 2}(undef, 2, 2)
      S.t[c][1] = one(Int64)
      S.t[c][2] = SEED.n
      S.t[c][3] = dts
      S.t[c][4] = zero(Int64)
    else
      if v > 1 && dts > 0
        println(stdout, "Old end = ", te, ", New start = ", dts + te, ", diff = ", dts, " μs")
      end
      δt = S.t[c][nt,2]

      # If the gap is greater than or equal to one sample, we record it
      if dts + δt >= round(Int64, SEED.dt*sμ)
        S.t[c][nt,1] += 1
        S.t[c][nt,2] += dts
        S.t[c] = vcat(S.t[c], [xi+SEED.n 0])
        nt += 1
      else
        S.t[c][nt,1] = xi+SEED.n
      end
    end
  end
  return nothing
end