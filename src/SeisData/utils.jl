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
    namestrip(s::AbstractString)

Remove bad characters from S: \,, \\, !, \@, \#, \$, \%, \^, \&, \*, \(, \),
  \+, \/, \~, \`, \:, \|, and whitespace.
"""
namestrip(S::AbstractString) = strip(S, ['\,', '\\', '!', '\@', '\#', '\$',
  '\%', '\^', '\&', '\*', '\(', '\)', '\+', '\/', '\~', '\`', '\:', '\|', ' '])

"""
    gapfill!(x::Array{Float64,1}, t::Array{Float64,2}, fs::Float64)

Fill gaps in x, as specified in t, assuming sampling rate fs
"""
function gapfill!(x::Array{Float64,1}, t::Array{Float64,2}, fs::Float64)
  (fs == 0 || fs == Inf) && (return x)
  m = mean(x)
  u = round(Int, max(20,0.2*fs))
  for i = size(t,1):-1:2
    g = t[i,2]
    g < 0 && (warn(@sprintf("Channel %i: Negative time gap (t = %.3f); skipped.", i, g)); continue)
    (g == 0 && i < size(t,1)) && continue
    j = Int(t[i-1,1])
    k = Int(t[i,1])
    if (k-j) >= u
      N = round(Int, k-j)
      x[j+1:k] .*= tukey(N, u/N)
    else
      warn(string(@sprintf("Channel %i: Time window too small, ",i),
        @sprintf("x[%i:%i]; replaced with mean.", j+1, k)))
      x[j+1:k] = m
    end
    splice!(x, k:k-1, m.*ones(round(Int, fs*g)))
  end
  return x
end
gapfill(x::Array{Float64,1}, t::Array{Float64,2}, f::Float64) =
  (y = deepcopy(x); gapfill!(y,t,f); return y)

"""
    ungap!(S)

Fill time gaps in S with the mean of data in S. If S is a SeisData structure,
time gaps in channel [i] are filled with the mean value of each channel's data.
"""
function ungap!(S::SeisObj)
  N = size(S.t,1)-2
  (N ≤ 0 || S.fs == 0) && return S
  L = sum(S.t[2:end-1,2])
  gapfill!(S.x, S.t, S.fs)
  note(S, @sprintf("Filled %i gaps (%i total points)", N, L))
  S.t = [S.t[1,:]; [length(S.x) 0.0]]
  return S
end
function ungap!(S::SeisData)
  for i = 1:1:S.n
    N = size(S.t[i],1)-2
    (N ≤ 0 || S.fs[i] == 0) && continue
    L = sum(S.t[i][2:end-1,2])
    gapfill!(S.x[i], S.t[i], S.fs[i])
    note(S, i, @sprintf("Filled %i gaps (%i total points)", N, L))
    S.t[i] = [S.t[i][1,:]; [length(S.x[i]) 0.0]]
  end
  return S
end
ungap(S::Union{SeisData,SeisObj}) = (T = deepcopy(S); ungap!(T))

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
  if isa(s,Real)
    t_start = s
  elseif isa(s,DateTime)
    t_start = Dates.datetime2unix(s)
  else
    start_times = [S.t[i][1,2] for i=1:S.n]
    k = find(S.fs .> 0)
    starts = start_times[k]
    if s == "max"
      t_start = minimum(starts)
    elseif s == "min"
      t_start = maximum(starts)
    else
      t_start = Dates.datetime2unix(DateTime(s))
    end
  end
  if isa(t,Real)
    t_end = t
  elseif isa(t,DateTime)
    t_end = Dates.datetime2unix(t)
  else
    end_times = [sum(S.t[i][2:end,2]) + length(S.x[i])/S.fs[i] for i=1:S.n]
    k = find(isfinite, end_times)
    ends = end_times[k] + start_times[k]
    if t == "max"
      t_end = maximum(ends)
    elseif t == "min"
      t_end = minimum(ends)
    else
      t_end = Dates.datetime2unix(DateTime(t))
    end
  end
  t_end <= t_start && error("No time overlap with given start \& end times!")
  @printf(STDOUT, "Synching %.2f seconds of data\n", t_end - t_start)

  # Resample
  if resample && S.n > 1
    ungap!(S)
    f0 = fs == 0 ? minimum(S.fs[0 .< S.fs .< Inf]) : fs
    N = floor(Int64, f0*(t_end-t_start))-1
    t = cat(1, 0, collect(repeated(1/f0, N)))
    for i = 1:S.n
      S.fs[i] == 0 && continue
      isapprox(S.fs[i],f0) && continue
      S.x[i] = resample(S.x[i], rationalize(f0/S.fs[i]))
      S.fs[i] = f0
      note(S, i, @sprintf("Resampled to %.1f", f0))
    end
  end

  sstr = string(Dates.unix2datetime(t_start))
  tstr = string(Dates.unix2datetime(t_end))

  # Pad and truncate
  for i = 1:S.n
    # non-ts data are never padded; only truncated
    if S.fs[i] == 0
      t = cumsum(S.t[i][:,2])
      j = find(t_start .< t .< t_end)
      S.x[i] = S.x[i][j]
      if isempty(j)
        S.t[i] = Array{Float64,2}()
        note(S, i, @sprintf("Channel emptied (campaign-style data with no measurements in range %s--%s)", sstr, tstr))
      else
        t = t[j]
        t = [t[1]; diff(t)]
        L = length(t)
        S.t[i] = [zeros(L,1) reshape(t,L,1)]
        note(S, i, @sprintf("Channel restricted to time range range %s--%s)", sstr, tstr))
      end
    elseif length(S.x[i]) == 0
      S.x[i] = zeros(1 + round(Int, S.fs[i]*(t_end-t_start)))
      S.t[i] = [1.0 t_start; length(S.x[i]) t_end]
      note(S, i, @sprintf("Replaced empty data array with zeros to fill time range range %s--%s)", sstr, tstr))
    else
      sf = true
      ef = true
      dt = 1/S.fs[i]
      if (start_times[i] - t_start) > dt
        sstr0 = string(Dates.unix2datetime(start_times[i]))
        unshift!(S.x[i], mean(S.x[i]))
        t_new = [1.0 t_start; 2.0 start_times[i]-t_start]
        S.t[i] = cat(1, t_new, S.t[i][2:end,:])
        sf = false
        note(S, i, @sprintf("Extended start time from %s to %s", sstr0, sstr))
      end
      if (t_end - end_times[i]) > dt
        tstr0 = string(Dates.unix2datetime(end_times[i]+start_times[i]))
        #t_end_new = end_times[i]-t_start
        push!(S.x[i], mean(S.x[i]))
        L = Float64(length(S.x[i]))
        S.t[i] = cat(1, S.t[i][1:end-1,:], [L end_times[i]-dt])
        ef = false
        note(S, i, @sprintf("Extended end time from %s to %s", tstr0, tstr))
      end
      if sf || ef
        dt = 1/S.fs[i]
        t = t_expand(S.t[i], dt)
        I = find(t_start .< t .< t_end)
        S.t[i] = t_collapse(t[I], dt)
        S.x[i] = S.x[i][I]
      end
    end
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
