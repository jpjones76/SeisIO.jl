using DSP:tukey, resample

"""
    getbandcode(fs, fc=FC)

Get SEED-compliant one-character band code corresponding to instrument sample
rate `fs` and corner frequency `FC`. If unset, `FC` is assumed to be 1 Hz.
"""
function getbandcode(fs::Real; fc = 1::Real)
  fs ≥ 1000 && return fc ≥ 0.1 ? 'G' : 'F'
  fs ≥ 250 && return fc ≥ 0.1 ? 'C' : 'D'
  fs ≥ 80 && return fc ≥ 0.1 ? 'E' : 'H'
  fs ≥ 10 && return fc ≥ 0.1 ? 'S' : 'B'
  fs > 1 && return 'M'
  fs > 0.1 && return 'L'
  fs > 1.0e-2 && return 'V'
  fs > 1.0e-3 && return 'U'
  fs > 1.0e-4 && return 'R'
  fs > 1.0e-5 && return 'P'
  fs > 1.0e-6 && return 'T'
  return 'Q'
end

"""
    prune!(S)

Merge all channels from S with redundant fields.
"""
function prune!(S::SeisData)
  hs = headerhash(S)
  k = falses(S.n)
  m = falses(S.n)
  for i = 1:1:S.n-1
    for j = i+1:1:S.n
      if isequal(hs[:,i], hs[:,j])
        k[j] = true
        if !m[j]
          T = S[j]
          merge!(S, T)
          m[j] = true
        end
      end
    end
  end
  any(k) && (delete!(S, find(k)))
  return S
end
prune(S::SeisData) = (T = deepcopy(S); prune!(T); return(T))

"""
    purge!(S)

Remove all channels from S with empty data fields.
"""
function purge!(S::SeisData)
  k = falses(S.n)
  [isempty(S.x[i]) && (k[i] = true) for i in 1:S.n]
  any(k) && (delete!(S, find(k)))
  return S
end
purge(S::SeisData) = (T = deepcopy(S); purge!(T); return(T))

"""
    gapfill!(x, t, fs)

Fill gaps in x, as specified in t, assuming sampling rate fs
"""
function gapfill!(x::Array{Float64,1}, t::Array{Int64,2}, fs::Float64; m=true::Bool, w=true::Bool)
  (fs == 0 || isempty(x)) && (return x)
  mx = m ? mean(x[!isnan(x)]) : NaN
  u = round(Int, max(20,0.2*fs))
  for i = size(t,1):-1:2
    # Gap fill
    g = round(Int, fs*μs*t[i,2])
    g < 0 && (warn(@sprintf("Channel %i: negative time gap (t = %.3f); skipped.", i, g)); continue)
    g == 0 && continue
    j = t[i-1,1]
    k = t[i,1]
    N = k-j
    splice!(x, k:k-1, mx.*ones(g))

    # Window if selected
    if w
      if N >= u
        x[j+1:k] .*= tukey(N, u/N)
      else
        warn(string(@sprintf("Channel %i: Time window too small, ",i),
        @sprintf("x[%i:%i]; replaced with mean.", j+1, k)))
        x[j+1:k] = mx
      end
    end
  end
  return x
end
gapfill(x::Array{Float64,1}, t::Array{Int64,2}, f::Float64) =
  (y = deepcopy(x); gapfill!(y,t,f); return y)

"""
    ungap!(S)

Fill time gaps in S with the mean of data in S. If S is a SeisData structure,
time gaps in channel [i] are filled with the mean value of each channel's data.
"""
function ungap!(S::SeisObj; m=true::Bool, w=true::Bool)
  N = size(S.t,1)-2
  (N ≤ 0 || S.fs == 0) && return S
  gapfill!(S.x, S.t, S.fs, m=m, w=w)
  note(S, @sprintf("Filled %i gaps (sum = %i microseconds)", N, sum(S.t[2:end-1,2])))
  S.t = [S.t[1,:]; [length(S.x) 0]]
  return S
end
function ungap!(S::SeisData; m=true::Bool, w=true::Bool)
  for i = 1:1:S.n
    N = size(S.t[i],1)-2
    (N ≤ 0 || S.fs[i] == 0) && continue
    gapfill!(S.x[i], S.t[i], S.fs[i], m=m, w=w)
    note(S, i, @sprintf("Filled %i gaps (sum = %i microseconds)", N, sum(S.t[i][2:end-1,2])))
    S.t[i] = [S.t[i][1,:]; [length(S.x[i]) 0]]
  end
  return S
end
ungap(S::Union{SeisData,SeisObj}; m=true::Bool, w=true::Bool) = (T = deepcopy(S); ungap!(T, m=m, w=w))

"""
    sync!(S::SeisData)

Synchronize time ranges of S and pad data gaps.

    sync!(S, resample=true)

Synchronize S and resample data in S to the lowest non-null interval in S.fs.

    sync!(S, resample=true, fs=FS)

Synchronize S and resample data in S to `FS`. Note that a poor choice of `FS`
can lead to upsampling and other bad behaviors. Resample requests are
ignored if S has only one data channel.

    sync!(S, s=ST, t=EN)

Synchronize all data in S to start at `ST` and terminate at `EN`.

#### Specifying start time
Start time can be synchronized to a variety of values:

* `ST` = "max": Sync to earliest start time of any channel in `S`. (default)
* `ST` = "min": Use latest start time of any channel in `S`.
* `ST` numeric: Start at epoch time ST.
* ST is a DateTime: Start at ST.
* ST is a string other than "max" or "min": Start at DateTime(ST).

#### Specifying end time
* `ET` = "max": Synchronize to latest end time in `S`. (default)
* `ET` = "min": Synchronize to earliest end time in `S`.
* numeric, datetime, and other string values are as for `ST`.
"""
function sync!(S::SeisData; resample=false::Bool, fs=0::Real,
  s="max"::Union{ASCIIString,Real,DateTime},
  t="max"::Union{ASCIIString,Real,DateTime})

  # Do not edit order of operations
  ungap!(S, m=false, w=false)
  autotap!(S)
  start_times = zeros(S.n)
  end_times = zeros(S.n)
  c = find(S.fs .== 0)
  for i in c
    start_times[i] = S.t[i][1,2]
    end_times[i] = sum(S.t[i][:,2])
  end
  k = find((S.fs .> 0).*[!isempty(S.x[i]) for i=1:S.n])
  for i in k
    S.x[i] -= mean(S.x[i])
    start_times[i] = round(Int, S.t[i][1,2]*S.fs[i]) / S.fs[i]
  end
  [end_times[i] = length(S.x[i])/S.fs[i] for i in k]
  # Do not edit order of operations

  # Possible options for s
  if isa(s,Real)
    t_start = round(Int, s/μs)
  elseif isa(s,DateTime)
    t_start = round(Int, Dates.datetime2unix(s)/μs)
  else
    starts = start_times[k]
    if s == "max"
      t_start = minimum(starts)
    elseif s == "min"
      t_start = maximum(starts)
    else
      t_start = round(Int, Dates.datetime2unix(DateTime(s))/μs)
    end
  end

  # Possible options for t
  if isa(t,Real)
    t_end = t_start + round(Int, t/μs)
  elseif isa(t,DateTime)
    t_end = round(Int, Dates.datetime2unix(t)/μs)
  else
    ends = end_times[k] + start_times[k]
    if t == "max"
      t_end = maximum(ends)
    elseif t == "min"
      t_end = minimum(ends)
    else
      t_end = round(Int, Dates.datetime2unix(DateTime(t))/μs)
    end
  end
  t_end <= t_start && error("No time overlap with given start \& end times!")
  @printf(STDOUT, "Synching %.2f seconds of data\n", (t_end - t_start)*μs)

  # Resample
  if resample && S.n > 1
    f0 = fs == 0 ? minimum(S.fs[S.fs .> 0]) : fs
    N = floor(Int64, f0*(t_end-t_start)*μs)-1
    for i = 1:S.n
      S.fs[i] == 0 && continue
      isapprox(S.fs[i],f0) && continue
      S.x[i] = resample(S.x[i], f0/S.fs[i])
      S.fs[i] = f0
      note(S, i, @sprintf("Resampled to %.1f", f0))
    end
  end

  sstr = string(Dates.unix2datetime(t_start*μs))
  tstr = string(Dates.unix2datetime(t_end*μs))

  # Pad and truncate
  end_times += start_times

  # Loop over non-timeseries data
  for i in c
    if S.fs[i] == 0
      t = cumsum(S.t[i][:,2])
      j = find(t_start .< t .< t_end)
      S.x[i] = S.x[i][j]
      if isempty(j)
        S.t[i] = Array{Int64,2}()
        note(S, i, @sprintf("Channel emptied; no samples in range %s--%s.", sstr, tstr))
      else
        t = t[j]
        t = [t[1]; diff(t)]
        S.t[i] = reshape(t,length(t),1)
        note(S, i, @sprintf("Samples outside range %s--%s pulled.", sstr, tstr))
      end
    end
  end

  # PRE LOOP: fill empty items
  for i = 1:S.n
    if length(S.x[i]) == 0 && S.fs[i] > 0
      S.x[i] = zeros(1 + round(Int, S.fs[i]*(t_end-t_start)*μs))
      S.t[i] = [1 t_start; length(S.x[i]) t_end]
      note(S, i, "Replaced empty data array with zeros.")
    end
  end

  # FIRST LOOP: START TIMES.
  for i in k
    fsμ = S.fs[i]*μs
    dt = round(Int, 1/fsμ)

    mx = mean(S.x[i])

    # truncate X to values within bounds
    t = t_expand(S.t[i], S.fs[i])
    j = find(t_start .< t .< t_end)
    S.x[i] = S.x[i][j]

    # prepend time series data that begin late
    if (start_times[i] - t_start) >= dt
      ni = round(Int, (start_times[i]-t_start)*fsμ)
      prepend!(S.x[i], collect(repeated(mx, ni)))
      note(S, i, join(["Prepended ", ni, " values."]))
    end
    end_times[i] = t_start + round(Int, length(S.x[i])/fsμ)

    if (t_end - end_times[i]) >= dt
      ii = round(Int, (t_end-end_times[i])*fsμ)
      append!(S.x[i], collect(repeated(mx, ii)))
      note(S, i, join(["Appended ", ii, " values."]))
    end
    S.t[i] = [1 t_start; length(S.x[i]) 0]
    note(S, i, "Synched to "*sstr*" -- "*tstr)
  end
  return S
end

"""
    T = sync(S)

Synchronize time ranges of S and pad data gaps.

    T = sync(S, downsample=true)

Synchronize S and downsample data to the lowest non-null interval in S.fs.
"""
sync(S::SeisData; r=false::Bool) = (T = deepcopy(S); sync!(T, resample=r);
  return T)

function autotuk!(x, v, u)
  g = find(diff(v) .> 1)
  L = length(g)
  if L > 0
    w = Array{Int64,2}(0,2)
    v[g[1]] > 1 && (w = cat(1, w, [1 v[g[1]]]))
    v[g[L]] < length(x) && (w = cat(1, w, [v[g[L]+1] length(x)]))
    L > 1 && ([w = cat(1, w, [v[g[i]+1] v[g[i+1]]]) for i = 1:L-1])
    for i = 1:size(w,1)
      (j,k) = w[i,:]
      if (k-j) >= u
        N = round(Int, k-j)
        x[j+1:k] .*= tukey(N, u/N)
      else
        warn(string(@sprintf("Channel %i: Time window too small, ",i),
          @sprintf("x[%i:%i]; replaced with zeros.", j+1, k)))
        x[j+1:k] = 0
      end
    end
  end
  return x
end

"""
    !autotap(U)

Automatically cosine taper (Tukey window) all data in U
"""
function autotap!(U::SeisObj)
  (U.fs == 0 || isempty(U.x)) && return

  # Fill time gaps with NaNs
  ungap!(U, m=false, w=false)

  j = find(!isnan(U.x))
  mx = mean(U.x[j])
  u = round(Int, max(20,0.2*U.fs))

  # remove mean
  U.x[j] .-= mx

  # Then check for auto-fill values (i.e. values that don't change) and NaNs
  # autotuk!(U.x, find(diff(U.x).!=0), u)
  # Removed; leaving this would be a mistake

  # Then check for NaNs
  autotuk!(U.x, find(!isnan(U.x)), u)

  # Then replace NaNs with zeros
  U.x[find(isnan(U.x))] = 0

  # And note it
  note(U, "De-meaned, auto-tapered, and ungapped data; replaced all NaNs with zeros.")
  return U
end
function autotap!(U::SeisData)
  # Fill gaps with NaNs
  ungap!(U, m=false, w=false)

  for i = 1:U.n
    (U.fs[i] == 0 || isempty(U.x[i])) && continue
    j = find(!isnan(U.x[i]))
    mx = mean(U.x[i][j])
    U.x[i][j] .-= mx

    u = round(Int, max(20,0.2*U.fs[i]))

    # Check for NaNs and window around them
    autotuk!(U.x[i], find(!isnan(U.x[i])), u)

    # Replace NaNs with zeros
    U.x[i][find(isnan(U.x[i]))] = 0
    note(U, i, "De-meaned, auto-tapered, and ungapped data; replaced all NaNs with zeros.")
  end
  return U
end

"""
    namestrip(s::AbstractString)

Remove bad characters from S: \,, \\, !, \@, \#, \$, \%, \^, \&, \*, \(, \),
  \+, \/, \~, \`, \:, \|, and whitespace.
"""
namestrip(S::AbstractString) = strip(S, ['\,', '\\', '!', '\@', '\#', '\$',
  '\%', '\^', '\&', '\*', '\(', '\)', '\+', '\/', '\~', '\`', '\:', '\|', ' '])

"""
    add_fake_net!(S, NET)

Insert arbitrary network code NET at the start of all IDs with no specified
network (i.e. IDs that begin with a '.'). Only the first two characters of NET
are used.
"""
function add_fake_net!(S::SeisData, str::ASCIIString)
  if length(str) > 2
    str = str[1:2]
  end
  str = uppercase(str)
  for i = 1:S.n
    if startswith(S.id[i],'.')
      S.id[i] = join(str, S.id[i][2:end])
    end
  end
end
