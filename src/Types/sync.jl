"""
    ungap!(S)

Fill time gaps in S with the mean of data in S. If S is a SeisData structure,
time gaps in channel [i] are filled with the mean value of each channel's data.
"""
function ungap!(S::SeisChannel; m=true::Bool, w=true::Bool)
  N = size(S.t,1)-2
  (N ≤ 0 || S.fs == 0) && return S
  gapfill!(S.x, S.t, S.fs, m=m, w=w)
  note!(S, @sprintf("ungap! filled %i gaps (sum = %i microseconds)", N, sum(S.t[2:end-1,2])))
  S.t = [reshape(S.t[1,:],1,2); [length(S.x) 0]]
  return S
end
function ungap!(S::SeisData; m=true::Bool, w=true::Bool)
  for i = 1:S.n
    N = size(S.t[i],1)-2
    (N ≤ 0 || S.fs[i] == 0) && continue
    gapfill!(S.x[i], S.t[i], S.fs[i], m=m, w=w)
    note!(S, i, @sprintf("ungap! filled %i gaps (sum = %i microseconds)", N, sum(S.t[i][2:end-1,2])))
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
  s="max"::Union{String,DateTime}, t="max"::Union{String,DateTime},
  v=false::Bool, z=true::Bool)

  # PREPROCESS
  z && deleteat!(S, findall([isempty(S.x[i]) for i =1:S.n])) # delete (zap) empty channels
  ungap!(S, m=false, w=false)                               # ungap

  S.n < 2 && return nothing                                 # pointless to continue

  # Resample
  if resample && S.n > 1
    f0 = fs == 0 ? minimum(S.fs[S.fs .> 0]) : fs
    N = floor(Int64, f0*(t_end-t_start)*SeisIO.μs)-1
    for i = 1:S.n
      S.fs[i] == 0 && continue
      isapprox(S.fs[i],f0) && continue
      S.x[i] = resample(S.x[i], f0/S.fs[i])
      S.fs[i] = f0
      note!(S, i, @sprintf("sync! resampled from %.1f Hz to %.1f Hz.", f1, f0))
    end
  end

  # Do not edit order of operations -------------------------------------------
  start_times = zeros(Int64, S.n)
  end_times = zeros(Int64, S.n)

  # non-timeseries data
  c = findall(S.fs .== 0)
  for i in c
    start_times[i] = S.t[i][1,2]
    end_times[i] = sum(S.t[i][:,2])
  end

  # non-null timeseries data
  k = findall((S.fs .> 0).*[!isempty(S.x[i]) for i=1:S.n])
  for i in k
    start_times[i] = S.t[i][1,2]
    end_times[i] = start_times[i] + round(Int64, (length(S.x[i])-1)/(SeisIO.μs*S.fs[i]))
  end
  # Do not edit order of operations -------------------------------------------

  # Start and end times
  t_start = SeisIO.get_sync_t(s, start_times, k)
  t_end = SeisIO.get_sync_t(t, end_times, k)
  t_end <= t_start && error("No time overlap with given start & end times!")
  if v
    @printf(stdout, "Synching %.2f seconds of data\n", (t_end - t_start)*SeisIO.μs)
    println("t_start = ", t_start, " μs from epoch")
    println("t_end = ", t_end, " μs from epoch")
  end
  sstr = string(Dates.unix2datetime(t_start*SeisIO.μs))
  tstr = string(Dates.unix2datetime(t_end*SeisIO.μs))

  # Loop over non-timeseries data
  for i in c
    t = cumsum(S.t[i][:,2])
    j = findall(t_start .≤ t .< t_end)
    S.x[i] = S.x[i][j]
    if isempty(j)
      S.t[i] = Array{Int64,2}()
      note!(S, i, @sprintf("sync! emptied channel; no data in range %s--%s", sstr, tstr))
    else
      t = t[j]
      t = [t[1]; diff(t)]
      S.t[i] = reshape(t,length(t),1)
      note!(S, i, @sprintf("sync! pulled samples outside range %s--%s", sstr, tstr))
    end
  end

  # Synchronization loop
  for i in k
    fμs = S.fs[i]*SeisIO.μs
    dt = round(Int64, 1/fμs)
    mx = mean(S.x[i])

    # truncate X to values within bounds
    t = SeisIO.t_expand(S.t[i], S.fs[i])
    j = findall(t_start .≤ t .< t_end)
    S.x[i] = S.x[i][j]

    # prepend points to time series data that begin late
    if (start_times[i] - t_start) >= dt
      ni = round(Int64, (start_times[i]-t_start)*fμs)
      prepend!(S.x[i], collect(Main.Base.Iterators.repeated(mx, ni)))
      note!(S, i, string("sync! prepended ", ni, " values."))
    end
    end_times[i] = t_start + round(Int64, length(S.x[i])/fμs)

    # append points to time series data that end early
    if (t_end - end_times[i]) >= dt
      ii = round(Int64, (t_end-end_times[i])*fμs)
      append!(S.x[i], collect(Main.Base.Iterators.repeated(mx, ii)))
      note!(S, i, string("sync! appended ", ii, " values."))
    end
    S.t[i] = [1 t_start; length(S.x[i]) 0]
    note!(S, i, string("sync! synchronized times to ", sstr, " -- ", tstr))
  end
  return nothing
end

"""
    T = sync(S)

Synchronize time ranges of S and pad data gaps.

    T = sync(S, downsample=true)

Synchronize S and downsample data to the lowest non-null interval in S.fs.
"""
sync(S::SeisData; r=false::Bool) = (T = deepcopy(S); sync!(T, resample=r);
  return T)
