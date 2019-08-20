export convert_seis, convert_seis!

@doc """
    convert_seis!(S[, chans=CC, units_out=UU, v=V])
    convert_seis(S, chans=CC, units_out=UU, v=V])
    convert_seis!(C[, units_out=UU, v=V])
    convert_seis(CC, units_out=UU, v=V)

    Converts all seismic data channels in `S` to velocity seismograms,
differentiating or integrating as needed.

### Keywords
* `units_out=UU` specifies output units.
  + Default: "m/s".
  + Allowed: "m", "m/s", or "m/s2". (SeisIO uses Unicode (UTF-8) UCUM units.)
* `v=V` sets verbosity.
* `chans=CC` restricts seismogram conversion to seismic data channels within `CC`.
  + `chans` can be an Integer, UnitRange, or Array{Int64,1}.
  + By default, all seismic data channels in `S` are converted (if needed).
  + This does not allow `convert_seis!` to work on non-seismic data.

!!! warning

    `convert_seis!` becomes less reversible as seismograms lengthen, particularly at Float32 precision.

### References
[^1] Neumaier, A. (1974). "Rundungsfehleranalyse einiger Verfahren zur Summation
endlicher Summen" [Rounding Error Analysis of Some Methods for Summing Finite
Sums]. Zeitschrift für Angewandte Mathematik und Mechanik (in German). 54 (1):
39–51. doi:10.1002/zamm.19740540106.

""" convert_seis!
function convert_seis!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  units_out::String="m/s",
  v::Int64=KW.v)

  # sanity check
  if units_out in ("m", "m/s", "m/s2") == false
    error("units_out must be in (\"m\", \"m/s\", \"m/s2\")!")
  end

  # get seismic data channels
  chans = mkchans(chans, S.n)
  filt_seis_chans!(chans, S)

  # now loop over all seismic channels
  for i in chans
    S.fs[i] == 0.0 && (@warn(string("Irregularly-sampled seismic data in channel ", i, "; skipped!")); continue)

    if v > 2
      println(stdout, "Begin channel ", i)
    end

    # get units
    units_in = lowercase(S.units[i])
    units_in == units_out && continue

    # differentiate or integrate
    if v > 0
      println(stdout, "Converting channel ", i, ": ", units_in, " => ", units_out)
    end

    T = eltype(S.x[i])
    fs = T(S.fs[i])
    δ = one(T)/fs
    dt = round(Int64, 1.0/(S.fs[i]*μs))
    d2 = div(dt, 2)
    t = S.t[i]
    Nt = size(t, 1) - 1

    if units_out == "m/s"

      # differentiate from m to m/s
      if units_in == "m"
        diff_x!(S.x[i], t[:,1], fs)
        for j = 1:Nt
          t[j,2] -= d2
        end

      # integrate from m/s2 to m/s
      else
        int_x!(S.x[i], t[:,1], δ)
        for j = 1:Nt
          t[j,2] -= d2
        end
      end

    elseif units_out == "m"
      int_x!(S.x[i], t[:,1], δ)
      for j = 1:Nt
        t[j,2] -= d2
      end
      if units_in == "m/s2"
        int_x!(S.x[i], t[:,1], δ)
        for j = 1:Nt
          t[j,2] -= d2
        end
      end
    else # units == "m/s2"
      diff_x!(S.x[i], t[:,1], fs)
      for j = 1:Nt
        t[j,2] += d2
      end
      if units_in == "m"
        diff_x!(S.x[i], t[:,1], fs)
        for j = 1:Nt
          t[j,2] += d2
        end
      end
    end

    # change units
    S.units[i] = units_out

    # log processing
    note!(S, i, string("convert_seis!, units_old = ", units_in))

    if v > 2
      println(stdout, "Done channel ", i)
    end
  end

  return nothing
end

function convert_seis!(C::GphysChannel;
  units_out::String="m/s",
  v::Int64=KW.v)

  # sanity check
  if units_out in ("m", "m/s", "m/s2") == false
    error("units_out must be in (\"m\", \"m/s\", \"m/s2\")!")
  end

  units_in = lowercase(C.units)
  units_in == units_out && return nothing

  # differentiate or integrate
  if v > 0
    println(stdout, "Converting ", units_in, " => ", units_out)
  end

  T = eltype(C.x)
  fs = T(C.fs)
  δ = one(T)/fs
  dt = round(Int64, 1.0/(C.fs*μs))
  d2 = div(dt, 2)
  t = C.t
  Nt = size(t, 1) - 1

  if units_out == "m/s"

    # differentiate from m to m/s
    if units_in == "m"
      diff_x!(C.x, t[:,1], fs)
      for j = 1:Nt
        t[j,2] -= d2
      end

    # integrate from m/s2 to m/s
    else
      int_x!(C.x, t[:,1], δ)
      for j = 1:Nt
        t[j,2] -= d2
      end
    end

  elseif units_out == "m"
    int_x!(C.x, t[:,1], δ)
    for j = 1:Nt
      t[j,2] -= d2
    end
    if units_in == "m/s2"
      int_x!(C.x, t[:,1], δ)
      for j = 1:Nt
        t[j,2] -= d2
      end
    end
  else # units == "m/s2"
    diff_x!(C.x, t[:,1], fs)
    for j = 1:Nt
      t[j,2] += d2
    end
    if units_in == "m"
      diff_x!(C.x, t[:,1], fs)
      for j = 1:Nt
        t[j,2] += d2
      end
    end
  end

  # change units
  C.units = units_out

  # log processing
  note!(C, string("convert_seis!, units_old = ", units_in))

  return nothing
end

@doc (@doc convert_seis!)
function convert_seis(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  units_out::String="m/s",
  v::Int64=KW.v)

  U = deepcopy(S)
  convert_seis!(U, chans=chans, units_out=units_out, v=v)
  return U
end

function convert_seis(C::GphysChannel;
  units_out::String="m/s",
  v::Int64=KW.v)

  U = deepcopy(C)
  convert_seis!(U, units_out=units_out, v=v)
  return U
end
