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
function ungap!(S::SeisChannel; m=true::Bool, w=true::Bool)
  N = size(S.t,1)-2
  (N ≤ 0 || S.fs == 0) && return S
  gapfill!(S.x, S.t, S.fs, m=m, w=w)
  note(S, @sprintf("Filled %i gaps (sum = %i microseconds)", N, sum(S.t[2:end-1,2])))
  S.t = [reshape(S.t[1,:],1,2); [length(S.x) 0]]
  return S
end
function ungap!(S::SeisData; m=true::Bool, w=true::Bool)
  for i = 1:1:S.n
    N = size(S.t[i],1)-2
    (N ≤ 0 || S.fs[i] == 0) && continue
    gapfill!(S.x[i], S.t[i], S.fs[i], m=m, w=w)
    note(S, i, @sprintf("Filled %i gaps (sum = %i microseconds)", N, sum(S.t[i][2:end-1,2])))
    S.t[i] = [reshape(S.t[i][1,:],1,2); [length(S.x[i]) 0]]
  end
  return S
end
ungap(S::Union{SeisData,SeisChannel}; m=true::Bool, w=true::Bool) = (T = deepcopy(S); ungap!(T, m=m, w=w))

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
  s="max"::Union{String,Real,DateTime},
  t="max"::Union{String,Real,DateTime},
  v=false::Bool)

  for i = 1:S.n
    S.x[i] -= mean(S.x[i])
  end
  ungap!(S, m=false, w=false)
  #autotap!(S)

  # Do not edit order of operations -------------------------------------------
  start_times = zeros(Int64, S.n)
  end_times = zeros(Int64, S.n)

  # non-timeseries data
  c = find(S.fs .== 0)
  for i in c
    start_times[i] = S.t[i][1,2]
    end_times[i] = sum(S.t[i][:,2])
  end

  # non-null timeseries data
  k = find((S.fs .> 0).*[!isempty(S.x[i]) for i=1:S.n])
  for i in k
    start_times[i] = round(Int, S.t[i][1,2]*S.fs[i]) / S.fs[i]
    end_times[i] = start_times[i] + round(Int, length(S.x[i])/(μs*S.fs[i]))
  end
  # Do not edit order of operations -------------------------------------------
  v && println("start_times = ", start_times)
  v && println("end_times = ", end_times)

  # Possible options for s
  v && println("s = ", s)
  if isa(s,Real)
    t_start = round(Int, s/μs)
  elseif isa(s,DateTime)
    t_start = round(Int, Dates.datetime2unix(s)/μs)
  else
    starts = start_times[k]
    v && println("starts = ", starts)
    if s == "max"
      t_start = floor(Int, minimum(starts))
    elseif s == "min"
      t_start = ceil(Int, maximum(starts))
    else
      t_start = round(Int, Dates.datetime2unix(DateTime(s))/μs)
    end
  end
  v && println("t_start =", t_start)

  # Possible options for t
  v && println("t = ", t)
  if isa(t,Real)
    t_end = t_start + round(Int, t/μs)
  elseif isa(t,DateTime)
    t_end = round(Int, Dates.datetime2unix(t)/μs)
  else
    if t == "max"
      t_end = maximum(end_times)
    elseif t == "min"
      t_end = minimum(end_times)
    else
      t_end = round(Int, Dates.datetime2unix(DateTime(t))/μs)
    end
  end
  v && println("t_end =", t_end)

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
  v && println("t_start = ", t_start)
  v && println("t_end = ", t_end)
  sstr = string(Dates.unix2datetime(t_start*μs))
  tstr = string(Dates.unix2datetime(t_end*μs))

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
