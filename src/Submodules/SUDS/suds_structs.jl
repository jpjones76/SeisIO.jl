function read_struct_tag!(io::IO, v::Int64=0)
  s = read(io, UInt8)
  s == 0x53 || (close(io); error("damaged or scrambled SUDS file; can't continue."))
  m = read(io, UInt8)
  SB.sid = read(io, Int16)
  SB.nbs = read(io, Int32)
  SB.nbx = read(io, Int32)

  (v > 0) && println("suds_structtag: machine code = ", Char(m),
                      ", ID = ",          SB.sid,
                      ", struct size = ", SB.nbs, " B",
                      ", data size = ",   SB.nbx, " B",
                      )

  return nothing
end

function staident!(io::IO, v::Int64=0)
  read!(io, SB.hdr)
  fill!(SB.id, 0x00)

  # Set ID string
  j = 1
  for i = 1:2
    if SB.hdr[i] != 0x00
      SB.id[j] = SB.hdr[i]
      j += 1
    end
  end
  SB.id[j] = 0x2e
  j += 1
  for i = 5:9
    if SB.hdr[i] != 0x00
      SB.id[j] = SB.hdr[i]
      j += 1
    end
  end
  SB.id[j] = 0x2e
  SB.id[j+1] = 0x2e
  SB.id[j+2] = SB.hdr[10]
  j += 2
  setfield!(SB, :id_str, unsafe_string(pointer(getfield(SB, :id)), j))

  # Print new ID to STDOUT if v > 1
  (v > 1) && println( "id  = ",         SB.id_str,
                      ", inst code = ", Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]))
  return nothing
end

function read_chansetentry!(S::GphysData, io::IO, v::Int64)
  SB.C.inst    = read(io, Int32)
  SB.C.stream  = read(io, Int16)
  SB.C.chno    = read(io, Int16)
  staident!(io, 0)
  if v > 2
    println("id = ",          SB.id_str,
            ", inst code = ", Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]),
            ", inst = ",      SB.C.inst,
            ", stream = ",    SB.C.stream,
            ", chno = ",      SB.C.chno)
  end
  return nothing
end

# #  STAT_IDENT:  Station identification
# read_1!(S::GphysData, io::IO, v::Int64, full::Bool) = staident!(io, v)
#
# #  STRUCTTAG:  Structure to identify structures when archived together
# read_2!(S::GphysData, io::IO, v::Int64, full::Bool) = read_struct_tag!(io)

# STATIONCOMP:  Generic station component information
function read_5!(S::GphysData, io::IO, v::Int64, full::Bool)
  staident!(io, 0)
  SB.S05.az             = read(io, Int16)    # azimuth, N°E
  SB.S05.inc            = read(io, Int16)    # incidence, from vertical
  SB.S05.lat            = read(io, Float64)  # latitude, N = +
  SB.S05.lon            = read(io, Float64)  # longitude, E = +
  SB.S05.ele            = read(io, Float32)  # elevation, meters
  read!(io, SB.S05.codes)
  read!(io, SB.S05.gain)
  read!(io, SB.S05.a2d)
  SB.t_i32              = read(io, Int32)    # date/time values became effective
  read!(io, SB.S05.t_corr)

  # Post-read processing
  SB.data_type  = SB.S05.codes[9]
  sensor_type   = SB.S05.codes[8]

  # Does this station exist in S?
  i = findid(SB.id_str, S)
  if i == 0
    loc = GeoLoc( "",
                  SB.S05.lat,
                  SB.S05.lon,
                  Float64(SB.S05.ele),
                  0.0,
                  Float64(SB.S05.az),
                  Float64(SB.S05.inc)
                  )
    misc = if full
            Dict{String, Any}(
              "ic"             => Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]),
              "enclosure"      => Char(SB.S05.codes[1]),
              "annotation"     => Char(SB.S05.codes[2]),
              "recorder"       => Char(SB.S05.codes[3]),
              "rockclass"      => Char(SB.S05.codes[4]),
              "rocktype"       => Int16(SB.S05.codes[6]) << 8 | Int16(SB.S05.codes[5]),
              "sitecondition"  => Char(SB.S05.codes[7]),
              "sensor_type"    => Char(sensor_type),
              "data_type"      => Char(SB.data_type),
              "data_units"     => Char(SB.S05.codes[10]),
              "polarity"       => Char(SB.S05.codes[11]),
              "st_status"      => Char(SB.S05.codes[12]),
              "max_gain"       => SB.S05.gain[1],
              "clip_value"     => SB.S05.gain[2],
              "con_mvolts"     => SB.S05.gain[3],
              "a2d_ch"         => SB.S05.a2d[1],
              "a2d_gain"       => SB.S05.a2d[2],
              "dt_eff"         => SB.t_i32,
              "clock_corr"     => SB.S05.t_corr[1],
              "sta_delay"      => SB.S05.t_corr[2]
              )
          else
            Dict{String, Any}(
              "data_type"      => Char(SB.data_type),
              "sensor_type"    => Char(sensor_type),
              )
          end

    push!(S, SeisChannel( id = SB.id_str,
                          loc = loc,
                          misc = misc,
                          gain = Float64(SB.S05.gain[1]),
                          units = sensor_types[sensor_type]
                          )
         )
    i = S.n
  end
  return i
end

# MUXDATA:  Header for (possibly) multiplexed data
function read_6!(S::GphysData, io::IO, v::Int64, full::Bool)
  SB.T.net      = read(io, UInt16)
  skip(io, 2)
  SB.t_f64      = read(io, Float64)
  SB.t_i16      = read(io, Int16)
  SB.T.n_ch     = read(io, Int16)
  SB.fs         = read(io, Float32)
  SB.data_type  = read(io, UInt8)
  skip(io, 3)
  SB.T.ns       = read(io, Int32)
  SB.nz         = read(io, Int32)

  if v > 1
    println("net = ",         Char(SB.T.net & 0x00ff), Char(SB.T.net >> 8),
            ", btime = ",     u2d(SB.t_f64),
            ", loctime = ",   SB.t_i16,
            ", n = ",         SB.T.n_ch,
            ", fs = ",        SB.fs,
            ", data_type = ", Char(SB.data_type),
            ", n sweeps = ",  SB.T.ns,
            ", nx = ",        SB.nz
            )
  end

  # return (net, data_type, btime, loctime, numchans, fs, data_type, nx)
  return nothing
end

#=  DESCRIPTRACE:  Descriptive information about a seismic trace.
                   Normally followed by waveform data =#
function read_7!(S::GphysData, io::IO, v::Int64, full::Bool)
  staident!(io, 0)
  SB.t_f64       = read(io, Float64)
  SB.t_i16       = read(io, Int16)
  SB.data_type   = read(io, UInt8)
  SB.T.desc      = read(io, UInt8)
  skip(io, 4)
  SB.nz          = read(io, Int32)
  SB.fs          = read(io, Float32)
  skip(io, 16)
  SB.t_f64      += read(io, Float64)
  SB.rc          = read(io, Float32)

  if v > 2
    tl = SB.t_i16
    println("id = ",          SB.id_str,
            ", inst code = ", Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]),
            ", begin = ",     u2d(SB.t_f64 + tl*60),
            " (GMT ", tl < 0 ? "-" : "+", div(tl, 60), ")",
            ", data_type = ", Char(SB.data_type),
            ", nx = ",        SB.nx,
            ", fs = ",        SB.fs + SB.rc)
  end

  # return (id, data_type, nx, Float64(fs+rc), btime+tc)
  return nothing
end

# FEATURE:  Observed phase arrival time, amplitude, and period
function read_10!(S::GphysData, io::IO, v::Int64, full::Bool)
  staident!(io, 0)
  SB.P.pc           = read(io, Int16)
  SB.P.onset        = read(io, UInt8)
  SB.P.fm           = read(io, UInt8)
  SB.P.snr          = read(io, Int16)
  skip(io, 4)
  SB.P.gr           = read(io, Int16)
  SB.t_f64          = read(io, Float64)
  SB.P.amp          = read(io, Float32)
  SB.t_f32          = read(io, Float32)
  SB.t_i32          = read(io, Int32)
  skip(io, 4)

  phase = pick_types[SB.P.pc]
  (v > 1) && println(
            "id  = ",           SB.id_str,
            ", inst code = ",   Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]),
            ", phase: ",        phase, Char(SB.P.onset), Char(SB.P.fm),
            ", t = ",           u2d(SB.t_f64),
            ", A = ",           SB.P.amp,
            ", τ = ",           SB.t_f32,
            ", SNR = ",         SB.P.snr,
            ", gain range = ",  SB.P.gr)

  if isa(S, EventTraceData)
    i = findid(SB.id_str, S)
    if i == 0
      push!(S, SeisChannel(id = SB.id_str))
      i = S.n
    end
    S.pha[i][phase] = SeisPha(amp = Float64(SB.P.amp),
                              tt = SB.t_f64,
                              pol = Char(SB.P.fm),
                              )
  end

  return nothing
end

#  ORIGIN: Information about a specific solution for a given event
function read_14!(S::GphysData, io::IO, v::Int64, full::Bool)
  SB.H.evno         = read(io, Int32)
  SB.H.auth         = read(io, Int16)
  read!(io, SB.H.chars)
  SB.H.reg          = read(io, Int32)
  SB.H.ot           = read(io, Float64)
  SB.H.lat          = read(io, Float64)
  SB.H.lon          = read(io, Float64)
  read!(io, SB.H.floats)
  read!(io, SB.H.model)
  SB.H.gap          = read(io, Int16)
  SB.H.d_min        = read(io, Float32)
  read!(io, SB.H.shorts)
  read!(io, SB.H.mag)
  SB.t_i32          = read(io, Int32)
  if v > 1
    println("evno = ",      SB.H.evno,
            ", auth = ",    SB.H.auth,
            ", codes = ",   map(Char, SB.H.chars),
            ", reg = ",     SB.H.reg,
            ", ot = ",      u2d(SB.H.ot),
            ", origin = ",  SB.H.lat, "N, ", SB.H.lon, "E, z ", SB.H.floats[1], " km",
            ", δx = ",      SB.H.floats[2], " km",
            ", δz = ",      SB.H.floats[3], " km",
            ", rms = ",     SB.H.floats[4],
            ", model = ",   String(copy(SB.H.model)),
            ", Δ = ",       SB.H.gap, "∘",
            ", d_min = ",   SB.H.d_min, " km",
            ", shorts = ",  SB.H.shorts,
            ", mag = ",     SB.H.mag,
            ", t_eff = ",   u2d(Float64(SB.t_i32))
            )
  end
  return nothing
end

# COMMENT:  Comment tag to be followed by the bytes of comment
function read_20!(S::GphysData, io::IO, v::Int64, full::Bool)
  read!(io, SB.comm_i)
  L = read(io, Int16)
  skip(io, 2)
  if v > 1
    println("structure ref. ID = ",   SB.comm_i[1],
            ", item in struct ID = ", SB.comm_i[2],
            ", L = ", L)
  end
  SB.comm_s = String(copy(read(io, L)))
  for i in 1:S.n
    if haskey(S.misc[i], "comment")
      append!(S.misc[i]["comment"], SB.comm_s)
    else
      S.misc[i]["comment"] = [SB.comm_s]
    end
  end
  (v > 2) && (printstyled("comment: \n", color=:green); println(SB.comm_s); printstyled("--\n", color=:green))
  return nothing
end

# TRIGGERS:  Earthquake detector trigger statistics
function read_25!(S::GphysData, io::IO, v::Int64, full::Bool)
  staident!(io, 0)
  shorts    = read!(io, zeros(Int16, 6))
  trig_time = read(io, Float64)
  if v > 1
    println("id = ",          SB.id_str,
            ", inst code = ", Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]),
            ", shorts = ", shorts,
            ", btime = ", u2d(trig_time))
  end
  return nothing
end

# TRIGSETTING:  Settings for earthquake trigger system
function read_26!(S::GphysData, io::IO, v::Int64, full::Bool)
  net       = read!(io, zeros(UInt8, 4))
  btime     = read(io, Float64)
  shorts    = read!(io, zeros(Int16, 6))
  t_sweep   = read(io, Float32)
  t_aper    = read(io, Float32)
  alg       = read(io, UInt8)
  skip(io, 3)
  if v > 1
    println("net = ", String(copy(net)),
            ", btime = ", u2d(btime),
            ", shorts = ", shorts,
            ", t_sweep = ", t_sweep,
            ", t_aperture = ", t_aper,
            ", alg = ", Char(alg))
  end

  return nothing
end

# EVENTSETTING:  Settings for earthquake trigger system
function read_27!(S::GphysData, io::IO, v::Int64, full::Bool)
  net       = read!(io, zeros(UInt8, 4))
  btime     = read(io, Float64)
  shorts    = read!(io, zeros(Int16, 4))
  dur_min   = read(io, Float32)
  dur_max   = read(io, Float32)
  alg       = read(io, UInt8)
  skip(io, 3)
  if v > 1
    println("net = ", String(copy(net)),
            ", btime = ", u2d(btime),
            ", shorts = ", shorts,
            ", dur_min = ", dur_min,
            ", dur_max = ", dur_max,
            ", alg = ", Char(alg))
  end

  return nothing
end

# DETECTOR
function read_28!(S::GphysData, io::IO, v::Int64, full::Bool)
  alg           = read(io, UInt8)
  event_type    = read(io, UInt8)
  net_node_id   = read!(io, Array{UInt8,1}(undef, 10))
  version       = read(io, Float32)
  event_num     = read(io, Int32)
  skip(io, 4)

  if v > 1
    println("algorithm = ", Char(alg),
            ", event_type = ", Char(event_type),
            ", net_node_id = ", String(net_node_id),
            ", version = ", version,
            ", event_num = ", event_num
            )

  end
  return nothing
end

# ATODINFO
function read_29!(S::GphysData, io::IO, v::Int64, full::Bool)
  io_addr       = read(io, Int16)
  dev_id        = read(io, Int16)
  dev_flags     = read(io, UInt16)
  ext_bufs      = read(io, Int16)
  ext_mux       = read(io, Int16)
  timing_src    = read(io, UInt8)
  trig_src      = read(io, UInt8)

  if v > 1
    println("io_addr = ", io_addr,
            ", dev_id = ", dev_id,
            ", dev_flags = ", bitstring(dev_flags),
            ", ext_bufs = ", ext_bufs,
            ", ext_mux = ", ext_mux,
            ", timing_src = ", timing_src,
            ", trig_src = ", trig_src
            )

  end
  return nothing
end

# TIMECORRECTION:  Time correction information
function read_30!(S::GphysData, io::IO, v::Int64, full::Bool)
  staident!(io, 0)
  SB.tc          = read(io, Float64)
  SB.rc          = read(io, Float32)
  SB.sync_code   = Char(read(io, UInt8))
  skip(io,1)
  SB.t_i32       = read(io, Int32)
  skip(io, 2)

  if v > 1
    println("tc = ",          SB.tc,
            ", rc = ",        SB.rc,
            ", sync_code = ", SB.sync_code,
            ", t_eff = ",     SB.t_i32)
  end

  # Check: is the second part of ID "IRIG" (i.e., a local time clock)?
  SB.irig = false
  id_b = SB.id
  i1 = findfirst(SB.id.==0x2e)+1
  i2 = findnext(SB.id.==0x2e, i1+1)-1
  if SB.id[i1:i2] == [0x49, 0x52, 0x49, 0x47] # "IRIG"
    SB.irig = true
  end

  # return (round(Int64, tc*1.0e6), rc, t_eff*1000000, SB.id_str, netflg)
  return nothing
end

#= INSTRUMENT: Instrument hardware settings, mainly PADS related
                    added by R. Banfill, Jan 1991 =#
function read_31!(S::GphysData, io::IO, v::Int64, full::Bool)
  staident!(io, 0)
  serial    = read(io, Int16)
  ncmp      = read(io, Int16)
  chno      = read(io, Int16)
  sens_type = read(io, UInt8)
  data_type = read(io, UInt8)
  void_samp = read(io, Int32)
  floats    = read!(io, zeros(Float32,10))
  t_eff     = read(io, Int32)
  pre_evt   = read(io, Float32)
  trig_num  = read(io, Int16)
  study     = read(io, 6)
  sn_serial = read(io, Int16)
  if v > 1
    println("id = ",            SB.id_str,
            ", inst code = ",   Int16(SB.hdr[12]) << 8 | Int16(SB.hdr[11]),
            ", serial = ",      serial,
            ", ncmp = ",        ncmp,
            ", chno = ",        chno,
            ", sens_type = ",   Char(sens_type),
            ", data_type = ",   Char(data_type),
            ", void_samp = ",   void_samp,
            ", floats = ",      floats,
            ", t_eff = ",       u2d(t_eff),
            ", pre_evt = ",     pre_evt,
            ", trig_num = ",    trig_num,
            ", study = ",       String(study),
            ", sn_serial = ",   sn_serial
            )
  end
  return nothing
end

# CHANSET:  Associate stations and components with sets...???
function read_32!(S::GphysData, io::IO, v::Int64, full::Bool)
  SB.C.typ        = read(io, Int16)
  SB.C.n          = read(io, Int16)
  read!(io, SB.C.sta)
  skip(io, 1)
  SB.C.tu         = read(io, Int32)
  SB.C.td         = read(io, Int32)
  if v > 1
    println("type = ",    SB.C.typ,
            ", n = ",     SB.C.n,
            ", sta = ",   String(copy(SB.C.sta)),
            ", t_up = ",  u2d(SB.C.tu),
            ", t_dn = ",  u2d(SB.C.td)
            )
    (v > 2) && printstyled("channel entries:\n", color=:green)
  end

  for i = 1:SB.C.n
    read_chansetentry!(S, io, v)
  end

  return nothing
end

# # CHANSETENTRY
# read_33!(S::GphysData, io::IO, v::Int64, full::Bool) = read_chansetentry!(S, io, v)
#
function suds_support()
  println("\nCurrent support for SUDS structures\n")
  printstyled("CODE  STRUCTURE       \n", color=:green, bold=true)
  printstyled("====  =========       \n", color=:green, bold=true)
  for i in 1:33
    str = lpad(i, 4) * "  " * suds_codes[i] * "\n"
    if i in unsupported
      printstyled(str, color=:red)
    elseif i in disp_only
      printstyled(str, color=11)
    else
      printstyled(str, color=:green, bold=true)
    end
  end
  printstyled("\n(supported = ")
  printstyled("GREEN", color=:green, bold=true)
  printstyled(", logging only = ")
  printstyled("YELLOW", color=11)
  printstyled(", unsupported = ")
  printstyled("RED", color=:red)
  printstyled(")\n")
  return nothing
end
