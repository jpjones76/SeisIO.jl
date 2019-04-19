export sync, sync!

function get_sync_t(s::Union{String,DateTime}, t::Array{Int64,1})
  isa(s, DateTime) && return floor(Int64, d2u(s)*sμ)
  if s == "first"
    return minimum(t)
  elseif s == "last"
    return maximum(t)
  else
    return floor(Int64, d2u(DateTime(s))*sμ)
  end
end

function get_sync_inds(t::AbstractArray{Int64,1}, Ω::Bool, t₀::Int64, t₁::Int64)
  if Ω == true
    return union(findall(t.<t₀), findall(t.>t₁))
  else
    return findall(t.<t₀)
  end
end

"""
sync!(S::SeisData)

Synchronize the start times of all data in S to begin at or after the last
start time in S.

sync!(S, [s=ST, t=ET, v=VV])

Synchronize all data in S to start at `ST` and terminate at `EN` with verbosity level VV.

For regularly-sampled channels, gaps between the specified and true times
are filled with the mean; this isn't possible with irregularly-sampled data.

#### Specifying start time
* s="last": (Default) sync to the last start time of any channel in `S`.
* s="first": sync to the first start time of any channel in `S`.
* A numeric value is treated as an epoch time (`?time` for details).
* A DateTime is treated as a DateTime. (see Dates.DateTime for details.)
* Any string other than "last" or "first" is parsed as a DateTime.

#### Specifying end time (t)
* t="none": (Default) end times are not synchronized.
* t="last": synchronize all channels to end at the last end time in `S`.
* t="first" synchronize to the first end time in `S`.
* numeric, datetime, and non-reserved strings are treated as for `-s`.

Related functions: time, Dates.DateTime, parsetimewin
"""
function sync!(S::SeisData;
                s="last"::Union{String,DateTime},
                t="none"::Union{String,DateTime},
                v::Int64=KW.v,
                )

  # Dekete empty traces
  deleteat!(S, findall([isempty(S.x[i]) for i =1:S.n]))     # delete (zap) empty channels
  S.n == 0 && return nothing                                # pointless to continue

  do_end = t=="none" ? false : true

  # Do not edit order of operations -------------------------------------------
  start_times = zeros(Int64, S.n)
  if do_end
    end_times = zeros(Int64, S.n)
  end

  # non-timeseries data
  irr = falses(S.n)
  non_ts = findall(S.fs .== 0)
  irr[non_ts] .= true
  z = zero(Int64)
  for i = 1:S.n
    start_times[i] = S.t[i][1,2]
    if do_end
      end_times[i] = S.t[i][end,2] + (irr[i] ? z : start_times[i] + sum(S.t[i][2:end,2]) +
        round(Int64, (length(S.x[i])-1)/(μs*S.fs[i])))
        # ts data: start time in μs from epoch + sum of time gaps in μs + length of trace in μs
        # non-ts data: time of last sample
    end
  end
  # Do not edit order of operations -------------------------------------------

  # Start and end times
  t_start = get_sync_t(s, start_times)
  sstr = string(u2d(t_start*μs))

  if do_end
    t_end = get_sync_t(t, end_times)
    t_end > t_start || error("No time overlap with given start & end times!")
    tstr = string(u2d(t_end*μs))
    if v > 0
      @info(@sprintf("Synchronizing %.2f seconds of data\n", (t_end - t_start)*μs))
      if v > 1
        @info(string("t_start = ", u2d(t_start*μs)))
        @info(string("t_end = ", tstr))
    end
    elseif v > 0
      @info(string("Synchronizing to start at ", u2d(t_start*μs)))
    end
  else
    t_end = z
  end

  # Loop over non-timeseries data
  dflag = falses(S.n)
  for i in non_ts
    t = view(S.t[i], :, 2)
    Lt = length(t)

    j = get_sync_inds(t, do_end, t_start, t_end)
    Lj = length(j)
    if Lj ≥ Lt
      dflag[i] = true
      continue
    elseif do_end
      note!(S, i, @sprintf("sync!, s = %s, t = %s, removed %i samples (out of time range) from :x", sstr, tstr, Lj))
    else
      note!(S, i, @sprintf("sync! s = %s, t = none, removed %i samples (out of time range) from :x", sstr, Lj))
    end
    ti = collect(1:Lt)
    deleteat!(S.x[i], j)
    deleteat!(ti, j)
    S.t[i] = S.t[i][ti,:]
  end

  # Loop over timeseries data
  for i = 1:S.n
    if irr[i] == false
      sync_str = Array{String,1}(undef,0)
      desc_str = ""

      # truncate X to values within bounds
      t = t_expand(S.t[i], S.fs[i])
      j = get_sync_inds(t, do_end, t_start, t_end)
      deleteat!(S.x[i], j)
      deleteat!(t, j)

      #= length 0 traces _can_ happen with resampled :x where (lx*f_rat) < 0.5
      requries short series of high-frequency data resampled to too low fs =#
      if length(S.x[i]) == 0
        dflag[i] = true
        continue
      end

      if !isempty(j)
        push!(sync_str, string("deleted ", length(j), " samples from :x"))
      end

      S.t[i] = t_collapse(t, S.fs[i])

      # prepend points to time series data that begin late
      T = eltype(S.x[i])
      fμs = S.fs[i]*μs
      dtμ = round(Int64, 1/fμs)
      μ_x = T(mean(S.x[i]))

      if (start_times[i] - t_start) ≥ dtμ
        ni = div(start_times[i]-t_start, dtμ)
        prepend!(S.x[i], ones(T, ni).*μ_x)

        # corrected 2019-02-28
        S.t[i][1,2] = S.t[i][1,2] - ni*dtμ

        push!(sync_str, string("prepended ", ni, " samples to :x."))
      end

      # append points to time series data that end early
      if do_end
        end_times[i] = S.t[i][1,2] +
                        sum(S.t[i][2:end,2]) +
                        round(Int64, length(S.x[i])/fμs)
        if (t_end - end_times[i]) ≥ dtμ
          ni = div(t_end-end_times[i], dtμ)
          append!(S.x[i], ones(T,ni).*μ_x)

          push!(sync_str, string("appended ", ni, " samples to :x."))
        end

        # Correct for length aberration if necessary
        S.t[i][end,1] = length(S.x[i])

        desc_str = string("sync!, s = ", sstr, ", t = ", tstr)
      else
        desc_str = string("sync!, s = ", sstr, ", t = none")
      end

      if length(sync_str) > 0
        desc_str *= string(", ", join(sync_str, ";"))
      end
      note!(S, i, desc_str)
    end
  end
  del_flagged!(S, dflag, "length 0 after sync")
  return nothing
end

"""
    T = sync(S)

Synchronize time ranges of S and pad data gaps.

    T = sync(S, rs=true)

Synchronize S and downsample data to the lowest non-null interval in S.fs.
"""
function sync( S::SeisData;
                s="last"::Union{String,DateTime},
                t="none"::Union{String,DateTime},
                v::Int64=KW.v )

  T = deepcopy(S)
  sync!(T, s=s, t=t, v=v)
  return T
end
