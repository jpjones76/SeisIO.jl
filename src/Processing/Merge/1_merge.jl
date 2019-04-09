import Base: *, merge!, merge
export mseis!

# The following must be the same to merge:
# :loc
# :resp
# :fs
# :units

# The following are easily dealt with
# :gain
# Gain can be translated with no trouble.

# ============================================================================

"""
    merge!(S::SeisData, U::SeisData)

Merge two SeisData structures. For timeseries data, a single-pass merge-and-prune
operation is applied to value pairs whose sample times are separated by less than
half the sampling interval.

    merge!(S::SeisData)

"Flatten" a SeisData structure by merging data from each unique ID into a single channel.

#### Merge Behavior
* Non-overlapping data are concatenated and sample times are adjusted.
* If two data segments contain no gaps, a "fast merge" operation checks and
  corrects for 1-2 sample time shifts to prevent start time rounding inconsistencies.
  However, these checks are only possible on a per-channel basis.
* For gapped or non-identical data, pairs of samples x_i, x_j : |t_i-t_j| < (1/2*S.fs)
  are averaged. Warnings are thrown when non-identical data are merged.

#### Potential Pitfalls
* It's best to only merge unprocessed data. Merging data segments that were
processed independently (e.g. detrended) will throw many warnings because the
processed traces differ slightly in the overlap window.
* If necessary, time series from the same channel sampled at different Fs will
be resampled to the lowest Fs for that channel ID.

`merge!` always invokes `sort!` before return to ensure that the "*" operator is
commutative.
"""
function merge!(S::SeisData;
    v::Int = KW.v)

  # Initialize variables
  UID = unique(S.id)
  L = length(UID)
  cnt = 0
  N_warn = 0
  note_head = string(SeisIO.timestamp(), ": ")
  to_delete = Array{Int64,1}(undef, 0)

  for cnt = 1:length(UID)
    id = UID[cnt]
    GRP = findall(S.id.==id)

    # Prep step: remove group members with no data
    no_data = GRP[findall([(length(S.x[i]) == 0 || size(S.t[i]) == (0,0)) for i in GRP])]
    if length(no_data) > 0
      @warn(string("Deleting channels (either :x or :t is empty): ", no_data, ", id = ", id))
      deleteat!(S, no_data)
      N_warn += 1
      GRP = findall(S.id.==id)
    end

    N_grp = length(GRP)
    (N_grp ≤ 1) && continue

    SUBGRPS = get_subgroups(S, GRP)

    for subgrp in SUBGRPS
      subgrp = sort(subgrp)
      N_sub = length(subgrp)
      N_sub == 1 && continue

      # These are all the same
      i1    = subgrp[1]
      fs    = S.fs[i1]
      if fs == 0.0
        Ω = merge_non_ts!(S, subgrp)
        append!(to_delete, subgrp[subgrp.!=Ω])
        continue
      end
      Δ = round(Int64, sμ/fs)
      loc   = S.loc[i1]
      resp  = S.resp[i1]
      units = S.units[i1]

      # ====================================
      # Let ind_last be the index in subgrp to the member with the last end time
      # Let Ω be the corresponding index in S
      # ind_last = argmax(te)

      # Index of final channel for merge
      (ts, te, pa, pi, xs, xe) = get_time_windows(S, subgrp, Δ)

      Ω = pa[argmax(te)]
      rest = subgrp[subgrp.!=Ω]
      # ====================================

      # GAIN, SRC =============================================================
      gain = getindex(getfield(S, :gain), Ω)
      for (i, g) in enumerate(rest)
        scalefac = gain / S.gain[i]
        if !isapprox(scalefac, 1.0)
          rmul!(S.x[g], scalefac)
        end
        if S.src[g] != S.src[Ω]
          push!(S.notes[Ω], string(note_head, "+src: ", S.src[g]))
        end
      end

      # NAME ==================================================================
      (length(unique(S.name[subgrp])) == 1) ||
        (v > 0 && @info(string(id, ": name changes across inputs; using most recent.")))

      # NOTES =================================================================
      S.notes[Ω] = sort(vcat(getfield(S, :notes)[subgrp]...))

      # MISC ==================================================================
      merge!(S.misc[Ω], getfield(S, :misc)[rest]...)

      # T,X ===================================================================
      (src, dest) = get_next_pair(S, subgrp, Δ)
      while (src, dest) != ((0,0,0,0), (0,0,0,0))
        ts_i = src[1]; te_i = src[2]; p = src[3]; p_i = src[4]
        ts_j = dest[1]; te_j = dest[2]; q = dest[3]; q_i = dest[4]
        ts_max = max(ts_i, ts_j)
        te_min = min(te_i, te_j)
        nov = 1 + div(te_min - ts_max, Δ)

        # (1) determine the times and indices of overlap within each pair

        # a. determine sample times of overlap
        Ti = collect(ts_max:Δ:te_min)
        Tj = deepcopy(Ti)

        # b. get sample indices within each overlap window
        # i
        xsi_i = div(ts_max - ts_i, Δ) + 1 + (p_i > 1 ? S.t[p][p_i,1]-1 : 0)
        xei_i = xsi_i + nov - 1
        # j
        xsi_j = div(ts_max - ts_j, Δ) + 1 + (q_i > 1 ? S.t[q][q_i,1]-1 : 0)
        xei_j = xsi_j + nov - 1

        # (2) Extract sample windows
        Xi = S.x[p][xsi_i:xei_i]
        Xj = S.x[q][xsi_j:xei_j]
        lxp = length(S.x[p])
        lxq = length(S.x[q])

        # Check for misalignment:
        T, X, do_xtmerge, δj = check_alignment(Ti, Tj, Xi, Xj, Δ)
        if do_xtmerge
          xtmerge!(T, X, div(Δ,2))
        end
        if δj != 0
          xsi_i += δj
          xei_j -= δj
        end

        # (3) Merge X,T into S[q]
        deleteat!(S.x[q], xsi_j:xei_j)
        if xsi_j == 1
          prepend!(S.x[q], X)
        else
          splice!(S.x[q], xsi_j:xsi_j-1, X)
        end

        # (4) Delete S.x[p][xsi_i:xei_i]
        deleteat!(S.x[p], xsi_i:xei_i)
        nxq = length(S.x[q]) - lxq
        nxp = lxp - length(S.x[p])

        # Convert S.t[q] to time window
        wq = t_win(S.t[q], Δ)

        # Decrement wq[q_i,1] by nxq*Δ
        nwq = size(wq,1)
        for i = q_i:nwq
          wq[i, 1] += nxq*Δ
          wq[i, 2] += nxq*Δ
        end

        # Sort by start time, to be safe
        ii = sortperm(wq[:,1])
        wq = wq[ii,:]

        # Convert back to time
        S.t[q] = w_time(wq, Δ)

        # (5) Adjust window p_i in S.t[p]
        wp = t_win(S.t[p], Δ)
        wp[p_i, 2] -= (nxp + δj)*Δ
        wp[p_i, 1] -= δj*Δ
        if wp[p_i, 2] - wp[p_i, 1] == -Δ
          wp = wp[setdiff(1:end, p_i), :]
        end
        S.t[p] = w_time(wp, Δ)

        # Repeat until no further merges are possible
        (src, dest) = get_next_pair(S, subgrp, Δ)
      end

      #= At this point, we have nothing left that can be merged. So we're going
      to arrange T[subgrp] and X[subgrp] in windows using t_win =#
      ts, te, pa, pi, xsi, xei = get_time_windows(S, subgrp, Δ, rev=false)
      nt = length(ts)
      nx = sum(broadcast(+, xei-xsi, 1))
      X = Array{eltype(S.x[Ω]),1}(undef, nx)
      xi = 1
      for i = 1:nt
        lx     = xei[i] - xsi[i] + 1
        unsafe_copyto!(X, xi, S.x[pa[i]], xsi[i], lx)
        xi += lx
      end
      S.t[Ω] = combine_t_fields(S.t[subgrp], Δ)
      S.x[Ω] = X

      append!(to_delete, rest)
    end
    # Done with SUBGRPS
  end
  if N_warn > 0
    @info(string("Total warnings: ", N_warn))
  end
  deleteat!(S, to_delete)
  return S
end
