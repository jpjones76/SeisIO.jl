export readsegy, segyhdr

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

function do_trace(f::IO; full=false::Bool, passcal=false::Bool, fh=zeros(Int16, 3)::Array{Int16, 1}, src=""::String)
  ftypes = Array{DataType, 1}([UInt32, Int32, Int16, Any, Float32, Any, Any, Int8]) # Note: type 1 is IBM Float32
  shorts = Array{Int16, 1}(undef, 62)
  ints   = Array{Int32, 1}(undef, passcal ? 23 : 29)

  # First part of trace header is quite standard
  ints[1:7]   = read!(f, Array{Int32, 1}(undef, 7))
  shorts[1:4] = read!(f, Array{Int16, 1}(undef, 4))
  ints[8:15]  = read!(f, Array{Int32, 1}(undef, 8))
  shorts[5:6] = read!(f, Array{Int16, 1}(undef, 2))
  ints[16:19] = read!(f, Array{Int32, 1}(undef, 4))
  shorts[7:52]= read!(f, Array{Int16, 1}(undef, 46))
  if passcal
    chars         = read!(f, Array{UInt8, 1}(undef, 18))
    shorts[53]    = read(f, Int16)
    ints[20]      = read(f, Int32); dt = ints[20]
    shorts[54:61] = read!(f, Array{Int16, 1}(undef, 8)); fmt = shorts[54]
    scale_fac     = read(f, Float32)
    inst_no       = read(f, UInt16)
    shorts[62]    = read(f, Int16)
    ints[21:23]   = read!(f, Array{Int32, 1}(undef, 3)); # n = ints[21]
    nx = (shorts[20] == Int16(32767) ? ints[21] : Int32(shorts[20]))
    x = map(Float32, read!(f, Array{fmt == Int16(1) ? Int32 : Int16, 1}(undef, nx)))
    close(f)

    # trace processing
    fs    = 1.0e6 / Float64(shorts[21] == Int16(1) ? dt : shorts[21])
    gain  = Float64(shorts[23]) * 10.0^(Float64(shorts[24])/10.0) / Float64(scale_fac)
    lat, lon = auto_coords(ints[18:19], shorts[6:7])
    if passcal == true && abs(lat) < 0.1 && abs(lon) < 0.1
      lat *= 3600.0
      lon *= 3600.0
    end
    el    = Float64(ints[9]) * Float64(abs(shorts[5]))^(shorts[5]<Int16(0) ? -1.0 : 1.0)
    sta   = strip(replace(String(chars[1:6]),"\0" => ""))
    sensor_serial = strip(replace(String(chars[7:14]),"\0" => ""))
    c = strip(replace(String(chars[15:18]),"\0" => ""))

    if uppercase(c) in ["Z","N","E"]
      cha = string(getbandcode(fs), 'H', c[1])
    elseif length(c) < 2
      cha = "YYY"
    else
      cha = c
    end
  else
    (dt, nx, fmt) = fh
    ints[20:24]   = read!(f, Array{Int32, 1}(undef, 5))
    shorts[53:54] = read!(f, Array{Int16, 1}(undef, 2))
    ints[25]      = read(f, Int32)
    shorts[55:59] = read!(f, Array{Int16, 1}(undef, 5))
    ints[26]      = read(f, Int32)
    shorts[60]    = read(f, Int16)
    ints[27]      = read(f, Int32)
    shorts[61:62] = read!(f, Array{Int16, 1}(undef, 2))
    ints[28:29]   = read!(f, Array{Int32, 1}(undef, 2))
    x             = map(Float32, [bswap(i) for i in read!(f, Array{ftypes[fmt], 1}(undef, nx))])


    # not sure about this; where did this formula come from...?
    shorts = ntoh.(shorts)
    ints   = ntoh.(ints)

    gain  = Float64(ints[25]) * 10.0^(Float64(shorts[53]+sum(shorts[23:24]))/10.0) # *2.0^shorts[47]
    fs    = 1.0e6 / Float64(shorts[21])
    lat   = 0.0
    lon   = 0.0
    el    = Float64(ints[9]) * Float64(abs(shorts[5]))^(shorts[5]<Int16(0) ? -1.0 : 1.0)
    sta   = @sprintf("%04i", shorts[55])
    cha   = shorts[1] in Int16(11):Int(1):Int16(17) ? trid(shorts[1]-Int16(10), fs=fs) : "YYY"
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
    misc["scale_fac"] = 1/gain
    misc["station_name"] = sta
    misc["channel_name"] = cha
    if passcal
      misc["inst_no"] = inst_no
      misc["sensor_serial"] = sensor_serial
    end
  end

  # Trace info
  (m,d)     = j2md(shorts[41], shorts[42])
  ts        = round(Int64, d2u(DateTime(shorts[41], m, d, shorts[43], shorts[44], shorts[45]))*1000000 +
                   (shorts[53] + sum(shorts[15:17]))*1000)
  loc       = [lat, lon, el, 0.0, 0.0]
  t         = [1 ts; length(x) 0]
  id        = uppercase(replace(join(["", sta, "00", cha], '.'), "\0" => ""))
  chan      = SeisChannel()
  setfield!(chan, :name, id)
  setfield!(chan, :id, id)
  setfield!(chan, :loc, loc)
  setfield!(chan, :gain, gain)
  setfield!(chan, :fs, fs)
  setfield!(chan, :src, src)
  setfield!(chan, :t, t)
  setfield!(chan, :x, x)
  if full == true
    setfield!(chan, :misc, misc)
  end
  note!(chan, string("+src: readsegy ", src))
  return chan
end
# ============================================================================

"""
    seis = readsegy(fname)

Read SEG-Y file `fname` into SeisData object `seis`.

### Keywords
* `passcal=true` for PASSCAL/NMT modified SEG-Y
* `full=true` to store full SEG-Y headers as a dictionary in `seis.misc`.
"""
function readsegy(fname::String; passcal=false::Bool, full=false::Bool)
  fname = realpath(fname)
  f = open(fname, "r")
  if passcal == true
    seis = SeisData(do_trace(f, full=full, passcal=passcal, src=fname))
    seis.src[1] = fname
  else
    fh = Array{Int16, 1}(undef, 27)
    seis = SeisData()

    # File header
    txthdr        = join(read!(f, Array{Cchar,1 }(undef, 3200)))
    ids           = read!(f, Array{Int32, 1}(undef, 3))
    fh[1:24]      = read!(f, Array{Int16, 1}(undef, 24))

    # My sample files have the Int16s in little endian order...?
    fh = [bswap(i) for i in fh]
    skip(f, 240)
    fh[25:27] = read!(f, Array{Int16, 1}(undef, 3))
    skip(f, 94)

    # Process file header
    ids = [bswap(i) for i in ids]
    nh = 0
    if fh[end] > Int16(0)
      nh = fh[end]
    end
    if full == false
      skip(f, 3200*nh)
    else
      fhd = Dict{String,Any}()
      fhd["exthdr"] = [replace(join(read!(f, Array{Cchar, 1}(undef, 3200))), "\0" => " ") for i = 1:nh]
      merge!(fhd, Dict{String,Any}(zip(["jobid", "lineid", "reelid", "ntr",
      "naux", "filedt", "origdt", "filenx", "orignx", "fmt", "cdpfold",
      "trasort", "vsum", "swst", "swen0", "swlen", "swtyp", "tapnum", "swtapst",
      "swtapen", "taptyp", "corrtra", "bgainrec", "amprec", "msys", "zupdn",
      "vibpol", "segyver", "isfixed", "ntxthdr"],
      [ids; fh])))
    end

    # Channel headers
    for i = 1:fh[1]
      seis += do_trace(f, full=full, passcal=passcal, fh=fh[[3,5,7]], src=fname)
      seis.src[seis.n] = fname
      if full == true
        merge!(seis.misc[i], fhd)
      end
    end
  end
  close(f)
  return seis
end

"""
    segyhdr(f)

Print formatted, sorted SEG-Y headers of file `f` to stdout. Pass keyword argument `passcal=true` for PASSCAL/NMT modified SEG-Y.
"""
function segyhdr(fname::String; passcal=false::Bool)
  seis = readsegy(fname::String; passcal=passcal, full=true)
  if passcal
    printstyled(stdout, @sprintf("%20s: %s\n", "PASSCAL SEG-Y FILE", realpath(fname)), color=:green, bold=true)
    for k in sort(collect(keys(seis.misc)))
      @printf(stdout, "%20s: %s\n", k, string(seis.misc[k]))
    end
  else
    W = displaysize(stdout)[2]-2
    S = fill("", length(seis.misc[1])+1)
    p = 1
    w = 32
    # @printf(stdout, "%20s: %s\n", "SEG-Y HEADER", realpath(fname))
    printstyled(stdout, @sprintf("%20s: %s\n", "SEG-Y FILE", realpath(fname)), color=:green, bold=true)
    for i = 1:seis.n
      if p > 1
        s = @sprintf("%20i/%i", i, seis.n)
      else
        s = @sprintf(" Trace # %11i/%i", i, seis.n)
      end
      S[1] *= s
      S[1] *= " "^(w-length(s))
      for (j,k) in enumerate(sort(collect(keys(seis.misc[i]))))
        if k == "exthdr"
          val = get(seis.misc[i], k, repr(nothing))
          if val == "nothing" || isempty(val)
            s = "(empty)"
          else
            s = s[1:8]*"…"
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
