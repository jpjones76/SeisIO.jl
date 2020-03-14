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

# # still used for irregular data
function get_sync_inds(t::AbstractArray{Int64,1}, Ω::Bool, t₀::Int64, t₁::Int64)
  if Ω == true
    return union(findall(t.<t₀), findall(t.>t₁))
  else
    return findall(t.<t₀)
  end
end

function get_del_ranges(xi::Array{Int64, 2}, nx::Int64)
  nw = size(xi, 1)
  x_del = Array{UnitRange, 1}(undef, 0)
  sizehint!(x_del, nw+1)

  # Does first row start at 1?
  if xi[1] != 1
    push!(x_del, UnitRange(1, xi[1]-1))
  end

  # Any gaps in rows 2:n-1
  for i in 2:nw
    if xi[i,1] - xi[i-1,2] > 1
      push!(x_del, UnitRange(xi[i-1,2]+1, xi[i,1]-1))
    end
  end

  # Does last row end at nx?
  if xi[nw,2] < nx
    push!(x_del, UnitRange(xi[nw,2]+1, nx))
  end

  return x_del
end

#=
OUTPUTS
xi  start and end indices of X to keep
W   truncated time windows
=#
function sync_t(t::Array{Int64, 2}, Δ::Int64, t_min::Int64, t_max::Int64)
  (t_max == 0) && (t_max = typemax(Int64))
  xi = x_inds(t)
  W = t_win(t, Δ)
  nw = size(W, 1)
  wi = zeros(Int64, nw, 2)
  wk = Array{Bool, 1}(undef, nw)
  fill!(wk, true)
  for i in 1:nw
    if (W[i,2] < t_min) || (W[i,1] > t_max)
      wk[i] = false
      continue
    end

    # Find last index ≤ t_max
    if W[i,2] > t_max
      k = xi[i,2]
      v = W[i,2]
      while v > t_max
        v -= Δ
        k -= 1
      end
      W[i,2] = v
      xi[i,2] = k
    end

    # Find first index ≥ t_min
    if W[i,1] < t_min
      j = xi[i,1]
      v = W[i,1]
      while v < t_min
        j += 1
        v += Δ
      end
      W[i,1] = v
      xi[i,1] = j
    end
  end

  # eliminated windows
  if minimum(wk) == false
    W = W[wk, :]
    xi = xi[wk, :]
  end
  return xi, W
end
# ==========

@doc """
sync!(S::GphysData)

Synchronize the start times of all data in S to begin at or after the last
start time in S.

sync!(S[, s=TS, t=TT, pad=false, v=V])

Synchronize all data in S to start no earlier than `TS` and terminate no later
than `TT`, with verbosity level `V`.

By default, a channel with mean `μᵢ = mean(S.x[i])` that begins after `TS` is
prepended with `μᵢ` to begin exactly at `TS`; similarly, if keyword `t` is used,
`μᵢ` is appended so that data ends at `TT`. If `pad=false`, channels that begin
after `TS` or end before `TT` are not extended in either direction.

For regularly-sampled channels, gaps between the specified and true times
are filled with the mean; this isn't possible with irregularly-sampled data.

#### Specifying start time (`s=`)
* s="last": (Default) sync to the last start time of any channel in `S`.
* s="first": sync to the first start time of any channel in `S`.
* A numeric value is treated as an epoch time (`?time` for details).
* A DateTime is treated as a DateTime. (see Dates.DateTime for details.)
* Any string other than "last" or "first" is parsed as a DateTime.

#### Specifying end time (`t=``)
* t="none": (Default) end times are not synchronized.
* t="last": synchronize all channels to end at the last end time in `S`.
* t="first" synchronize to the first end time in `S`.
* numeric, datetime, and non-reserved strings are treated as for `s=`.

See also: `TimeSpec`, `Dates.DateTime`, `parsetimewin`

!!! warning

    `sync!` calls `prune!`; empty channels will be deleted.
""" sync!
function sync!(S::GphysData;
                s::Union{String,DateTime}="last",
                t::Union{String,DateTime}="none",
                pad::Bool=true,
                v::Integer=KW.v,
                )

  # Delete empty traces
  prune!(S)                                         # delete empty channels
  S.n == 0 && return nothing                        # pointless to continue

  do_end = t=="none" ? false : true
  proc_str = string("sync!(S, s = \"", s, "\", t = \"", t, "\")")

  # Do not edit order of operations -------------------------------------------
  start_times = zeros(Int64, S.n)
  if do_end
    end_times = zeros(Int64, S.n)
  end
  fs = S.fs
  irr = falses(S.n)
  z = zero(Int64)

  # (1) Determine start and end times
  for i = 1:S.n
    start_times[i] = starttime(S.t[i], S.fs[i])
    if do_end
      end_times[i] = endtime(S.t[i], S.fs[i])
    end
    if fs[i] == 0.0
      irr[i] = true
    end
  end

  # (2) Determine earliest start and latest end
  t_start = get_sync_t(s, start_times)
  t_end = 0
  t_str = "none"
  if do_end
    t_end = get_sync_t(t, end_times)
    (t_end > t_start) || error("No time overlap with given start & end times!")
    t_str = string(u2d(t_end*μs))
    if v > 0
      @info(@sprintf("Synchronizing %.2f seconds of data\n", (t_end - t_start)*μs))
      if v > 1
        @info(string("t_start = ", u2d(t_start*μs)))
        @info(string("t_end = ", t_str))
      end
    end
  elseif v > 0
    @info(string("Synchronizing to start at ", u2d(t_start*μs)))
  end

  # (3) Synchronization to t_start (and maybe t_end)
  dflag = falses(S.n)
  for i = 1:S.n

    # non-timeseries data
    if fs[i] == 0.0
      t = view(S.t[i], :, 2)
      nt = length(t)
      k = get_sync_inds(t, do_end, t_start, t_end)
      nk = length(k)
      if nk ≥ nt
        dflag[i] = true
        proc_note!(S, i, proc_str, "synchronize, :x unchanged")
        continue
      else
        proc_note!(S, i, proc_str, string("synchronize, deleted ", nk, " samples from :x"))
      end
      deleteat!(S.x[i], k)
      ti = collect(1:nt)
      deleteat!(ti, k)
      S.t[i] = S.t[i][ti,:]
      S.t[i][:,1] .= 1:length(S.x[i])

    # timeseries data
    else
      sync_str = Array{String, 1}(undef, 0)
      desc_str = ""

      # truncate X to values within bounds
      Δ = round(Int64, sμ/fs[i])
      (xi, W) = sync_t(S.t[i], Δ, t_start, t_end)
      if isempty(W)
        dflag[i] = true
        continue
      else
        nx = length(S.x[i])
        x_del = get_del_ranges(xi, nx)
        nr = size(x_del, 1)
        for j in nr:-1:1
          if last(x_del[j]) == nx
            resize!(S.x[i], first(x_del[j])-1)
          else
            deleteat!(S.x[i], x_del[j])
          end
        end

        #= length 0 traces _can_ happen with resampled :x
        where (lx*f_rat) < 0.5; requries short series of
        high-frequency data resampled to too-low fs
        =#
        if length(S.x[i]) == 0
          dflag[i] = true
          continue
        end

        if length(S.x[i]) < nx
          push!(sync_str, string("deleted ", nx-length(S.x[i]), " samples from :x"))
        end

        # prepend points to time series data that begin late
        T = eltype(S.x[i])
        μ = T(mean(S.x[i]))
        ni = div(start_times[i] - t_start, Δ)

        sort_segs!(W)
        if (ni > 0) && (pad == true)
          prepend!(S.x[i], ones(T, ni).*μ)
          W[1] -= ni*Δ

          # logging
          push!(sync_str, string("prepended ", ni, " samples to :x."))
        end

        # append points to time series data that end early
        if do_end
          nj = div(t_end - W[end], Δ)
          if (nj > 0) && (pad == true)
            nx = length(S.x[i])
            resize!(S.x[i], nx+nj)
            V = view(S.x[i], nx+1:nx+nj)
            fill!(V, μ)
            W[end] += nj*Δ

            # logging
            push!(sync_str, string("appended ", nj, " samples to :x."))
          end
        end

        # last step
        S.t[i] = w_time(W, Δ)

        # logging
        if length(sync_str) > 0
          desc_str = string(", ", join(sync_str, ";"))
        end
        proc_note!(S, i, proc_str, desc_str)
      end
    end
  end
  del_flagged!(S, dflag, "length 0 after sync")
  return nothing
end

function sync!(C::SeisChannel;
                pad::Bool=true,
                s::Union{String,DateTime}="last",
                t::Union{String,DateTime}="none",
                v::Integer=KW.v )
  S = SeisData(C)
  sync!(S, pad=pad, s=s, t=t, v=v)
  return nothing
end

@doc (@doc sync!)
function sync(S::GphysData;
                pad::Bool=true,
                s::Union{String,DateTime}="last",
                t::Union{String,DateTime}="none",
                v::Integer=KW.v )

  T = deepcopy(S)
  sync!(T, pad=pad, s=s, t=t, v=v)
  return T
end

function sync(C::SeisChannel;
                pad::Bool=true,
                s::Union{String,DateTime}="last",
                t::Union{String,DateTime}="none",
                v::Integer=KW.v )

  U = deepcopy(C)
  S = SeisData(U)
  sync!(S, pad=pad, s=s, t=t, v=v)
  return S[1]
end
