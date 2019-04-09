import Dates:DateTime
export readgeocsv

function assign_val!(C::SeisChannel, k::String, v::String)
  if k == "delimiter" ; C.misc["delim"] = mkdelim(v);
  elseif k == "SID" ; C.id = replace(v, '_' => '.');
  elseif k == "sample_count" ; nx = v;
  elseif k == "sample_rate_hz" ; C.fs = Base.parse(Float64,v);
  elseif k == "latitude_deg" ; C.loc[1] = Base.parse(Float64, v);
  elseif k == "longitude_deg" ; C.loc[2] = Base.parse(Float64, v);
  elseif k == "elevation_m" ; C.loc[3] = Base.parse(Float64, v);
  elseif k == "azimuth_deg" ; C.loc[4] = Base.parse(Float64, v);
  elseif k == "dip_deg" ; C.loc[5] = Base.parse(Float64, v);
  elseif k == "depth_m" ; C.loc[6] = Base.parse(Float64, v);
  elseif k == "scale_factor" ; C.gain = Base.parse(Float64, v);
  elseif k == "scale_frequency_hz" ; C.misc[k] = Base.parse(Float64, v);
  elseif k == "scale_units" ; C.units = lowercase(v);
  else
    C.misc[k] = lowercase(v)
  end
  return nothing
end

function mkdelim(delim::String)
  if occursin(delim, "\\^\$.|?*+()[{")
    delim = "\\" * delim
  end
  return delim
end

"""
    S = read_geocsv_ts(fname)

Read GeoCSV time-series ASCII file `fname` to new SeisData object `S`.
"""
function parse_geocsv_ts!(S::SeisData, lines::Array{String,1})

  # Find all lines that start with "#", save indices as hdr_lines
  hdr_lines = findall(startswith.(lines, "#"))
  ii = findall(diff(hdr_lines).>1)
  hs = vcat(1, hdr_lines[ii.+1])
  xs = vcat(hdr_lines[ii].+2, last(hdr_lines)+2)
  xe = vcat(hs[2:end].-1, length(lines))

  for i = 1:length(hs)
    C = SeisChannel()
    C.loc = Array{Float64,1}(undef, 6)
    hdr = lines[hs[i]:xs[i]-1]

    # Parse header
    for i = 1:length(hdr)
      h = hdr[i]
      if startswith(h, "#")
        k, v = String.(strip.(split(h[2:end], ":", limit=2)))
        assign_val!(C, k, v)
      end
    end
    delim = get(C.misc, "delim", r"[a-zA-Z.,]")
    types = String.(strip.(split(get(C.misc, "field_type", ""), delim)))

    T = Array{Type,1}(undef, length(types))
    for (n,t) in enumerate(types)
      if t == "datetime"
        T[n] = DateTime
      elseif t in ["integer","float"]
        T[n] = Float32
      end
    end

    nx = xe[i]-xs[i]+1
    C.x = Array{T[2],1}(undef, nx)
    C.t = Array{Int64,2}(undef, 0, 2)
    Δ = round(Int64, 1.0e3/C.fs)
    t0 = 62135683200000

    # Parse data
    for (n, line) in enumerate(lines[xs[i]:xe[i]])
      A = split(line, delim, keepempty=false)

      if T[1] == DateTime
        dt = split(A[1], ".")
        t = DateTime(dt[1]).instant.periods.value +
              div(parse(Int, replace(dt[2], r"[a-z,A-Z]" => "")), 1000)
        if t - t0 > div(Δ,2)
          C.t = vcat(C.t, [n 1000*(t-t0-Δ)])
        end
        t0 = t
      end

      # parse A[2] according to format spec
      C.x[n] = parse(T[2], A[2])
    end
    C.t = vcat(C.t, [xe[i]-xs[i]+1 0])
    # C.name = identity(C.id)

    # if C.id exists in S, and C.fs = S.fs[i], append the data
    i = findid(C.id, S)
    if i > 0
      # We can only test fs, loc, and units; resp is not part of GeoCSV
      if C.fs == S.fs[i] && C.loc == S.loc[i] && C.units == S.units[i]
        # So we assume resp is the same
        C.resp = deepcopy(S.resp[i])
        merge!(S, C)
      else
        push!(S, C)
      end
    else
      push!(S, C)
    end
  end
  return nothing
end

"""
    S = readgeocsv(fname)

Read GeoCSV time-series ASCII file `fname` to new SeisData object `S`.
"""
function readgeocsv(fname::String)
  fname = relpath(fname)

  # (1) Read all lines into memory
  fio = open(fname, "r")
  lines = readlines(fio)
  close(fio)
  S = SeisData()
  parse_geocsv_ts!(S, lines)
  return S
end
