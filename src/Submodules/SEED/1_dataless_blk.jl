# ===========================================================================
# VOLUME CONTROL BLOCKETTES
function blk_010!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  v > 1 && println("")
  close(sio)
  return nothing
end

function blk_011!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  if v > 1
    println("")
    if v > 2
      nsta = stream_int(sio, 3)
      println(" "^16, lpad("STA", 5), " | SEQ")
      println(" "^16, "------|-------")
      @inbounds for i = 1:nsta
        sta = String(read(sio, 5))
        seq = stream_int(sio, 6)
        println(" "^16, sta, " | ", seq)
      end
    end
  end
  close(sio)
  return nothing
end

function blk_012!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  if v > 1
    N = stream_int(sio, 4)
    println(", N_SPANS = ", N)
    if v > 2
      @inbounds for i = 1:N
        ts = string_field(sio)
        te = string_field(sio)
        seq_no = stream_int(sio, 6)
        println("ts = ", ts, ", te = ", te, ", seq #", seq_no)
      end
    end
  end
  close(sio)
  return nothing
end


# ===========================================================================
# ABBREVIATION CONTROL HEADERS

# [30] is out of scope for SeisIO
function blk_030!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  if v > 1
    desc = string_field(sio)
    code = stream_int(sio, 4)
    fam = stream_int(sio, 3)
    println(", CODE ", code, ", DESC ", desc, ", FAM ", fam)
    if v > 2
      ND = stream_int(sio, 2)
      @inbounds for i = 1:ND
        desc = string_field(sio)
        println(" "^18, desc)
      end
    end
  end
  close(sio)
  return nothing
end

function blk_031!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  k = stream_int(sio, 4)
  class = read(sio, UInt8)
  desc = string_field(sio)
  if v > 1
    units = stream_int(sio, 3)
    println(", CODE ", k, ", CLASS ", Char(class), ", DESC ", desc, ", UNITS ", units)
  end
  close(sio)
  comments[k] = replace(desc, "," => "-")

  return nothing
end

function blk_032!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  if v > 1
    code = stream_int(sio, 2)
    pub = string_field(sio)
    date = string_field(sio)
    name = string_field(sio)
    println(", CODE ", code, ", REFERENCE ", pub, ", DATE ", date, ", PUBLISHER ", name)
  end
  close(sio)

  return nothing
end

function blk_033!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)

  code = stream_int(sio, 3)
  desc = string_field(sio)
  close(sio)

  v > 1 && println(", CODE ", code, ", DESC ", desc)

  abbrev[code] = desc

  return nothing
end

function blk_034!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)

  code = stream_int(sio, 3)
  name = string_field(sio)
  if v > 1
    desc = string_field(sio)
    println(", CODE ", code, ", NAME ", name, ", DESC ", desc)
  end
  close(sio)

  units_lookup[code] = fix_units(name)

  return nothing
end

function blk_041!(io::IO, nb::Int64, v::Int64, units::Bool)
  sio = blk_string_read(io, nb, v)

  resp_lookup_key = stream_int(sio, 4)
  skip_string!(sio)
  symm_code = read(sio, UInt8)
  uic = stream_int(sio, 3)
  uoc = stream_int(sio, 3)

  #= NF can be completely wrong here. Two issues:
  (1) The SEED manual quietly suggests writing only part of "symmetric" FIR
  filters to file; in which case NF is not the length of the vector we need. =#
  NF = stream_int(sio, 4)
  if symm_code == 0x42
    NF = div(NF, 2)+1
  elseif symm_code == 0x43
    NF = div(NF, 2)
  end

  #= (2) buried in the SEED manual, it's noted that the maximum size of
  a non-data blockette length is 9999 chars, and type [41] can exceed it.
  In this case, the sample files tell me that NF is dead wrong; workaround is
  to read as many FIR values as possible and fix with append! of next packet.

  We've already used 7 chars on blockette type & size; rest are in sio.
  =#
  p = position(sio)
  NF_true = min(NF, div(9992-p, 14))

  if v > 1
    println(", KEY ", resp_lookup_key, ", SYMM ", Char(symm_code))
    if v > 2
      println(" "^16, "units in = ", units_lookup[uic])
      println(" "^16, "units out = ", units_lookup[uoc])
    end
    println(" "^16, "p = ", p, ", NF = ", NF, ", NF_true = ", NF_true)
  end
  #= This appears to fix it but results in some very odd behavior. =#

  F = Array{Float64, 1}(undef, NF_true)
  @inbounds for i = 1:NF_true
    readbytes!(sio, BUF.hdr_old, 14)
    setindex!(F, buf_to_double(BUF.hdr_old, 14), i)
  end
  close(sio)

  if v > 2
    [println("F[", i, "] = ", F[i]) for i = 1:NF_true]
  end

  # Process to resps

  if haskey(responses, resp_lookup_key)
    R = responses[resp_lookup_key][1]
    append!(R.b, F)
  else
    resp = CoeffResp(F, Float64[])
    ui = units ? fix_units(units_lookup[uic]) : ""
    uo = units ? fix_units(units_lookup[uoc]) : ""
    responses[resp_lookup_key] = (resp, ui, uo)
  end
  return nothing
end

function blk_043!(io::IO, nb::Int64, v::Int64, units::Bool)
  sio = blk_string_read(io, nb, v)
  resp_lookup_key = stream_int(sio, 4)
  skip_string!(sio)
  skip(sio, 1)
  uic = stream_int(sio, 3)
  uoc = stream_int(sio, 3)
  readbytes!(sio, BUF.hdr_old, 12)
  A0 = buf_to_double(BUF.hdr_old, 12)
  readbytes!(sio, BUF.hdr_old, 12)
  F0 = buf_to_double(BUF.hdr_old, 12)
  NZ = stream_int(sio, 3)
  Z = Array{ComplexF64, 1}(undef, NZ)
  @inbounds for i = 1:NZ
    readbytes!(sio, BUF.hdr_old, 12)
    rr = buf_to_double(BUF.hdr_old, 12)
    readbytes!(sio, BUF.hdr_old, 12)
    ii = buf_to_double(BUF.hdr_old, 12)
    Z[i] = complex(rr, ii)
    skip(sio, 24)
  end
  NP = stream_int(sio, 3)
  P = Array{ComplexF64,1}(undef, NP)
  @inbounds for i = 1:NP
    readbytes!(sio, BUF.hdr_old, 12)
    rr = buf_to_double(BUF.hdr_old, 12)
    readbytes!(sio, BUF.hdr_old, 12)
    ii = buf_to_double(BUF.hdr_old, 12)
    P[i] = complex(rr, ii)
    skip(sio, 24)
  end
  close(sio)

  if v > 1
    println("A0 = ", string(A0), "F0 = ", string(F0))
    if v > 2
      println(" "^16, "NZ = ", NZ, ":")
      @inbounds for i = 1:NZ
        println(" "^16, Z[i])
      end
      println(" "^16, "NP = ", NP, ":")
      @inbounds for i = 1:NP
        println(" "^16, P[i])
      end
    end
  end

  # Process to resps
  R = PZResp64(a0 = A0, f0 = F0, z = Z, p = P)
  ui = units ? fix_units(units_lookup[uic]) : ""
  uo = units ? fix_units(units_lookup[uoc]) : ""
  responses[resp_lookup_key] = (R, ui, uo)

  return nothing
end

function blk_044!(io::IO, nb::Int64, v::Int64, units::Bool)
  sio = blk_string_read(io, nb, v)

  resp_lookup_key = stream_int(sio, 4)
  skip_string!(sio)
  skip(sio, 1)
  uic = stream_int(sio, 3)
  uoc = stream_int(sio, 3)
  NN = stream_int(sio, 4)
  N = Array{Float64,1}(undef, NN)
  @inbounds for i = 1:NN
    readbytes!(sio, BUF.hdr_old, 12)
    N[i] = buf_to_double(BUF.hdr_old, 12)
    skip(sio, 12)
  end
  ND = stream_int(sio, 4)
  D = Array{Float64,1}(undef, ND)
  @inbounds for i = 1:ND
    readbytes!(sio, BUF.hdr_old, 12)
    D[i] = buf_to_double(BUF.hdr_old, 12)
    skip(sio, 12)
  end
  close(sio)

  if v > 1
    println(", KEY ", resp_lookup_key)
    if v > 2
      println(" "^16, "units in code = ", uic)
      println(" "^16, "units out code = ", uoc)
      println(" "^16, "NN = ", NN, ":")
      @inbounds for i = 1:NN
        println(" "^16, N[i])
      end
      println(" "^16, "ND = ", ND, ":")
      @inbounds for i = 1:min(ND)
        println(" "^16, D[i])
      end
    end
  end

  if units
    responses[resp_lookup_key] = (CoeffResp(N, D),
                                  fix_units(units_lookup[uic]),
                                  fix_units(units_lookup[uoc])
                                  )
  else
    responses[resp_lookup_key] = (CoeffResp(N, D), "", "")
  end
  return nothing
end

function blk_047!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  resp_lookup_key = stream_int(sio, 4)
  skip_string!(sio)
  readbytes!(sio, BUF.hdr_old, 10)
  fs = buf_to_double(BUF.hdr_old, 10)
  fac = stream_int(sio, 5)
  os = stream_int(sio, 5)
  readbytes!(sio, BUF.hdr_old, 11)
  delay = buf_to_double(BUF.hdr_old, 11)
  readbytes!(sio, BUF.hdr_old, 11)
  corr = buf_to_double(BUF.hdr_old, 11)
  close(sio)

  if v > 1
    println(", KEY ", resp_lookup_key)
    if v > 2
      println(" "^16, "fs = ", fs)
      println(" "^16, "decimation factor = ", fac)
      println(" "^16, "decimation offset = ", os)
      println(" "^16, "delay = ", delay)
      println(" "^16, "delay correction applied = ", corr)
    end
  end

  responses[resp_lookup_key] = Blk47(fs, delay, corr, fac, os)

  return nothing
end

function blk_048!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)

  resp_lookup_key = stream_int(sio, 4)
  skip_string!(sio)
  readbytes!(sio, BUF.hdr_old, 12)
  gain = buf_to_double(BUF.hdr_old, 12)
  readbytes!(sio, BUF.hdr_old, 12)
  fg = buf_to_double(BUF.hdr_old, 12)
  nv = stream_int(sio, 2)
  # channel histories are not in the scope of SeisIO
  @inbounds for i = 1:nv
    # skip(sio, 24)
    skip_string!(sio) # should cover the 24-Byte channel history
  end
  close(sio)

  if v > 1
    println(", KEY ", resp_lookup_key)
    if v > 2
      println(" "^16, "gain = ", gain, " (f = ", fg, " Hz)")
    end
  end

  responses[resp_lookup_key] = Blk48(gain, fg)

  return nothing
end

function blk_050(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)

  # Station
  fill!(BUF.hdr, 0x00)
  p = pointer(BUF.hdr)
  unsafe_read(sio, p, 5)

  #= I make the assumption here that channel coordinates are
  correctly set in blockette 52; if this is not true, then
  :loc will not be set.

  This shortcut makes support for multiplexing impossible, though
  blockette-50 multiplexing has never been encountered in my
  test files (or in any files of the ObsPy test suite.)

  Multiplexing would be annoying as one would need to define
  new SeisData objects S_subnet of length = n_subchans and use
  append!(S, S_subnet), rather than push!(S, C); indexing would
  be a mess. But it's doable in theory.
  =#
  skip(sio, 33)
  site_name = strip(string_field(sio))
  skip(sio, 9)
  ts = string_field(sio)
  te = string_field(sio)
  uc = read(sio, UInt8)

  # Network
  p = pointer(BUF.hdr, 11)
  unsafe_read(sio, p, 2)

  close(sio)

  if v  > 1
    println(", ID = ", String(copy(BUF.id)))
    if v > 2
      println(" "^16, "site name = ", site_name)
      println(" "^16, "start date = ", ts)
      println(" "^16, "end date = ", te)
      println(" "^16, "update code = ", Char(uc))
    end
  end

  return site_name
end

# ===========================================================================
# STATION CONTROL BLOCKETTES

# not necessary
function blk_051!(io::IO, nb::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)
  if v > 1
     println("")
    if v > 2
      ts = string_field(sio)
      te = string_field(sio)
      k = stream_int(sio, 4)
      comment_level = stream_int(sio, 6)
      println(" "^16, "ts = ", ts)
      println(" "^16, "te = ", te)
      println(" "^16, "comment code key #", k)
      println(" "^16, "comment level = ", comment_level)
    end
  end
  close(sio)
  return nothing
end

function blk_052!(io::IO, nb::Int64, C::SeisChannel, ts_req::Int64, te_req::Int64, v::Int64)
  sio = blk_string_read(io, nb, v)

  # loc
  p = pointer(BUF.hdr, 6)
  unsafe_read(sio, p, 2)

  # cha
  p = pointer(BUF.hdr, 8)
  unsafe_read(sio, p, 3)
  skip(sio, 4)
  inst = stream_int(sio, 3)
  skip_string!(sio)
  units_code = stream_int(sio, 3)
  skip(sio, 3)

  # lat, lon, el, dep, az, inc
  readbytes!(sio, BUF.hdr_old, 10)
  lat = buf_to_double(BUF.hdr_old, 10)
  readbytes!(sio, BUF.hdr_old, 11)
  lon = buf_to_double(BUF.hdr_old, 11)
  readbytes!(sio, BUF.hdr_old, 7)
  el = buf_to_double(BUF.hdr_old, 7)
  readbytes!(sio, BUF.hdr_old, 5)
  dep = buf_to_double(BUF.hdr_old, 5)
  readbytes!(sio, BUF.hdr_old, 5)
  az = buf_to_double(BUF.hdr_old, 5)
  readbytes!(sio, BUF.hdr_old, 5)
  inc = 90.0 - buf_to_double(BUF.hdr_old, 5)
  skip(sio, 6)

  # fs
  readbytes!(sio, BUF.hdr_old, 10)
  fs = buf_to_double(BUF.hdr_old, 10)

  # don't really need max. drift; skip_string passes it over
  skip_string!(sio)

  # ts, te
  ts = parse_resp_date(sio, BUF.u16)
  te = parse_resp_date(sio, BUF.u16)
  if te == -56504908800000000
    te = 19880899199000000
  end
  close(sio)

  if v > 1
    println(", ID = ", String(copy(BUF.hdr)), ", INST = ", inst)
    if v > 2
      println(" "^16, "lat = ", lat, ", lon = ", lon, ", z = ", el, ", dep = ", dep, ", θ = ", az, ", ϕ = ", inc)
      println(" "^16, "fs = ", fs)
      println(" "^16, "ts = ", u2d(div(ts, 1.0e6)))
      println(" "^16, "te = ", u2d(div(te, 1.0e6)))
    end
  end

  if ts ≤ te_req && te ≥ ts_req
    update_hdr!(BUF)
    C.id = getfield(BUF, :id_str)
    C.fs = fs
    C.loc = GeoLoc(lat = lat, lon = lon, el = el, dep = dep, az = az, inc = inc)
    C.resp = MultiStageResp(12)
    C.misc["ts"] = ts
    C.misc["te"] = te
    C.misc["timespan"] = string(u2d(div(ts, 1000000))) * " : " *  string(u2d(div(te, 1000000)))
    C.misc["inst"] = get(abbrev, inst, "")
    units = get(units_lookup, units_code, "")
    C.units = fix_units(units)
    skipping = false
  else
    if v > 1
      println(" "^16, "Skipping ", String(copy(BUF.hdr)), " (not in requested time range)")
    end
    skipping = true
  end
  return skipping
end

function blk_053(io::IO, nb::Int64, v::Int64, R::MultiStageResp, units::Bool)
  sio = blk_string_read(io, nb, v)
  tft = Char(read(sio, UInt8))
  stage = stream_int(sio, 2)
  uic = stream_int(sio, 3)
  uoc = stream_int(sio, 3)
  readbytes!(sio, BUF.hdr_old, 12)
  A0 = buf_to_double(BUF.hdr_old, 12)
  readbytes!(sio, BUF.hdr_old, 12)
  F0 = buf_to_double(BUF.hdr_old, 12)
  NZ = stream_int(sio, 3)
  Z = Array{ComplexF64,1}(undef, NZ)
  @inbounds for i = 1:NZ
    readbytes!(sio, BUF.hdr_old, 12)
    rr = buf_to_double(BUF.hdr_old, 12)
    readbytes!(sio, BUF.hdr_old, 12)
    ii = buf_to_double(BUF.hdr_old, 12)
    Z[i] = complex(rr, ii)
    skip(sio, 24)
  end
  NP = stream_int(sio, 3)
  P = Array{ComplexF64,1}(undef, NP)
  @inbounds for i = 1:NP
    readbytes!(sio, BUF.hdr_old, 12)
    rr = buf_to_double(BUF.hdr_old, 12)
    readbytes!(sio, BUF.hdr_old, 12)
    ii = buf_to_double(BUF.hdr_old, 12)
    P[i] = complex(rr, ii)
    skip(sio, 24)
  end
  close(sio)

  if v > 1
    println(", TFT ", tft, ", STAGE ", stage)
    if v > 2
      println(" "^16, "units in code #", uic)
      println(" "^16, "units out code #", uoc)
      println(" "^16, "A0 = ", A0)
      println(" "^16, "F0 = ", F0)
      println(" "^16, "NZ = ", NZ, ":")
      @inbounds for i = 1:NZ
        println(" "^16, Z[i])
      end
      println(" "^16, "NP = ", NP, ":")
      @inbounds for i = 1:NP
        println(" "^16, P[i])
      end
    end
  end

  if stage > length(R.fs)
    append!(R, MultiStageResp(6))
  end
  resp = PZResp64(a0 = A0, f0 = F0, z = Z, p = P)
  ui = units ? fix_units(units_lookup[uic]) : ""
  uo = units ? fix_units(units_lookup[uoc]) : ""
  R.stage[stage] = resp
  R.i[stage] = ui
  R.o[stage] = uo
  return stage
end

function blk_054(io::IO, nb::Int64, v::Int64, R::MultiStageResp, units::Bool)
  sio = blk_string_read(io, nb, v)

  skip(sio, 1)
  stage = stream_int(sio, 2)
  uic = stream_int(sio, 3)
  uoc = stream_int(sio, 3)
  NN = stream_int(sio, 4)
  N = Array{Float64,1}(undef, NN)
  @inbounds for i = 1:NN
    readbytes!(sio, BUF.hdr_old, 12)
    N[i] = buf_to_double(BUF.hdr_old, 12)
    skip(sio, 12)
  end
  ND = stream_int(sio, 4)
  D = Array{Float64,1}(undef, ND)
  @inbounds for i = 1:ND
    readbytes!(sio, BUF.hdr_old, 12)
    D[i] = buf_to_double(BUF.hdr_old, 12)
    skip(sio, 12)
  end
  close(sio)

  if v > 1
    println(", STAGE ", stage)
    if v > 2
      println(" "^16, "units in code = ", uic)
      println(" "^16, "units out code = ", uoc)
      println(" "^16, "NN = ", NN, ":")
      @inbounds for i = 1:NN
        println(" "^16, N[i])
      end
      println(" "^16, "ND = ", ND, ":")
      @inbounds for i = 1:ND
        println(" "^16, D[i])
      end
    end
  end

  if stage > length(R.fs)
    append!(R, MultiStageResp(6))
  end
  R.stage[stage] = CoeffResp(N, D)
  if units
    @inbounds R.i[stage] = fix_units(units_lookup[uic])
    @inbounds R.o[stage] = fix_units(units_lookup[uoc])
  end
  return stage
end

function blk_057(io::IO, nb::Int64, v::Int64, R::MultiStageResp)
  sio = blk_string_read(io, nb, v)
  stage = stream_int(sio, 2)
  readbytes!(sio, BUF.hdr_old, 10)
  fs = buf_to_double(BUF.hdr_old, 10)
  fac = stream_int(sio, 5)
  os = stream_int(sio, 5)
  readbytes!(sio, BUF.hdr_old, 11)
  delay = buf_to_double(BUF.hdr_old, 11)
  readbytes!(sio, BUF.hdr_old, 11)
  corr = buf_to_double(BUF.hdr_old, 11)
  close(sio)

  if v > 1
    println(", STAGE #", stage)
    if v > 2
      println(" "^16, "fs = ", fs)
      println(" "^16, "decimation factor = ", fac)
      println(" "^16, "decimation offset = ", os)
      println(" "^16, "delay = ", delay)
      println(" "^16, "delay correction applied = ", corr)
    end
  end

  @inbounds R.fs[stage] = fs
  @inbounds R.delay[stage] = delay
  @inbounds R.corr[stage] = corr
  @inbounds R.fac[stage] = fac
  @inbounds R.os[stage] = os
  return stage
end

function blk_058(io::IO, nb::Int64, v::Int64, C::SeisChannel)
  sio = blk_string_read(io, nb, v)
  stage = stream_int(sio, 2)
  readbytes!(sio, BUF.hdr_old, 12)
  if stage == 0
    C.gain = buf_to_double(BUF.hdr_old, 12)
    close(sio)
    if v > 1
      println(", STAGE #", stage)
    end
    return stage
  else
    C.resp.gain[stage] = buf_to_double(BUF.hdr_old, 12)
    readbytes!(sio, BUF.hdr_old, 12)
    C.resp.fg[stage] = buf_to_double(BUF.hdr_old, 12)

    if v > 1
      println(", STAGE #", stage)
      if v > 2
        println(" "^16, "gain = ", C.resp.gain[stage], " (f = ", C.resp.fg[stage], " Hz)")
      end
    end

    # station history is not in the scope of SeisIO
    close(sio)
    return stage
  end
end

# Not in scope of SeisIO
function blk_059!(io::IO, nb::Int64, v::Int64, C::SeisChannel, units::Bool)
  sio = blk_string_read(io, nb, v)
  v > 1 && println("")
  if units
    ts = parse_resp_date(sio, BUF.u16)
    te = parse_resp_date(sio, BUF.u16)
    if te == -56504908800000000
      te = 19880899199000000
    end
    k = stream_int(sio, 4)
    tstr = string("comment,", ts, ",", te, ",", comments[k])
    if v > 2
      println(u2d(div(ts, 1000000)), "–", u2d(div(te, 1000000)), ": ", comments[k])
    end
    note!(C, tstr)
  end
  close(sio)
  return nothing
end

# Assign dictionary elements with response info in the 41-49 blockettes
function blk_060(io::IO, nb::Int64, v::Int64, R::MultiStageResp)
  sio = blk_string_read(io, nb, v)

  nstg = stream_int(sio, 2)
  if v > 1
    println(", # STAGES = ", nstg)
  end

  for i = 1:nstg
    seq = stream_int(sio, 2)
    nr = stream_int(sio, 2)
    for j = 1:nr
      k = stream_int(sio, 4)
      rr = get(responses, k, "")
      if v > 2
        printstyled(" "^16, " assigning response to stage #", seq, ":\n", color=:green, bold=true)
        println(rr)
      end

      if isa(rr, Blk48)
        @inbounds R.gain[seq] = rr.gain
        @inbounds R.fg[seq] = rr.fg
      elseif isa(rr, Blk47)
        @inbounds R.fs[seq] = rr.fs
        @inbounds R.delay[seq] = rr.delay
        @inbounds R.corr[seq] = rr.corr
        @inbounds R.fac[seq] = rr.fac
        @inbounds R.os[seq] = rr.os
      elseif typeof(rr[1]) <: InstrumentResponse
        if length(R.fs) < seq
          append!(R, MultiStageResp(6))
        end
        @inbounds R.stage[seq] = rr[1]
        @inbounds R.i[seq] = rr[2]
        @inbounds R.o[seq] = rr[3]
      end
    end
  end
  close(sio)
  return nstg
end

function blk_061(io::IO, nb::Int64, v::Int64, R::MultiStageResp, units::Bool)
  sio = blk_string_read(io, nb, v)

  stage = stream_int(sio, 2)
  skip_string!(sio)
  symm_code = Char(read(sio, UInt8))
  uic = stream_int(sio, 3)
  uoc = stream_int(sio, 3)
  NF = stream_int(sio, 4)
  F = Array{Float64,1}(undef, NF)
  @inbounds for i = 1:NF
    readbytes!(sio, BUF.hdr_old, 14)
    F[i] = buf_to_double(BUF.hdr_old, 14)
  end
  close(sio)

  if v > 1
    println(", STAGE #", stage, " , SYMM = ", Char(symm_code))
    if v > 2
      println(" "^16, "units in code #", uic)
      println(" "^16, "units out code #", uoc)
      println(" "^16, "NF = ", NF)
      @inbounds for i = 1:NF
        println(" "^16, F[i])
      end
    end
  end

  if length(R.fs) < stage
    append!(R, MultiStageResp(6))
  end
  @inbounds R.stage[stage] = CoeffResp(F, Float64[])
  if units
    @inbounds R.i[stage] = fix_units(units_lookup[uic])
    @inbounds R.o[stage] = fix_units(units_lookup[uoc])
  end
  return stage

  return nothing
end
