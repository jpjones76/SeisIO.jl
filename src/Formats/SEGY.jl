export segyhdr
# ============================================================================
# Utility functions not for export
function trid(i::Int16; fs=2000.0::Float64)
  S = ["DH", "HZ", "H1", "H2", "HZ", "HT", "HR"]
  return string(getbandcode(fs, fc=10.0), S[i])
end

function auto_coords(xy::Array{Int32, 1}, c::Array{Int16, 1})
  xy == Int32[0,0] && return (0.0, 0.0)
  lon = xy[1]
  lat = xy[2]
  coord_scale = c[1]
  coord_units = c[2]
  if coord_scale < 0
    coord_scale = -1 / coord_scale
  end
  lat *= coord_scale
  lon *= coord_scale
  if coord_units == 1
      iflg = lon < 0 ? -1 : 1
      x = 111132.95
      D = sqrt(lat^2+lon^2) / x
      lat = lat/x
      d = cosd(D)
      D = acosd(d / cosd(lat))
      lon = (iflg*D)
  else
    lat = Float64(lat/3600.0)
    lon = Float64(lon/3600.0)
  end
  return lat, lon
end

function do_trace(f::IO,
                  buf::Array{UInt8,1},
                  shorts::Array{Int16,1},
                  ints::Array{Int32,1},
                  passcal::Bool,
                  full::Bool,
                  src::String,
                  swap::Bool,
                  fh::Array{Int16,1}
                  )

  # First part of trace header is quite standard
  checkbuf!(ints, 29)
  checkbuf!(shorts, 62)
  readbytes!(f, buf, 180)

  intbuf = reinterpret(Int32, buf)
  copyto!(ints, 1, intbuf, 1, 7)
  copyto!(ints, 8, intbuf, 10, 8)
  copyto!(ints, 16, intbuf, 19, 4)

  shortbuf = reinterpret(Int16, buf)
  copyto!(shorts, 1, shortbuf, 1, 4)
  copyto!(shorts, 5, shortbuf, 35, 2)
  copyto!(shorts, 7, shortbuf, 45, 46)

  if passcal
    readbytes!(f, buf, 40)

    scale_fac     = read(f, Float32)
    inst_no       = read(f, UInt16)
    shorts[62]    = read(f, Int16)
    ints[21]      = read(f, Int32)
    ints[22]      = read(f, Int32)
    ints[23]      = read(f, Int32)

    setindex!(shorts, shortbuf[10], 53)
    copyto!(shorts, 54, shortbuf, 13, 8)
    setindex!(ints, intbuf[6], 20)

    if swap
      shorts     .= ntoh.(shorts)
      ints       .= ntoh.(ints)
      scale_fac   = bswap(scale_fac)
      inst_no     = bswap(inst_no)
    end

    chars = buf[1:18]
    dt    = getindex(ints,20)
    n     = getindex(shorts, 20)
    fmt   = getindex(shorts, 54)
    nx    = (n == typemax(Int16) ? getindex(ints,21) : Int32(n))
    T     = (fmt == one(Int16) ? Int32 : Int16)
    nb    = checkbuf!(buf, nx, T)

    readbytes!(f, buf, nb)
    close(f)

    # trace processing
    y = reinterpret(T, buf)
    x = Array{Float32,1}(undef, nx)
    if swap
      for i = 1:nx
        x[i] = bswap(y[i])
      end
    else
      copyto!(x, 1, y, 1, nx)
      # faster than reprocessing with fillx_ for long files
    end

    z = getindex(shorts, 5)
    δ = getindex(shorts, 21)
    fs        = 1.0e6 / Float64(δ == one(Int16) ? dt : δ)
    gain      = Float64(scale_fac)  * 10.0^(-1.0*Float64(shorts[24]) / 10.0) / Float64(shorts[23])
    lat, lon  = auto_coords(ints[18:19], shorts[6:7])
    if abs(lat) < 0.1 && abs(lon) < 0.1
      lat *= 3600.0
      lon *= 3600.0
    end
    el        = Float64(ints[9]) * Float64(abs(z))^(z < zero(Int16) ? -1.0 : 1.0)

    # Create ID
    id_arr = zeros(UInt8,8)
    i = one(Int8)
    o = one(Int8)
    while i < Int8(18)
      if chars[i] == 0x00
        chars[i] = 0x20
      end
      i = i+o
    end
    fill_id!(id_arr, chars, one(Int16), Int16(6), Int16(2), Int16(6))
    id_arr[1] = 0x2e
    id_arr[8] = 0x2e
    deleteat!(id_arr, id_arr.==0x00)

    # Channel part is tedious; people use one-char channel names like "Z"
    ch_arr = chars[15:18]
    deleteat!(ch_arr, ch_arr.==0x00)
    nc = lastindex(ch_arr)
    if nc == 1
      c = uppercase(Char(ch_arr[1]))
      if c in ('Z','N','E')
        cha = string(getbandcode(fs), 'H', c)
      else
        cha = "YYY"
      end
    elseif nc ≥ 3
      cha = String(ch_arr[1:3])
    else
      cha = "YYY"
    end
    id = String(id_arr) * cha

  else
    (dt, nx, fmt) = fh
    dt = fh[1]
    nx = fh[2]
    fmt = fh[3]
    readbytes!(f, buf, 38)
    ints[26]      = read(f, Int32)
    shorts[60]    = read(f, Int16)
    ints[27]      = read(f, Int32)
    shorts[61]    = read(f, Int16)
    shorts[62]    = read(f, Int16)
    ints[28]      = read(f, Int32)
    ints[29]      = read(f, Int32)

    copyto!(ints, 20, intbuf, 1, 5)
    copyto!(shorts, 53, shortbuf, 11, 2)
    ints[25] = getindex(intbuf, 7)
    copyto!(shorts, 55, shortbuf, 15, 5)

    T = getindex(segy_ftypes, fmt)
    nb = checkbuf!(buf, nx, T)
    readbytes!(f, buf, nb)

    # trace processing
    x = Array{Float32,1}(undef, nx)
    if T == Int16
      fillx_i16_be!(x, buf, nx, 0)
    elseif T == Int32
      fillx_i32_be!(x, buf, nx, 0)
    elseif T == Int8
      fillx_i8!(x, buf, nx, 0)
    elseif T == Float32
      x .= bswap.(reinterpret(Float32, buf))[1:nx]
    elseif T == UInt32
      fillx_u32_be!(x, buf, nx, 0)
    else
      error("Trace data Type unsupported!")
    end

    shorts  .= ntoh.(shorts)
    ints    .= ntoh.(ints)
    z       = getindex(shorts, 5)
    δ       = getindex(shorts, 21)
    fs      = 1.0e6 / Float64(δ)

    # not sure about this; where did this formula come from...?
    gain    = Float64(ints[25]) * 10.0^(Float64(shorts[53] +
                                                shorts[23] +
                                                shorts[24])/10.0) # *2.0^shorts[47]
    lat     = 0.0
    lon     = 0.0
    el      = Float64(ints[9]) * Float64(abs(z))^(z<Int16(0) ? -1.0 : 1.0)

    # Create ID
    sta = string(shorts[55])
    cha = Int16(10) < shorts[1] < Int16(18) ? trid(shorts[1]-Int16(10), fs=fs) : "YYY"
    id = "." * sta[1:min(lastindex(sta),5)] * ".." * cha

  end
  if full == true
    shorts_k = String["trace_id_code", "n_summed_z", "n_summed_h", "data_use",
      "z_sc", "h_sc", "h_units_code", "v_weather",
      "v_subweather", "t_src_uphole", "t_rec_uphole", "src_static_cor",
      "rec_static_cor", "total_static", "t_lag_a", "t_lag_b",
      "t_delay", "t_mute_st", "t_mute_en", "nx",
      "delta", "gain_type", "gain_const", "init_gain",
      "correlated", "sweep_st", "sweep_en", "sweep_len",
      "sweep_type", "sweep_tap_st", "sweep_tap_en", "tap_type",
      "f_alias", "slope_alias", "f_notch", "slope_notch",
      "f_low_cut", "f_high_cut", "slope_low_cut", "slope_high_cut",
      "year", "day", "hour", "minute",
      "second", "time_code", "trace_wt_fac", "geophone_roll_p1",
      "geophone_first_tr", "geophone_last_tr", "gap_size", "overtravel"]
    append!(shorts_k, passcal ?
        String["total_static_hi", "data_form", "ms", "trigyear",
        "trigday", "trighour", "trigminute", "trigsecond",
        "trigms", "not_to_be_used"] :
        String["shot_scalar", "trace_units_code", "trans_exp", "trans_units_code",
        "device_id", "trace_time_sc", "src_type_code", "src_energy_dir",
        "src_exp", "src_units_code"])

    ints_k = String["trace_seq_line", "trace_seq_file", "event_no", "channel_no",
      "energy_src_pt", "cdp", "trace_in_ensemble", "src-rec_dist",
      "rec_ele", "src_ele", "src_dep", "rec_datum_ele",
      "src_datum_ele", "src_water_dep", "rec_water_dep", "src_x",
      "src_y", "rec_x", "rec_y"]
    append!(ints_k, passcal ? String["samp_rate", "num_samps", "max", "min"] :
      String["cdp_x", "cdp_y", "inline_3d", "crossline_3d", "shot_point",
      "trans_mant", "unassigned_1", "unassigned_2"] )
    misc = Dict{String,Any}(zip([shorts_k; ints_k],[shorts; ints]))
    misc["scale_fac"] = gain
    if passcal
      sta = String(chars[1:6])
      misc["inst_no"] = inst_no
      misc["sensor_serial"] = String(chars[7:14])
    end
    misc["station_name"] = sta
    misc["channel_name"] = cha
  end

  # Trace info
  ts = mktime(shorts[41], shorts[42], shorts[43], shorts[45], shorts[45], zero(Int16)) +
        shorts[53] + 1000*sum(shorts[15:17])
  t = Array{Int64,2}(undef,2,2)
  setindex!(t, one(Int64), 1)
  setindex!(t, Int64(nx), 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)

  loc = GeoLoc()
  loc.lat = lat
  loc.lon = lon
  loc.el = el

  C = SeisChannel()
  setfield!(C, :name, id)
  setfield!(C, :id, id)
  setfield!(C, :loc, loc)
  setfield!(C, :gain, gain)
  setfield!(C, :fs, fs)
  setfield!(C, :src, src)
  setfield!(C, :t, t)
  setfield!(C, :x, x)
  # unsafe_copyto!(getfield(C, :x), 1, x, 1, nx)

  if full == true
    setfield!(C, :misc, misc)
  end
  note!(C, string("+src: ", src))
  return C
end

function read_segy_file(fname::String,
                        buf::Array{UInt8,1},
                        shorts::Array{Int16,1},
                        ints::Array{Int32,1},
                        passcal::Bool,
                        swap::Bool,
                        full::Bool)
  f = open(fname, "r")
  trace_fh = Array{Int16,1}(undef,3)
  if passcal == true
    S = SeisData(do_trace(f, buf, shorts, ints, true, full, fname, swap, trace_fh))
  else
    shorts  = getfield(BUF, :int16_buf)
    checkbuf!(shorts, 62)
    S = SeisData()

    # File header
    filehdr       = read(f, 3200)
    jobid         = bswap(read(f, Int32))
    lineid        = bswap(read(f, Int32))
    reelid        = bswap(read(f, Int32))
    readbytes!(f, buf, 48)
    fillx_i16_be!(shorts, buf, 24, 0)
    skip(f, 240)

    # My sample files have the Int16s in little endian order...?
    for i = 25:27
      shorts[i] = read(f, Int16)
    end
    skip(f, 94)

    # Process file header
    nh = max(zero(Int16), getindex(shorts, 27))
    if full == false
      skip(f, 3200*nh)
    else
      exthdr = Array{String,1}(undef, nh)
      for i = 1:nh; exthdr[i] = read(f, 3200); end
      fhd = Dict{String,Any}(
              zip(String["ntr", "naux", "filedt", "origdt", "filenx",
                         "orignx", "fmt", "cdpfold", "trasort", "vsum",
                         "swst", "swen0", "swlen", "swtyp", "tapnum",
                         "swtapst", "swtapen", "taptyp", "corrtra", "bgainrec",
                         "amprec", "msys", "zupdn", "vibpol", "segyver",
                         "isfixed", "n_exthdr"], shorts[1:27])
                            )
      fhd["jobid"]  = jobid
      fhd["lineid"] = lineid
      fhd["reelid"] = reelid
      fhd["filehdr"] = filehdr
      fhd["exthdr"] = exthdr
    end

    trace_fh[1] = getindex(shorts,3)
    trace_fh[2] = getindex(shorts,5)
    trace_fh[3] = getindex(shorts,7)

    # Channel headers
    nt = shorts[1]
    for i = 1:nt
      # "swap" is not used here
      push!(S, do_trace(f, buf, shorts, ints, false, full, fname, true, trace_fh))
      if full == true
        merge!(S.misc[i], fhd)
      end
    end
  end
  close(f)
  return S
end

# ============================================================================

"""
    segyhdr(f[; passcal=false, swap=false])

Print formatted, sorted SEG-Y headers of file `f` to stdout. Use keyword
`passcal=true` for PASSCAL/NMT modified SEG Y; use `swap=true` for big-endian
PASSCAL.
"""
function segyhdr(fname::String; passcal::Bool=false, swap::Bool=false)
  if passcal
    seis = read_data("passcal", fname::String, full=true, swap=swap)
  else
    seis = read_data("segy", fname::String, full=true)
  end
  if passcal
    printstyled(stdout, @sprintf("%20s: %s\n", "PASSCAL SEG-Y FILE", realpath(fname)), color=:green, bold=true)
    D = getindex(getfield(seis, :misc),1)
    for k in sort(collect(keys(D)))
      @printf(stdout, "%20s: %s\n", k, string(get(D, k, "")))
    end
  else
    W = displaysize(stdout)[2]-2
    S = fill("", length(seis.misc[1])+1)
    p = 1
    w = 32
    printstyled(stdout, @sprintf("%20s: %s\n", "SEG-Y FILE", realpath(fname)), color=:green, bold=true)
    for i = 1:seis.n
      if p > 1
        s = @sprintf("%20i/%i", i, seis.n)
      else
        s = @sprintf(" Trace # %11i/%i", i, seis.n)
      end
      S[1] *= s
      S[1] *= " "^(w-length(s))
      D = getindex(getfield(seis, :misc),1)
      for (j,k) in enumerate(sort(collect(keys(D))))
        if k == "exthdr" || k == "filehdr"
          val = get(seis.misc[i], k, repr(nothing))
          if val == "nothing" || isempty(val)
            s = "(empty)"
          else
            s = length(val) > 8 ? String(val[1:8])*"…" : String(val)
          end
        else
          s = string(get(seis.misc[i], k, repr(nothing)))
        end
        S[j+1] *= @sprintf("%20s: %s%s", k, s, " "^(10-length(s)))
      end
      if p+2*w > W || i == seis.n
        printstyled(stdout, S[1]*"\n", color=:yellow, bold=true)
        [println(S[j]) for j=2:length(S)]
        println("")
        S = fill("", length(seis.misc[i])+1)
        p = 1
      else
        p += w
      end
    end
    printstyled(stdout, @sprintf("%20s\n","END OF RECORD"), color=208, bold=true)
  end
  return nothing
end
