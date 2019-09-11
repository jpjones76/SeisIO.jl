mutable struct Blk47 <: SeedBlk
  fs::Float64
  delay::Float64
  corr::Float64
  fac::Int64
  os::Int64
end

mutable struct Blk48 <: SeedBlk
  gain::Float64
  fg::Float64
end

function dict_cleanup!(D::Union{Dict{Int64, Any},Dict{Int64, String}})
  if !isempty(D)
    for k in keys(D)
      delete!(D, k)
    end
  end
  return nothing
end

function close_channel!(S::SeisData, C::SeisChannel, stg::Int64)
  isempty(C) && return nothing
  smax = length(C.resp.fs)
  for f in (:stage, :fs, :gain, :fg, :delay, :corr, :fac, :os, :i, :o)
    deleteat!(getfield(C.resp, f), stg:smax)
  end
  push!(S, C)
  return nothing
end

function parse_dataless!(S::SeisData, io::IO, s::TimeSpec, t::TimeSpec, v::Int64, units::Bool)
  C = SeisChannel()
  R = MultiStageResp()
  resize!(BUF.hdr_old, 14)
  blk = 0
  nb = 0
  stg = 0
  nstg = 0
  codes = Array{String}
  BUF.k = 0
  if typeof(s) != String || typeof(t) != String
    d0, d1 = parsetimewin(s, t)
    ts_req = round(Int64, d2u(DateTime(d0))*1.0e6)
    te_req = round(Int64, d2u(DateTime(d1))*1.0e6)
  else
    ts_req = round(Int64, d2u(DateTime(s))*1.0e6)
    te_req = round(Int64, d2u(DateTime(t))*1.0e6)
  end
  skipping = false
  site_name = ""

  while !eof(io)
    p = position(io)
    read!(io, BUF.seq)
    BUF.k = 8
    v > 0 && println("seq = ", String(copy(BUF.seq)), ":")

    if BUF.seq[7] == 0x20
      v > 0 && println(" "^16, "(empty; skipped 4096 B)")
      skip(io, 4088)
      BUF.k = 0

    # ========================================================================
    else
      while BUF.k < 4096

        #= Buried in the SEED manual: (bottom of page 32) "If there are less
            than seven bytes remaining, the record *must* be flushed." =#
        if BUF.k > 4089
          skip(io, 4096-BUF.k)
          BUF.k = 0
          break
        end

        # Read blockette number; skip rest of record if blk == 0
        blk = string_int(io, 3)
        BUF.k += 3
        if blk == 0
          δp = 4096-BUF.k
          if v > 0
            printstyled(string(" "^16, "no blockettes left, skipping rest of record (δp = ", δp, " B); last sequence was ", String(copy(BUF.seq)), "\n"), color=:yellow, bold=true)
          end
          skip(io, δp)
          BUF.k = 0
          break
        elseif blk == 52
          if skipping == true
            skipping = false
            if v > 0
              println(" "^16, "(skipping turned off)")
            end
          end
        end

        # Read number of bytes
        nb = string_int(io, 4)-7
        BUF.k += 4

        if v > 1
          printstyled(string(" "^16, "BLK ", blk, ", ", nb , " Bytes"), color=:green, bold=true)
        end

        if skipping
          sio = blk_string_read(io, nb, v)
          v > 1 && println(" (skipped)")
          close(sio)
        else
          #= BUF.k is the counter to position within each record; below here,
             it is incremented during calls to blk_string_read
          =#

          # This is a heinous if/else block; Julia has no SWITCH statement
          # ====================================================================
          # Volume control; Char(BUF.seq[7]) == 'V'
          if blk == 10
            blk_010!(io, nb, v)
          elseif blk == 11
            blk_011!(io, nb, v)
          elseif blk == 12
            blk_012!(io, nb, v)

          # ====================================================================
          # Abbreviation control, whatever that means; Char(BUF.seq[7]) == 'A'
          elseif blk == 30
            blk_030!(io, nb, v)
          elseif blk == 31
            blk_031!(io, nb, v)
          elseif blk == 32
            blk_032!(io, nb, v)
          elseif blk == 33
            blk_033!(io, nb, v)
          elseif blk == 34
            blk_034!(io, nb, v)
          elseif blk == 41
            blk_041!(io, nb, v, units)
          elseif blk == 43
            blk_043!(io, nb, v, units)
          elseif blk == 44
            blk_044!(io, nb, v, units)
          elseif blk == 47
            blk_047!(io, nb, v)
          elseif blk == 48
            blk_048!(io, nb, v)

          # ====================================================================
          # Station (really, channel) control; Char(BUF.seq[7]) == 'S'
          elseif blk == 50
            site_name = blk_050(io, nb, v)
          elseif blk == 51
            blk_051!(io, nb, v)
          elseif blk == 52
            close_channel!(S, C, nstg > 0 ? nstg : stg + 1)
            C = SeisChannel()
            skipping = blk_052!(io, nb, C, ts_req, te_req, v)
            if isempty(C) == false
              R = C.resp
            end
            nstg = 0
          elseif blk == 53
            stg = blk_053(io, nb, v, R, units)
          elseif blk == 54
            stg = blk_054(io, nb, v, R, units)
          elseif blk == 57
            stg = blk_057(io, nb, v, R)
          elseif blk == 58
            n = blk_058(io, nb, v, C)
            if n > 0
              stg = n
            end
          elseif blk == 59
            blk_059!(io, nb, v, C, units)
          elseif blk == 60
            nstg = blk_060(io, nb, v, R)
            v > 2 && println(R.stage)
          elseif blk == 61
            stg = blk_061(io, nb, v, R, units)

          # ====================================================================
          # Not testable == not supported; no exceptions
          # send more test files if you want more blockette types covered!
          else
            @warn("unsupported blockette type -- trying to skip.")
            skip(io, nb)
          end
        end
      end
    end
    BUF.k -= 4096

  end
  seed_cleanup!(S, BUF)
  resize!(BUF.hdr_old, 12)

  # Prevent infinite concatenation
  dict_cleanup!(responses)
  dict_cleanup!(units_lookup)
  dict_cleanup!(comments)
  dict_cleanup!(abbrev)
  close_channel!(S, C, nstg > 0 ? nstg : stg + 1)
  return S
end

function read_dataless(fname::String;
  s::TimeSpec = "0001-01-01T00:00:00",
  t::TimeSpec = "9999-12-31T23:59:59",
  v::Int64 = KW.v,
  units::Bool = false)

  S = SeisData()
  io = open(fname, "r")
  skip(io, 6)
  c = read(io, UInt8)
  if c in (0x41, 0x53, 0x54, 0x56) # 'A', 'S', 'T', 'V'
    seekstart(io)
    parse_dataless!(S, io, s, t, v, units)
    close(io)
  else
    error("Not a SEED volume!")
  end
  fstr = realpath(fname)
  fill!(S.src, fstr)
  return S
end
