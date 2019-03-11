export readmseed, readmseed!
const SEED = SeedVol()

# TO DO: Account for channels where any of the relevant SeisData params
# (fs, gain, loc, resp) change within a SEED volume...these are all
# buried in currently-unsupported packet types. SEED is terrible; who
# wrote this shit format

function unpack!(S::SeedVol)
  @inbounds for m = 0x01:0x01:S.u8[3]
    S.k += 1
    S.x[S.k] = >>(signed(<<(S.u[1], S.u8[1])), 0x20-S.u8[2])
    S.u8[1] += S.u8[2]
  end
  return nothing
end

###############################################################################
function parserec!(S::SeisData, sid::IO, v::Int)
  # =========================================================================
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
  n               = read(sid, UInt16)
  SEED.r[1]       = read(sid, Int16)
  SEED.r[2]       = read(sid, Int16)
  @inbounds for i = 1:4
    SEED.u8[i]    = read(sid, UInt8)
  end
  tc              = read(sid, Int32)
  SEED.u16[4]     = read(sid, UInt16)
  SEED.u16[5]     = read(sid, UInt16)

  # =========================================================================
  # Post-read header processing

  # This is the standard check for correct byte order...?
  if (SEED.u16[1] > 0x0bc2 || SEED.u16[1] < 0x079e) && (SEED.swap == false)
    SEED.swap = true
    if ((SEED.swap == true) && (SEED.wo == 0x01))
      SEED.xs = true
    end
  end
  if SEED.swap
    v > 2 && println(stdout, "Performing byte swap")
    SEED.r[1] = bswap(SEED.r[1])
    SEED.r[2] = bswap(SEED.r[2])
    tc = bswap(tc)
    @inbounds for i = 1:5
      SEED.u16[i] = bswap(SEED.u16[i])
    end
    n = bswap(n)
  end

  # Time
  if v > 2
      println(stdout, "SEED.u16 = ", map(Int, SEED.u16))
  end
  SEED.t[1] = Int32(SEED.u16[1])
  (SEED.t[2], SEED.t[3]) = j2md(SEED.t[1], Int32(SEED.u16[2]))
  SEED.t[7] = Int32(SEED.u16[3])*Int32(100)

  # dt, n, tc (correct the time correction! hurr!)
  if SEED.r[1] > 0.0 && SEED.r[2] > 0.0
    SEED.dt = 1.0/Float64(SEED.r[1]*SEED.r[2])
  elseif SEED.r[1] > 0.0
    SEED.dt = -1.0*SEED.r[2]/SEED.r[1]
  elseif SEED.r[2] > 0.0
    SEED.dt = -1.0*SEED.r[1]/SEED.r[2]
  else
    SEED.dt = Float64(SEED.r[1]*SEED.r[2])
  end
  SEED.tc = SEED.u8[2] == 0x01 ? 0 : Int64(tc)*100

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
    xi = S.t[c][nt, 1]
    te = getindex(sum(S.t[c], dims=1),2) + round(Int64, L*SEED.dt*sμ)
  end

  # =========================================================================
  # Parse blockettes

  SEED.nsk = SEED.u16[4] - 0x0030
  SEED.u16[6] = SEED.u16[5] - 0x0030
  @inbounds for i = 0x01:0x01:SEED.u8[4]

    # DND DND DND
    skip(sid, SEED.u16[6])
    SEED.nsk -= SEED.u16[6]
    SEED.u16[5] = UInt16(position(sid) - pos)
    bt = ntoh(read(sid, UInt16))    # always big-Endian? Undocumented
    # DND DND DND

    if v > 2
      println(stdout, "Skipped SEED.u16[6] = ", SEED.u16[6], " bytes")
      println(stdout, "Relative position SEED.u16[5] = ", SEED.u16[5], " bytes from record begin")
      println(stdout, "Will seek SEED.nsk = ", SEED.nsk, " bytes from last blockete's end to data begin")
      println(stdout, "Position = ", position(sid))
      println(stdout, "Blockette type to parse = ", bt)
    end

    # DND DND DND
    SEED.u16[6] = ntoh(read(sid, UInt16)) - SEED.u16[5]
    # DND DND DND

    # Blockette parsing moved to individual functions named blk_####, e.g., blk_200
    if bt in UInt16[0x0064,0x00c9,0x01f4,0x03e8,0x03e9,0x07d0]
      blk_len = getfield(SeisIO, Symbol(string("blk_", bt)))(S, sid)
      SEED.nsk -= blk_len
      SEED.u16[6] -= blk_len
    else
      # This is only for mini-SEED.
      warn(string("No support for Blockette Type ", bt, ", channel ", id, "; attempting to skip."))
      skip(sid, SEED.u16[5]-0x0004)
    end
  end
  # =========================================================================
  if SEED.nsk > 0x0000
    skip(sid, Int(SEED.nsk))
    SEED.nsk = 0x0000
  end
  # =========================================================================
  # Data: Adapted from rdmseed.m by Francois Beauducel <beauducel@ipgp.fr>, Institut de Physique du Globe de Paris

  if v > 2
    println(stdout, "To parse = length ", n, " data blockette, ", SEED.nx-SEED.u16[4], " compressed points, fmt = ", SEED.fmt)
  end

  if xi+n > L
    v > 1 && println(stdout, "Resize S.x[", c, "] from length ", length(S.x[c]), " to length ", length(S.x[c]) + SEED.def.nx)
    resize!(S.x[c], length(S.x[c]) + SEED.def.nx)
  end

  # ASCII
  if SEED.fmt == 0x00
    SEED.x[1:n] = map(Float64, read(sid, Int8, SEED.nx-SEED.u16[4]))

  # Int or Float
  elseif SEED.fmt in [0x01, 0x03, 0x04, 0x05]
    if SEED.fmt == 0x01
      T = Int16
    elseif SEED.fmt == 0x03
      T = Int32
    elseif SEED.fmt == 0x04
      T = Float32
    elseif SEED.fmt == 0x05
      T = Float64
    end
    nv = div(SEED.nx - SEED.u16[4], sizeof(T))
    for i = 1:nv
      SEED.x[i] = Float64(SEED.swap ? ntoh(read(sid, T)) : read(sid, T))
    end
    unsafe_copyto!(getfield(S,:x)[c], xi+1, SEED.x, 1, n)

  # Steim1 or Steim2
  elseif SEED.fmt in (0x0a, 0x0b)
    nf = div(SEED.nx-SEED.u16[4], 0x0040)
    SEED.k = 0
    @inbounds for i = 1:nf
      for j = 1:16
        SEED.u[1] = SEED.xs ? bswap(read(sid, UInt32)) : read(sid, UInt32)
        if j == 1
          SEED.u[2] = copy(SEED.u[1])
        end
        SEED.u[3] = (SEED.u[2] >> SEED.steimvals[j]) & 0x00000003
        if SEED.u[3] == 0x00000001
          SEED.u8[1] = 0x00
          SEED.u8[2] = 0x08
          SEED.u8[3] = 0x04
        elseif SEED.fmt == 0x0a
          SEED.u8[1] = 0x00
          if SEED.u[3] == 0x00000002
            SEED.u8[2] = 0x10
            SEED.u8[3] = 0x02
          elseif SEED.u[3] == 0x00000003
            SEED.u8[2] = 0x20
            SEED.u8[3] = 0x01
          end
        else
          dd = SEED.u[1] >> 0x0000001e
          if SEED.u[3] == 0x00000002
            SEED.u8[1] = 0x02
            if dd == 0x00000001
              SEED.u8[2] = 0x1e
              SEED.u8[3] = 0x01
            elseif dd == 0x00000002
              SEED.u8[2] = 0x0f
              SEED.u8[3] = 0x02
            elseif dd == 0x00000003
              SEED.u8[2] = 0x0a
              SEED.u8[3] = 0x03
            end
          elseif SEED.u[3] == 0x00000003
            if dd == 0x00000000
              SEED.u8[1] = 0x02
              SEED.u8[2] = 0x06
              SEED.u8[3] = 0x05
            elseif dd == 0x00000001
              SEED.u8[1] = 0x02
              SEED.u8[2] = 0x05
              SEED.u8[3] = 0x06
            else
              SEED.u8[1] = 0x04
              SEED.u8[2] = 0x04
              SEED.u8[3] = 0x07
            end
          end
        end
        if SEED.u[3] != 0x00000000
          unpack!(SEED)
        end
        if i == 1
          if j == 2
            SEED.x0 = Float64(signed(SEED.u[1]))
          elseif j == 3
            SEED.xn = Float64(signed(SEED.u[1]))
          end
        end
      end
    end

    if SEED.wo != 0x01
      SEED.x[1:n] = reverse(SEED.x[1:n])
    end
    SEED.x[1] = SEED.x0

    # Cumsum by hand
    xa = SEED.x0
    @inbounds for i = 2:n
      xa += SEED.x[i]
      SEED.x[i] = xa
 	  end

    # Check data values
    if abs(SEED.x[n] - SEED.xn) > eps()
      println(stdout, string("RDMSEED: data integrity -- Steim-", SEED.fmt - 0x09, " sequence #", String(SEED.hdr[1:6]), " integrity check failed, last_data=", SEED.x[n], ", should be xn=", SEED.xn))
    end

    unsafe_copyto!(getfield(S,:x)[c], xi+1, SEED.x, 1, n)
    if v > 2
      println(stdout, "Added ", n, " data points")
    end
  else
    error(@sprintf("Decoding for fmt = %i NYI!", SEED.fmt))
  end

  # Correct time matrix
  dts = round(Int64, sμ*(d2u(DateTime(SEED.t[1:6]...)))) + SEED.t[7] + SEED.tc - te
  if te == 0
    S.t[c] = Array{Int64, 2}(undef, 2, 2)
    S.t[c][1] = one(Int64)
    S.t[c][2] = n
    S.t[c][3] = dts
    S.t[c][4] = zero(Int64)
  else
    if v > 1 && dts > 0
      println(stdout, "Old end = ", te, ", New start = ", dts + te, ", diff = ", dts, " μs")
    end
    δt = S.t[c][nt,2]

    # If the gap is greater than or equal to one sample, we note it
    if dts + δt >= round(Int64, SEED.dt*sμ)
      S.t[c][nt,1] += 1
      S.t[c][nt,2] += dts
      S.t[c] = vcat(S.t[c], [xi+n 0])
      nt += 1
    else
      S.t[c][nt,1] = xi+n
    end
  end

  return nothing
end

function parsemseed!(S::SeisData, sid::IO, v::Int)
  while !eof(sid)
    parserec!(S, sid, v)
  end
  for i = 1:S.n
    if length(S.x[i]) > S.t[i][end,1]
      resize!(S.x[i], S.t[i][end,1])
    end
  end
  return S
end

function parsemseed(sid::IO, swap::Bool, v::Int)
  S = SeisData(0)
  setfield!(SEED, :swap, swap)
  parsemseed!(S, sid, v)
  return S
end

"""
    S = readmseed(fname)

Read file fname in big-Endian mini-SEED format. Returns a SeisData structure.
Note: Limited functionality; cannot currently handle full SEED files or most
non-data blockettes.

Keywords:
* swap=false::Bool
* v=0::Int
"""
function readmseed(fname::String; swap=false::Bool, v::Int=KW.v)
  S = SeisData(0)
  setfield!(SEED, :swap, swap)

  if safe_isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    (findfirst(isequal(read(fid, Char)), "DRMQ") > 0) || error("Scan failed due to invalid file type")
    seek(fid, 0)
    parsemseed!(S, fid, v)
    close(fid)
  else
    error("Invalid file name!")
  end
  return S
end

"""
    readmseed!(S, fname)

Read file `fname` into `S` big-Endian mini-SEED format.
"""
function readmseed!(S::SeisData, fname::String; swap=false::Bool, v::Int=KW.v)
  setfield!(SEED, :swap, swap)

  if safe_isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    (findfirst(isequal(read(fid, Char)), "DRMQ") > 0) || error("Scan failed due to invalid file type")
    seek(fid, 0)
    parsemseed!(S, fid, v)
    close(fid)
  else
    error("Invalid file name!")
  end
  return nothing
end


# """
#     seeddef(s, v)
#
# Set SEED default for field `s` to value `v`. Field types, system defaults, and meanings are below.
#
# | Name   | Default | Type            | Description                      |
# |:-------|:--------|:----------------|:---------------------------------|
# | nx     | 360200  | Int             | length(C.x) for new channels     |
# """
# seeddef(f::Symbol, v::Any) = setfield!(SEED.def, f, v)
# seeddef(s::String, v::Any) = setfield!(SEED.def, Symbol(s), v)
