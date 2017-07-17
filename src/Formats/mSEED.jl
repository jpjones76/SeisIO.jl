const __SEED = SeedVol()

function unpack!(S::SeedVol)
  @inbounds for m = 0x01:0x01:S.u8[3]
    S.k += 1
    S.x[S.k] = >>(signed(<<(S.u[1], S.u8[1])), 0x20-S.u8[2])
    S.u8[1] += S.u8[2]
  end
  return nothing
end

function blk_time!(t::Array{Int32,1}, sid::IOStream, b::Bool)
  yy    = read(sid, UInt16)
  jj    = read(sid, UInt16)
  t[4]  = Int32(read(sid, UInt8))
  t[5]  = Int32(read(sid, UInt8))
  t[6]  = Int32(read(sid, UInt8))
  skip(sid, 1)
  ms    = read(sid, UInt16, 1)
  if b
    yy = bswap(yy)
    jj = bswap(jj)
    ms = bswap(ms)
  end
  t[1] = Int32(yy)
  (t[2], t[3]) = j2md(t[1], Int32(jj))
  t[7] = Int32(ms)*Int32(100)
  return nothing
end

###############################################################################
function parserec!(S::SeisData, sid::IO, v::Int)
  # =========================================================================
  # Fixed section of data header (48 bytes)
  @inbounds for i = 1:1:20
    __SEED.hdr[i]   = read(sid, UInt8)
  end
  __SEED.u16[1]     = read(sid, UInt16)
  __SEED.u16[2]     = read(sid, UInt16)
  __SEED.t[4]       = Int32(read(sid, UInt8))
  __SEED.t[5]       = Int32(read(sid, UInt8))
  __SEED.t[6]       = Int32(read(sid, UInt8))
  skip(sid, 1)
  __SEED.u16[3]     = read(sid, UInt16)
  n               = read(sid, UInt16)
  __SEED.r[1]       = read(sid, Int16)
  __SEED.r[2]       = read(sid, Int16)
  @inbounds for i = 1:1:4
    __SEED.u8[i]    = read(sid, UInt8)
  end
  tc              = read(sid, Int32)
  __SEED.u16[4]     = read(sid, UInt16)
  __SEED.u16[5]     = read(sid, UInt16)

  # =========================================================================
  # Post-read header processing

  # This is the standard check for correct byte order...?
  if (__SEED.u16[1] > 0x0bc2 || __SEED.u16[1] < 0x079e) && (__SEED.swap == false)
    __SEED.swap = true
    if ((__SEED.swap == true) && (__SEED.wo == 0x01))
      __SEED.xs = true
    end
  end
  if __SEED.swap
    __SEED.r[1] = bswap(__SEED.r[1])
    __SEED.r[2] = bswap(__SEED.r[2])
    tc = bswap(tc)
    @inbounds for i = 1:1:5
      __SEED.u16[i] = bswap(__SEED.u16[i])
    end
    n = bswap(n)
  end

  # Time
  __SEED.t[1] = Int32(__SEED.u16[1])
  (__SEED.t[2], __SEED.t[3]) = j2md(__SEED.t[1], Int32(__SEED.u16[2]))
  __SEED.t[7] = Int32(__SEED.u16[3])*Int32(100)

  # dt, n, tc (correct the time correction! hurr!)
  if __SEED.r[1] > 0.0 && __SEED.r[2] > 0.0
    __SEED.dt = 1.0/(__SEED.r[1]*__SEED.r[2])
  elseif __SEED.r[1] > 0.0
    __SEED.dt = -1.0*__SEED.r[2]/__SEED.r[1]
  elseif __SEED.r[2] > 0.0
    __SEED.dt = -1.0*__SEED.r[1]/__SEED.r[2]
  else
    __SEED.dt = __SEED.r[1]*__SEED.r[2]
  end
  TC::Int = __SEED.u8[2] == 0x01 ? 0 : Int(tc)*100

  # =========================================================================
  # Channel handling for S

  # Check this __SEED id and whether or not it exists in S
  unsafe_copy!(__SEED.id, 1, __SEED.hdr, 19, 2)
  unsafe_copy!(__SEED.id, 4, __SEED.hdr, 9, 5)
  unsafe_copy!(__SEED.id, 10, __SEED.hdr, 14, 2)
  unsafe_copy!(__SEED.id, 13, __SEED.hdr, 16, 3)
  id = unsafe_string(pointer(__SEED.id), 15)
  id = replace(id, ' ', "")
  c = findid(id, S)

  if c == 0
    C = SeisChannel()
    C.name = id
    C.id = id
    C.fs = 1.0/__SEED.dt
    C.x = Array{Float64,1}(__SEED.def.nx)
    C.misc["xi"] = 0
    push!(S, C)

    L = __SEED.def.nx
    te = 0
    c = S.n

    (v > 1) && println(STDOUT, "Added channel: ", S.id[c])
  else
    # assumes fs doesn't change within a SeisData structure
    L = length(S.x[c])
    te = getindex(sum(S.t[c], 1), 2) + round(Int, L*__SEED.dt*sμ)
  end
  xi = S.misc[c]["xi"]

  # =========================================================================
  # Parse blockettes
  __SEED.nsk = __SEED.u16[4] - 0x0030

  @inbounds for i = 0x01:0x01:__SEED.u8[4]
    bt = ntoh(read(sid, UInt16))    # always big-Endian? Undocumented

    if bt == 0x0064
      # [100] Sample Rate Blockette (12 bytes)
      skip(sid, 2)
      __SEED.dt = Float64(ntoh(read(sid, Float32)))
      skip(sid, 4)
      __SEED.nsk -= 0x000c

    elseif bt == 0x00c9
      # [201] Murdock Event Detection Blockette (60 bytes)
      skip(sid, 2)
      for j = 1:1:3
        __SEED.B201.sig[j]    = read(sid, Float32)
      end
      for j = 1:1:2
        __SEED.B201.flags[j]  = read(sid, UInt8, 2)
      end
      blk_time!(__SEED.B201.t, sid, __SEED.bswap)
      __SEED.B201.det         = String(read(sid, UInt8, 24))
      skip(sid, 32)
      __SEED.nsk -= 0x003c

      t_evt = round(Int, sμ*(d2u(DateTime(__SEED.B201.t[1:6]..., 0)))) + __SEED.B201.t[7] + TC
      if haskey(S.misc[c], ["Events"])
        push!(S.misc[c]["Events"], t_evt)
      else
        S.misc[c]["Events"] = Array{Int64,1}([t_evt])
      end

    elseif bt == 0x01f4
      #  [500] Timing Blockette (200 bytes)
      skip(sid, 2)
      __SEED.B500.vco_correction    = ntoh(read(sid, Float32))
      blk_time!(__SEED.B500.t, sid, swap)
      __SEED.B500.μsec              = read(sid, Int8)
      __SEED.B500.reception_quality = read(sid, UInt8)
      __SEED.B500.exception_count   = ntoh(read(sid, UInt16))
      __SEED.B500.exception_type    = String(read(sid, UInt8, 16))
      __SEED.B500.clock_model       = String(read(sid, UInt8, 32))
      __SEED.B500.clock_status      = String(read(sid, UInt8, 128))
      __SEED.nsk -= 0x00c8
      # TO DO: correct S.t[c] when a timing blockette is detected

    elseif bt == 0x03e8
      # [1000] Data Only __SEED Blockette (8 bytes)
      skip(sid, 2)
      __SEED.fmt = read(sid, UInt8)
      __SEED.wo  = read(sid, UInt8)
      __SEED.lx  = read(sid, UInt8)
      skip(sid, 1)

      __SEED.nx   = UInt16(2^__SEED.lx)
      __SEED.xs   = ((__SEED.swap == true) && (__SEED.wo == 0x01))
      __SEED.nsk -= 0x0008

    elseif bt == 0x03e9
      # [1001] Data Extension Blockette  (8 bytes)
      skip(sid, 2)
      TC += read(sid, Int8)
      skip(sid, 2)
      __SEED.nsk -= 0x0008

    elseif bt == 0x07d0
      # [2000] Variable Length Opaque Data Blockette
      name::String
      blk_length::UInt16
      odos::UInt16
      record_number::UInt32
      flags::Tuple{UInt8, UInt8, UInt8}
      header_fields::Array{String,1}
      opaque_data::Vector{UInt8}

      # Always big-Endian?
      __SEED.B2000.blk_length     = ntoh(read(sid, UInt16))
      __SEED.B2000.odos           = ntoh(read(sid, UInt16))
      __SEED.B2000.record_number  = ntoh(read(sid, UInt32))
      for j = 1:1:3
        __SEED.B2000.flags[j]       = read(sid, UInt8)
      end
      __SEED.B2000.header_fields  = String[String(j) for j in split(String(read(sid, UInt8, Int(__SEED.B2000.odos)-15)), '\~', keep=true, limit=__SEED.B2000.flags[3])]
      __SEED.B2000.opaque_data    = read(sid, UInt8, __SEED.B2000.blk_length - __SEED.B2000.odos)

      # Store to S.misc[i]
      ri = string(__SEED.B2000.record_number)
      S.misc[c][ri * "_flags"] = bits(flags)
      S.misc[c][ri * "_header"] = header_fields
      S.misc[c][ri * "_data"] = opaque_data
      __SEED.nsk -= __SEED.B2000.blk_length
    else
      # I have not found other blockette types in a mini-__SEED stream/archive as of 2017-07-14
      # Similar reports from C. Trabant @ IRIS
      error(string("No support for Blockette Type ", bt))
    end
  end
  # =========================================================================
  if __SEED.nsk > 0x0000
    skip(sid, Int(__SEED.nsk))
  end
  # =========================================================================
  # Data: Adapted from rdmseed.m by Francois Beauducel <beauducel@ipgp.fr>, Institut de Physique du Globe de Paris

  # Determine start time
  dts = round(Int, sμ*(d2u(DateTime(__SEED.t[1:6]...)))) + __SEED.t[7] + TC - te
  if te == 0
    S.t[c] = Array{Int64,2}(2,2)
    S.t[c][1] = one(Int64)
    S.t[c][2] = n
    S.t[c][3] = dts
    S.t[c][4] = zero(Int64)
    nt = 2
  else
    if v > 1
      println(STDOUT, "Old end = ", te, ", New start = ", dts + te, ", diff = ", dts, " μs")
    end
    nt = size(S.t[c], 1)
    δt = S.t[c][nt,2]
    if dts + δt > round(Int64, __SEED.dt*sμ)
      S.t[c] = vcat(S.t[c][1:end-1,:], [xi+1 dts+δt; xi+n 0])
    else
      S.t[c][nt,1] = xi+n
    end
  end

  # ASCII
  if __SEED.fmt == 0x00
    __SEED.x[1:n] = map(Float64, read(sid, Int8, __SEED.nx-__SEED.u16[4]))

  # Int or Float
  elseif __SEED.fmt in [0x01, 0x03, 0x04, 0x05]
    if __SEED.fmt == 0x01
      T = Int16
    elseif __SEED.fmt == 0x03
      T = Int32
    elseif __SEED.fmt == 0x04
      T = Float32
    elseif __SEED.fmt == 0x05
      T = Float64
    end
    nv = div(__SEED.nx - __SEED.u16[4], sizeof(T))
    d = read(sid, T, nv)
    if __SEED.swap
      for i = 1:1:nv
        d[i] = ntoh(d[i])
      end
    end
    unsafe_copy!(__SEED.x, 1, d, 1, n)

  # Steim1 or Steim2
  elseif __SEED.fmt in (0x0a, 0x0b)
    nf = div(__SEED.nx-__SEED.u16[4], 0x0040)
    __SEED.k = 0
    @inbounds for i = 1:1:nf
      for j = 1:1:16
        __SEED.u[1] = __SEED.xs ? bswap(read(sid, UInt32)) : read(sid, UInt32)
        if j == 1
          __SEED.u[2] = copy(__SEED.u[1])
        end
        __SEED.u[3] = (__SEED.u[2] >> __SEED.steimvals[j]) & 0x00000003
        if __SEED.u[3] == 0x00000001
          __SEED.u8[1] = 0x00
          __SEED.u8[2] = 0x08
          __SEED.u8[3] = 0x04
        elseif __SEED.fmt == 0x0a
          __SEED.u8[1] = 0x00
          if __SEED.u[3] == 0x00000002
            __SEED.u8[2] = 0x10
            __SEED.u8[3] = 0x02
          elseif __SEED.u[3] == 0x00000003
            __SEED.u8[2] = 0x20
            __SEED.u8[3] = 0x01
          end
        else
          dd = __SEED.u[1] >> 0x0000001e
          if __SEED.u[3] == 0x00000002
            __SEED.u8[1] = 0x02
            if dd == 0x00000001
              __SEED.u8[2] = 0x1e
              __SEED.u8[3] = 0x01
            elseif dd == 0x00000002
              __SEED.u8[2] = 0x0f
              __SEED.u8[3] = 0x02
            elseif dd == 0x00000003
              __SEED.u8[2] = 0x0a
              __SEED.u8[3] = 0x03
            end
          elseif __SEED.u[3] == 0x00000003
            if dd == 0x00000000
              __SEED.u8[1] = 0x02
              __SEED.u8[2] = 0x06
              __SEED.u8[3] = 0x05
            elseif dd == 0x00000001
              __SEED.u8[1] = 0x02
              __SEED.u8[2] = 0x05
              __SEED.u8[3] = 0x06
            else
              __SEED.u8[1] = 0x04
              __SEED.u8[2] = 0x04
              __SEED.u8[3] = 0x07
            end
          end
        end
        if __SEED.u[3] != 0x00000000
          unpack!(__SEED)
        end
        if i == 1
          if j == 2
            __SEED.x0 = Float64(signed(__SEED.u[1]))
          elseif j == 3
            __SEED.xn = Float64(signed(__SEED.u[1]))
          end
        end
      end
    end

    if __SEED.wo != 0x01
      __SEED.x[1:n] = flipdim(__SEED.x[1:n], 1)
    end
    __SEED.x[1] = __SEED.x0

    # Cumsum by hand
    xa = __SEED.x0
    @inbounds for i = 2:1:n
      xa += __SEED.x[i]
      __SEED.x[i] = xa
 	  end

    # Check data values
    if abs(__SEED.x[n] - __SEED.xn) > eps()
      println(STDOUT, string("RDM__SEED: data integrity -- Steim-", __SEED.fmt - 0x09, " sequence #", String(__SEED.hdr[1:6]), " integrity check failed, last_data=", __SEED.x[n], ", should be xn=", __SEED.xn))
    end
  else
    error(@sprintf("Decoding for fmt = %i NYI!", __SEED.fmt))
  end

  # Append data
  if xi+n > L
    resize!(S.x[c], L + __SEED.def.nx)
  end
  unsafe_copy!(getfield(S,:x)[c], xi+1, __SEED.x, 1, n)

  # Ensure there's no padding
  S.misc[c]["xi"] = S.t[c][nt,1]

  return nothing
end

function parsemseed!(S::SeisData, sid::IO, v::Int)
  for i = 1:1:S.n
    S.misc[i]["xi"] = length(S.x)
  end
  while !eof(sid)
    parserec!(S, sid, v)
  end
  for i = 1:1:S.n
    if length(S.x[i]) > S.t[i][end,1]
      resize!(S.x[i], S.t[i][end,1])
    end
    if haskey(S.misc[i], "xi")
      delete!(S.misc[i], "xi")
    end
  end
  return S
end

# This overloading is degenerate, but I don't care.
function parsemseed(sid::IO, v::Int)
  S = SeisData(0)
  parsemseed!(S, sid, v)
  return S
end

function parsemseed(sid::IO, swap::Bool, v::Int)
  S = SeisData(0)
  setfield!(__SEED, :swap, swap)
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
function readmseed(fname::String; swap=false::Bool, v=0::Int)
  S = SeisData(0)
  __SEED.id[[3,9,12]]=0x2e
  setfield!(__SEED, :swap, swap)

  if isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    (search("DRMQ", read(fid, Char)) > 0) || error("Scan failed due to invalid file type")
    seek(fid, 0)
    # parsemseed!(S, __SEED, fid, v)
    parsemseed!(S, fid, v)
    close(fid)
  else
    error("Invalid file name!")
  end
  return S
end

"""
    seeddef(s, v)

Set SEED default for field `s` to value `v`. Field types, system defaults, and meanings are below.

| Name   | Default | Type            | Description                      |
|:-------|:--------|:----------------|:---------------------------------|
| nx     | 360200  | Int             | length(C.x) for new channels     |
"""
seeddef(f::Symbol, v::Any) = setfield!(__SEED.def, f, v)
seeddef(s::String, v::Any) = setfield!(__SEED.def, Symbol(s), v)
