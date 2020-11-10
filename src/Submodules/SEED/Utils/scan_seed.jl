function find_idvec(id::Array{UInt8, 1}, ids::Array{Array{UInt8, 1}, 1})
  for j in 1:length(ids)
    if ids[j] == id
      return j
    end
  end
  return -1
end

function scanrec!(sid::IO,
  ints::Array{Int64, 1},
  ff::Array{Array{Float64, 1}, 1},
  segs::Array{Array{Int64, 1}, 1},
  ids::Array{Array{UInt8, 1}, 1},
  fs_times::Bool,
  seg_times::Bool,
  v::Integer)

  # ===================================================================
  u16 = getfield(BUF, :uint16_buf)
  flags = getfield(BUF, :flags)

  # Fixed section of data header (48 bytes)
  pos = fastpos(sid)
  rebuffer!(sid)
  seekstart(BUF.dh_buf)
  read!(BUF.dh_buf, BUF.seq)
  read!(BUF.dh_buf, BUF.hdr)
  u16[1]          = read(BUF.dh_buf, UInt16)
  u16[2]          = read(BUF.dh_buf, UInt16)
  hh              = read(BUF.dh_buf, UInt8)
  mm              = read(BUF.dh_buf, UInt8)
  ss              = read(BUF.dh_buf, UInt8)
  skip(BUF.dh_buf, 1)
  u16[3]          = read(BUF.dh_buf, UInt16)
  BUF.n           = read(BUF.dh_buf, UInt16)
  BUF.r1          = read(BUF.dh_buf, Int16)
  BUF.r2          = read(BUF.dh_buf, Int16)
  read!(BUF.dh_buf, flags)
  BUF.tc          = read(BUF.dh_buf, Int32)
  u16[4]          = read(BUF.dh_buf, UInt16)
  u16[5]          = read(BUF.dh_buf, UInt16)

  if getfield(BUF, :swap) == true
    hdrswap!(BUF)
  end

  # ==================================================================
  # Post-read header processing

  # Check for correct byte order
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

  # Number of data points
  n = getfield(BUF, :n)

  # Output
  if v > 2
    println(stdout, String(copy(BUF.seq)), " ", String(copy(BUF.hdr)), ", fs = ", 1.0/BUF.dt, ", n = ", n)
  end
  # ==================================================================
  # Channel handling

  # Index to channel ID in ids
  j = find_idvec(BUF.hdr, ids)
  if j == -1
    append!(ints, zeros(Int64, 4))
    push!(ids, copy(BUF.hdr))
    j = length(ids)

    if fs_times
      push!(ff, Float64[])
    end
    if seg_times
      push!(segs, zeros(Int64, 2))
    end
    ints[4j-1] = one(Int64)

    if v > 0
      printstyled("New channel; SEED header = ", String(copy(BUF.hdr)), "\n", color=:red, bold=true)
    end

  elseif v == 3
    println("j = ", j)
  end

  # Check for fs changes
  if (BUF.r1 != BUF.r1_old) || (BUF.r2 != BUF.r2_old)
    update_dt!(BUF)
    if fs_times
      push!(ff[j], 1.0/BUF.dt)
      push!(ff[j], zero(Float64))
      push!(ff[j], zero(Float64))
    end
    if ints[4j] != 0
      ints[4j-1] += 1
    end
  end

  # Get fs
  fs = 1.0/getfield(BUF, :dt)

  # ===================================================================
  # Parse blockettes
  # u16[5] = position within record
  # u16[6] = number of bytes to skip to next blockette

  nsk = u16[4] - 0x0030
  u16[6] = u16[5] - 0x0030
  nblk = flags[4]
  v > 1 && println(string("Number of Blockettes = ", nblk))
  v > 2 && println(stdout, "Relative position in record = ", u16[5], " B from begin, ", u16[6], " B to next blockette, ", nsk, " B to data")

  @inbounds for i in 0x01:nblk
    fastskip(sid, u16[6])
    bt            = fastread(sid, UInt16)
    u16[6]        = fastread(sid, UInt16)
    if getfield(BUF, :swap) == true
      bt          = bswap(bt)
      u16[6]      = bswap(u16[6])
    end

    # Special handling for certain time, fs corrections
    if bt == 0x0064             # [100] Sample Rate Blockette
      BUF.dt = 1.0 / Float64(BUF.swap ? ntoh(fastread(sid, Float32)) : fastread(sid, Float32))
      setfield!(BUF, :Δ, round(Int64, sμ*BUF.dt))

    # must still be parsed (nearly) in full ... could skip fmt
    elseif bt == 0x03e8         # [1000] Data Only SEED Blockette
      BUF.fmt  = fastread(sid)
      BUF.wo   = fastread(sid)
      lx       = fastread(sid)
      fastskip(sid, 1)

      BUF.nx   = 2^lx
      BUF.xs   = ((BUF.swap == true) && (BUF.wo == 0x01))
    elseif bt == 0x03e9         # [1001] Data Extension Blockette
      fastskip(sid, 1)
      BUF.tc += signed(fastread(sid))
    end

    # Get current position relative to record begin
    u16[5]        = UInt16(fastpos(sid) - pos)

    # Update bytes to next blockette or bytes to data
    if i < nblk
      u16[6]      = u16[6] - u16[5]
    else
      nsk         = u16[4] - u16[5]
    end

    if v > 1
      printstyled(string("Position = ", fastpos(sid), ", Blockette [", bt, "]\n"), color=:light_yellow)
      println(stdout, "Relative position in record = ", u16[5], " B from begin, ", u16[6], " B to next blockette, ", nsk, " B to data")
    end
  end

  # Skip to data section
  if nsk > 0x0000
    fastskip(sid, nsk)
    if (v > 2)
      println("Skipped ", nsk, " B")
      printstyled(string("Position = ", fastpos(sid), "\n"), color=:light_green)
    end
  end

  # ===================================================================
  # Skip data
  nb = getfield(BUF, :nx) - u16[4]
  v > 1 && println("Skipping ", nb, " B")
  fastskip(sid, nb)

  # Check for time correction
  is_tc = flags[2] >> 1 & 0x01
  tc = getfield(BUF, :tc)
  if is_tc == false && tc != zero(Int32)
    δt = Int64(tc)*100
  else
    δt = zero(Int64)
  end

  # Sample rate in μs
  Δ = getfield(BUF, :Δ)

  # Start time of this record
  τ = seed_time(u16, hh, mm, ss, δt)

  # if seg_times, check to update start_time
  if seg_times
    if segs[j][end-1] == 0
      segs[j][end-1] = τ
    end
  end

  # check for gap
  if ints[4j] != 0
    gap = τ - ints[4j] - Δ

    # gap found
    if abs(gap) > div(Δ, 2)
      ints[4j-2] += 1
      if seg_times
        append!(segs[j], zeros(Int64, 2))
        segs[j][end-1] = τ
      end
    end
  elseif seg_times
    segs[j][end-1] = τ
  end

  # Set end time of current segment
  ints[4j] = τ + (n-1)*Δ

  # if seg_times tracked, always update segment end time
  if seg_times
    segs[j][end] = ints[4j]
  end

  v > 2 && printstyled(string("Position = ", fastpos(sid), "\n"), color=:light_green)

  # Append number of samples to ints[4j-3]
  ints[4j-3] = ints[4j-3] + getfield(BUF, :n)

  # Logging if fs_times == true
  if fs_times
    if ff[j][end-1] == 0.0
      ff[j][end-1] = τ*1.0e-6
    end
    ff[j][end] = ints[4j]*1.0e-6
  end

  if v > 2
    println("ints[", 4j-3, "]:ints[", 4j, "] = ", ints[4j-3:4j])
  end

  # Done
  return nothing
end

# These are nearly identical to parse_mseed, parse_mseed_file
function scan_seed!(io::IO,
  ints::Array{Int64, 1},
  ff::Array{Array{Float64, 1}, 1},
  segs::Array{Array{Int64, 1}, 1},
  ids::Array{Array{UInt8, 1}, 1},
  fs_times::Bool,
  seg_times::Bool,
  v::Integer)

  while !eof(io)
    scanrec!(io, ints, ff, segs, ids, fs_times, seg_times, v)
  end

  fill!(getfield(BUF, :hdr_old), zero(UInt8))
  setfield!(BUF, :r1_old, zero(Int16))
  setfield!(BUF, :r2_old, zero(Int16))
  return nothing
end

"""
    soh = scan_seed(fname::String[, KWs])

Scan seed file `fname` and report properties in human-readable string array `soh`.

### General Keywords
* quiet (Bool): `true` to only return compact summary strings (no stdout)
* memmap (Bool): `true` to use memory mapping
* v (Integer): `v > 0` increases scan verbosity

### Output Keywords
These are all Booleans; `false` excludes from scan.
* `npts`: Number of samples per channel (default: `true`)
* `ngaps`: Number of time gaps per channel (default: `true`)
* `nfs`: Number of unique fs values per channel (default: `true`)
* `seg_times`: Exact gap times (default: `false`)
* `fs_times`: Exact times of fs changes (default: `false`)

!!! caution

    Rarely, the number of gaps reported is off-by-one from `read_data`.
"""
function scan_seed(fname::String;
    fs_times::Bool              = false,
   seg_times::Bool              = false,
      memmap::Bool              = false,
         nfs::Bool              = true,
       ngaps::Bool              = true,
        npts::Bool              = true,
       quiet::Bool              = false,
           v::Integer           = 0
           )

#=
TO DO:
* segment time tracking
=#

  # [npts ngaps nfs end_time]
  ints = Int64[]

  # [[fs_1, te_1, fs_2, te_2, ...]_1, ...]
  ff = Array{Array{Float64, 1}, 1}(undef, 0)
  ids = Array{Array{UInt8, 1}, 1}(undef, 0)
  segs = Array{Array{Int64, 1}, 1}(undef, 0)
  io  = memmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  fastskip(io, 6)
  c = fastread(io)
  if c in (0x44, 0x52, 0x4d, 0x51)
    seekstart(io)
    scan_seed!(io, ints, ff, segs, ids, fs_times, seg_times, v)
    close(io)
  else
    close(io)
    error("Invalid file type!")
  end

  # ================================================================
  # Screen output
  nc = length(ids)

  # -----------------------------------------------------------------
  # Compact output
  soh = Array{String, 1}(undef, nc)
  for j in 1:nc
    copyto!(BUF.hdr, ids[j])
    update_hdr!(BUF)
    soh[j] = string(BUF.id_str, ", ",
            "nx = ", ints[4j-3], ", ",
            "ngaps = ", ints[4j-2], ", ",
            "nfs = ", ints[4j-1])
  end
  quiet && (return soh)

  # -----------------------------------------------------------------
  # Basic counters
  println("\n", lpad("CHANNEL", 15), " ",
          npts          ? string("| ", lpad("N PTS", 11), " ") : "",
          ngaps         ? "| N GAPS " : "",
          nfs           ? "| N FS " : "",
          "\n", "-"^16,
          npts          ? string("+", "-"^13) : "",
          ngaps         ? string("+", "-"^8)  : "",
          nfs           ? string("+", "-"^5)  : "",
          )

  for j in 1:nc
    copyto!(BUF.hdr, ids[j])
    update_hdr!(BUF)
    println(lpad(BUF.id_str, 15), " ",
            npts  ? string("| ", lpad(ints[4j-3], 11), " ") : "",
            ngaps ? string("| ", lpad(ints[4j-2],  6), " ") : "",
            nfs   ? string("| ", lpad(ints[4j-1],  4), " ") : "",
            )
  end
  println("")

  # -----------------------------------------------------------------
  # Detailed tracking
  if fs_times
    # Detailed tracking strings
    for j in 1:nc
      copyto!(BUF.hdr, ids[j])
      update_hdr!(BUF)
      println(BUF.id_str * " fs tracking:\n\n" *
        lpad("TIME WINDOW", 50) * " | " * "FS\n" * "-"^51 * "+" * "---")
      nf = div(length(ff[j]), 3)
      for i in 1:nf
        println(stdout, rpad(u2d(ff[j][3i-1]), 23),
                      " -- ",
                      rpad(u2d(ff[j][3i]), 23),
                      " | ",
                      repr(ff[j][3i-2], context=:compact=>true)
                )
      end
      println("")
    end
  end

  if seg_times
    # Detailed tracking strings
    for j in 1:nc
      copyto!(BUF.hdr, ids[j])
      update_hdr!(BUF)
      println(BUF.id_str * " segment times:\n\n")
      ns = div(length(segs[j]), 2)
      for i in 1:ns
        println(stdout, rpad(u2d(segs[j][2i-1]*1.0e-6), 23),
                      " -- ",
                      rpad(u2d(segs[j][2i]*1.0e-6), 23)
                )
      end
      println("")
    end
  end


  return soh
end
