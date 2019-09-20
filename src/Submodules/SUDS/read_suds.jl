function read_suds(fname::String;
  full::Bool=false,
  v::Int64=KW.v,
  )

  sid = open(fname, "r")
  S = SeisData()

  # Tracking channels and indices
  xc = Array{UnitRange{Int64}, 1}(undef, 32)    # Array of arrays of channel indices
  xn = Array{Int64,1}(undef, 32)                # Array of lengths
  xt = Array{Int64,1}(undef, 32)                # Array of times
  xz = Array{Int64,1}(undef, 32)                # Array of segment sizes
  xnet = Array{UInt16,1}(undef, 32)             # Array of IDs mapped to UInt16
  xi = 1                                        # index into BUF.x
  xj = 0                                        # index into xc, xn
  nx = 0
  fs = 0.0
  fs_last = 0.0

  # File read ================================================================
  # Parse all structures
  cnt = 0
  while !eof(sid)
    cnt += 1
    read_struct_tag!(sid, v)
    # (struct_id, struct_len, nb) = read_struct_tag(sid, v)

    # Attempt to skip unsupported structures
    if SB.sid in unsupported
      nsk = SB.nbs + SB.nbx
      skip(sid, nsk)
      (v > 1) && @warn(string("SUDS struct #", SB.sid, " unsupported; skipped ", nsk, " B"))
      continue
    end

    v > 0 && println("reading structure code ", SB.sid)
    # 6: MUXDATA ------------------------------------------------------------
    if SB.sid == Int16(6)
      # (net, data_type, ts, loctime, Nc, fs, data_type, nz) = read_6!(S, sid, v, full)
      read_6!(S, sid, v, full)
      t0 = 1000000*round(Int64, SB.t_f64)
      (v > 2) && println("nz = ", SB.nz)
      if fs_last == 0.0
        for i in 1:SB.T.n_ch
          if S.fs[i] == 0.0
            S.fs[i] = SB.fs
          end
        end
        fs_last = SB.fs
      elseif fs_last != SB.fs
        @warn(string("fs changes in structure ", cnt))
      end
    else

      # 5: STATIONCOMP  ------------------------------------------------------
      if SB.sid == Int16(5)
        i = read_5!(S, sid, v, full)
        t0 = 1000000*Int64(SB.t_i32)

      # 7: DESCRIPTRACE  -----------------------------------------------------
      elseif SB.sid == Int16(7)
        # (id, data_type, nz, fs, ts) = read_7!(S, sid, v, full)
        read_7!(S, sid, v, full)
        t0 = 1000000*round(Int64, SB.t_f64)

      # 20: COMMENT  ---------------------------------------------------------
      elseif SB.sid == Int16(20)
        read_20!(S, sid, v, full)
        t0 = 0
        continue

      # 30: TIMECORRECTION ---------------------------------------------------
      elseif SB.sid == Int16(30)
        # (tc, rc, t_eff, id, net_flag) = read_30!(S, sid, v, full)
        read_30!(S, sid, v, full)
        SB.data_type = 0x00
        t0 = 0

      # 32: CHANSET ----------------------------------------------------------
      elseif SB.sid == Int16(32)
        read_32!(S, sid, v, full)
        SB.data_type = 0x00
        t0 = 0
        continue

      # 25-29 are skipped unless logged  -------------------------------------
    elseif SB.sid in 25:29 || SB.sid == Int16(31)
        if v > 1
          getfield(SUDS, Symbol(string("read_", SB.sid, "!")))(S, sid, v, full)
          SB.data_type = 0x00
          t0 = 0
        else
          nsk = SB.nbs + SB.nbx
          skip(sid, nsk)
          SB.data_type = 0x00
          t0 = 0
          continue
        end

      # ANYTHING ELSE  -------------------------------------------------------
      else
        getfield(SUDS, Symbol(string("read_", SB.sid, "!")))(S, sid, v, full)
        SB.data_type = 0x00
        t0 = 0
      end
      SB.nz = zero(Int32)
    end

    # Parse data
    if SB.nbx > 0
      # read and reinterpret data
      (v > 2) && println(stdout, "reading ", SB.nbx, " B")
      checkbuf_8!(BUF.buf, SB.nbx)
      readbytes!(sid, BUF.buf, SB.nbx)
      (y, sz) = suds_decode(BUF.buf, SB.data_type)
      nx = div(SB.nbx, sz)

      # Increment xj
      xj += 1
      checkbuf!(BUF.x, xi+nx)
      if xj > length(xn)
        L = length(xc)
        resize!(xc, L+32)
        resize!(xn, L+32)
        resize!(xt, L+32)
        resize!(xz, L+32)
        resize!(xnet, L+32)
      end
      copyto!(BUF.x, xi, y, 1, nx)

      # Store channel indices to xc
      if SB.sid == Int16(6)
        xc[xj] = 1:SB.T.n_ch
        xnet[xj] = SB.T.net
      elseif SB.sid == Int16(7)
        j =  findid(SB.id_str, S)
        xc[xj] = j:j
        xnet[xj] = 0x0000
      end

      # Store start indices to xn and per-segment sizes to xz. increment xi
      xn[xj] = xi
      xt[xj] = t0
      xz[xj] = SB.nz == zero(Int32) ? nx : SB.nz
      xi += nx
    end

    # if structure is a time correction, flush the suds buffers and write to S
    if SB.sid == Int16(30)

      # First identify which start times get corrected
      net = 0x0000
      tc = round(Int64, SB.tc*1.0e6)
      if SB.irig
        net = reinterpret(UInt16, SB.id[1:2])[1]
        for j = 1:xj
          if xnet[j] == net
            xt[j] += tc
          end
        end
      end
      flush_suds!(S, xc, xn, xt, xz, xj, v)

      # Adjust fs after flushing buffers, else fictitious time gaps appear
      if SB.irig
        net_str = String(copy(SB.id[1:2]))
        if SB.rc != 0.0f0
          for i = 1:S.n
            if (S.id[i][1:2] == net_str) && (S.fs[i] != SB.fs + SB.rc)
              (v > 2) && println("Adjusting S.fs[", i, "]")
              S.fs[i] += SB.rc
            end
          end
        end
      end
      xi = 1
      xj = 0
      SB.irig = false

    end
  end
  flush_suds!(S, xc, xn, xt, xz, xj, v)
  resize!(BUF.buf, 65535)
  resize!(BUF.x, 65535)

  return S
end

read_suds!(
  S::GphysData,
  fname::String;
  full::Bool=false,
  v::Int64=KW.v,
  ) = (U = read_suds(fname, full=full, v=v); append!(S,U))

function readsudsevt(fname::String;
  full::Bool=false,
  v::Int64=KW.v,
  )

  TD = read_suds(fname, full=full, v=v)
  src_auth = get(auth, Int32(SB.H.auth), "")
  m = SUDS.SB.H.shorts[6]
  mag_scale = try
    mag_scale[m]
  catch
    replace(join(Char.(reinterpret(UInt8, [m]))), "\0" => "")
  end

  # Generate empty event structs
  Mag = EQMag(val   = SB.H.mag[1],
              nst   = Int64(SB.H.shorts[7]),
              scale = mag_scale,
              src   = src_auth
              )

  # Create loc
  Loc = EQLoc(lat   = SB.H.lat,
              lon   = SB.H.lon,
              dep   = Float64(SB.H.floats[1]),
              dx    = Float64(SB.H.floats[2]),
              dy    = Float64(SB.H.floats[2]),
              dz    = Float64(SB.H.floats[3]),
              rms   = Float64(SB.H.floats[4]),
              gap   = Float64(SB.H.gap),
              dmin  = Float64(SB.H.d_min),
              nst   = Int64(SB.H.shorts[1]),
              flags = SB.H.chars[6] in (0x47, 0x4e, 0x53, 0x65, 0x66) ? 0x20 : 0x00,
              src   = get(loc_prog, Char(SB.H.chars[6]), "Unknown location program")
              )

  # Create header
  H = SeisHdr(id    = string(SB.H.evno),
              loc   = Loc,
              mag   = Mag,
              ot    = u2d(SB.H.ot),
              src   = fname
              )
  H.misc["auth"]  = src_auth
  H.misc["reg"]   = SB.H.reg
  H.misc["model"] = String(copy(SB.H.model))

  # Create event container
  Ev = SeisEvent(hdr = H, data = TD)

  return Ev
end
