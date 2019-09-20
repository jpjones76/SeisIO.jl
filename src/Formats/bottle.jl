export fill_pbo!

# https://www.unavco.org/data/strain-seismic/bsm-data/lib/docs/bottle_format.pdf

bottle_chans = Dict{String, Tuple{String,String}}(
  "BatteryVolts" => ("ABV", "V"),
  "CalOffsetCH0G3" => ("AO0", "{unknown}"),
  "CalOffsetCH1G3" => ("AO1", "{unknown}"),
  "CalOffsetCH2G3" => ("AO2", "{unknown}"),
  "CalOffsetCH3G3" => ("AO3", "{unknown}"),
  "CalStepCH0G2" => ("A02", "{unknown}"),
  "CalStepCH0G3" => ("A03", "{unknown}"),
  "CalStepCH1G2" => ("A12", "{unknown}"),
  "CalStepCH1G3" => ("A13", "{unknown}"),
  "CalStepCH2G2" => ("A22", "{unknown}"),
  "CalStepCH2G3" => ("A23", "{unknown}"),
  "CalStepCH3G2" => ("A32", "{unknown}"),
  "CalStepCH3G3" => ("A33", "{unknown}"),
  "DownholeDegC" => ("KD", "Cel"),
  "LoggerDegC" => ("K1", "Cel"),
  "PowerBoxDegC" => ("K2", "Cel"),
  "PressureKPa" => ("DI", "kPa"),
  "Rainfallmm" => ("R0", "mm"),
  "RTSettingCH0" => ("AR0", "{unknown}"),
  "RTSettingCH1" => ("AR1", "{unknown}"),
  "RTSettingCH2" => ("AR2", "{unknown}"),
  "RTSettingCH3" => ("AR3", "{unknown}"),
  "SolarAmps" => ("ASO", "A"),
  "SystemAmps" => ("ASY", "A")
)

bottle_nets = Dict{String, String}(
  "AIRS" => "MC",
  "TEPE" => "GF",
  "BUY1" => "GF",
  "ESN1" => "GF",
  "TRNT" => "MC",
  "HALK" => "GF",
  "B948" => "ARRA",
  "OLV1" => "MC",
  "OLV2" => "MC",
  "GERD" => "MC",
  "SIV1" => "GF",
  "BOZ1" => "GF",
  "B947" => "ARRA"
  )

function check_bads!(x::AbstractArray, nv::T) where T
  # Check for bad samples
  @inbounds for i in x
    if i == nv
      return true
    end
  end
  return false
end

function channel_guess(str::AbstractString, fs::Float64)
  si = fs >= 1.0 ? 14 : 10
  ei = length(str) - (endswith(str, "_20") ? 3 : 0)

  # name, id, units
  str = str[si:ei]
  if length(str) == 3
    units = "m/m"
  else
    (str, units) = get(bottle_chans, str, ("YY", "{unknown}"))
  end

  # form channel string
  if length(str) == 2
    str = (fs > 1.0 ? "B" : fs > 0.1 ? "L" : "R")*str
  end

  return (str, units)
end

function read_bottle!(S::GphysData, fstr::String, v::Int64, nx_new::Int64, nx_add::Int64)
  buf = BUF.buf
  files = ls(fstr)

  for file in files
    io = open(file, "r")

    # Read header ============================================================
    skip(io, 8)
    t0 = round(Int64, read(io, Float64)*1.0e6)
    dt = read(io, Float32)
    nx = read(io, Int32)
    ty = read(io, Int32)
    nv = read(io, Int32)
    skip(io, 8)
    fs = 1.0/dt
    v > 2 && println("t0 = ", t0, ", fs = ", fs, ", nx = ", nx, ", ty = ", ty, ", nv = ", nv)

    # Read data ==============================================================
    T = ty == 0 ? Int16 : ty == 1 ? Int32 : Float32
    nb = nx*sizeof(T)
    checkbuf_8!(buf, nb)
    readbytes!(io, buf, nb)
    close(io)

    # Try to create an ID from the file name =================================
    # Assumes fname SSSSyyJJJ... (SSSS = station, yy = year, JJJ = Julian day)
    fname = splitdir(file)[2]
    sta = fname[1:4]
    (cha, units) = channel_guess(fname, fs)

    # find relevant entry in station data
    net = get(bottle_nets, sta, "PB")
    id = net * "." * sta * ".." * cha

    # Load into S ============================================================
    i = findid(id, S.id)
    if i == 0

      # Create C.t
      t = ones(Int64, 2, 2)
      setindex!(t, nx, 2)
      setindex!(t, t0, 3)
      setindex!(t, zero(Int64), 4)

      # Create C.x
      x = Array{Float64,1}(undef, max(nx_new, nx))
      os = 1

      C = SeisChannel()
      setfield!(C, :id, id)
      setfield!(C, :name, fname)
      setfield!(C, :fs, fs)
      setfield!(C, :units, units)
      setfield!(C, :src, fstr)
      setfield!(C, :t, t)
      setfield!(C, :x, x)
      push!(S, C)
    else
      xi = S.t[i][end,1]
      x = getindex(getfield(S, :x), i)
      check_for_gap!(S, i, t0, nx, v)
      Lx = length(x)
      if xi + nx > Lx
        resize!(x, Lx + max(nx_add, nx))
      end
      os = xi + 1
    end

    # Check for null values
    nv = T(nv)
    y = reinterpret(T, buf)
    b = T == Int16 ? false : check_bads!(y, nv)
    if b
      j = os
      @inbounds for i = 1:nx
        if y[i] == nv
          x[j] = NaN
        else
          x[j] = y[i]
        end
        j += 1
      end
    else
      copyto!(x, os, y, 1, nx)
    end
  end
  trunc_x!(S)
  resize!(buf, 65535)

  return nothing
end

function read_bottle(fstr::String, v::Int64, nx_new::Int64, nx_add::Int64)

  S = SeisData()
  read_bottle!(S, fstr, v, nx_new, nx_add)
  return S
end

"""
    fill_pbo!(S)

Attempt to fill `:name` and `:loc` fields of S using station names (second field of S.id) cross-referenced against a PBO station info file.
"""
function fill_pbo!(S::GphysData)
  sta_data = readdlm(path * "/Formats/PBO_bsm_coords.txt", ',', comments=false)
  sta_data[:,2] .= strip.(sta_data[:,2])
  sta_data[:,6] .= strip.(sta_data[:,6])
  n_sta = size(sta_data, 1)
  for i = 1:S.n
    sta = split(S.id[i], '.')[2]
    for j = 1:n_sta
      if sta_data[j, 1] == sta
        S.name[i] = String(sta_data[j,2])
        lat = sta_data[j,3]
        lon = sta_data[j,4]
        el = sta_data[j,5]
        S.loc[i] = GeoLoc(lat = lat, lon = lon, el = el)
        break
      end
    end
  end
  return nothing
end
