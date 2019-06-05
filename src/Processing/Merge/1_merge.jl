@doc """
    merge!(S::SeisData, U::SeisData[, prune_only=true])

Merge channels of two SeisData structures.

    merge!(S::SeisData[, prune_only=true])

"Flatten" a SeisData structure by merging channels with identical properties.

If `prune_only=true`, the only action taken is deletion of empty and duplicate
channels; `merge!(S, U, prune_only=true)` is identical to an in-place `S+U`.
""" merge!
function merge!(S::Y; v::Int64=KW.v, purge_only::Bool=false) where Y<:GphysData
  # Required preprocessing
  prune!(S)

  # Initialize variables
  ID    = getfield(S, :id)
  NAME  = getfield(S, :name)
  LOC   = getfield(S, :loc)
  FS    = getfield(S, :fs)
  GAIN  = getfield(S, :gain)
  RESP  = getfield(S, :resp)
  UNITS = getfield(S, :units)
  SRC   = getfield(S, :src)
  MISC  = getfield(S, :misc)
  NOTES = getfield(S, :notes)
  T     = getfield(S, :t)
  X     = getfield(S, :x)

  UID = unique(getfield(S, :id))
  cnt = 0
  N_warn = 0
  note_head = string(SeisIO.timestamp(), ": ")
  to_delete = Array{Int64,1}(undef, 0)
  while cnt < length(UID)
    cnt = cnt + 1
    id = getindex(UID, cnt)
    GRP = findall(S.id.==id)
    SUBGRPS = get_subgroups(LOC, FS, RESP, UNITS, GRP)

    for subgrp in SUBGRPS
      N = length(subgrp)
      if N > 1
        # Check for duplicates
        sort!(subgrp)
        u = trues(N)
        while N > 1
          t1 = getindex(T, getindex(subgrp, N))
          x1 = getindex(X, getindex(subgrp, N))

          # if a channel is already known to be a duplicate, skip it
          if getindex(u, N) == true
            j = N
            while j > 1
              j = j-1
              t2 = getindex(T, getindex(subgrp, j))
              x2 = getindex(X, getindex(subgrp, j))
              if t1 == t2 && x1 == x2
                setindex!(u, false, j)
              end
            end
          end

          # flag duplicates for deletion
          append!(to_delete, subgrp[u.==false])
          N = N-1
        end

        subgrp = subgrp[u.==true]
      end
      purge_only == true && continue

      N     = length(subgrp)
      i1    = getindex(subgrp, 1)
      fs    = getindex(FS, i1)
      if fs == 0.0
        Ω = merge_non_ts!(S, subgrp)
        append!(to_delete, subgrp[subgrp.!=Ω])
        continue
      end
      Δ     = round(Int64, sμ/fs)
      w_tmp = Array{Array{Int64,2},1}(undef, N)
      te    = Array{Int64,1}(undef, N)
      for i = 1:N
        m     = getindex(subgrp, i)
        w_m   = t_win(getindex(T, m), Δ)
        n_w   = size(w_m, 1)

        # Store: w_start, w_end, channel_number, window_number, x_start, x_end
        w = hcat(w_m, Array{Int64,2}(undef, n_w, 4))
        j  = 0
        ws = 0
        we = 0
        while j < n_w
          j       = j + 1
          we      = max(we, getindex(w_m, j, 2))
          setindex!(w, m, j, 3)                     # channel number
          setindex!(w, j, j, 4)                     # window number
          setindex!(w, ws+1, j, 5)                  # x_start
          ws      = ws + div(w[j,2]-w[j,1], Δ)+1    # x_end
          setindex!(w, ws, j, 6)
        end
        setindex!(te, we, i)
        setindex!(w_tmp, w, i)
      end
      W   = vcat(w_tmp...)
      ii  = sortperm(W[:,2], rev=true)
      W   = W[ii,:]

      # ====================================
      # Let Ω be the channel number in subgrp with the last end time
      Ω     = subgrp[argmax(te)]
      rest  = subgrp[subgrp.!=Ω]
      # ====================================

      # GAIN, MISC, NAME, NOTES, SRC ==========================================
      gain  = getindex(GAIN, Ω)
      notes = getindex(NOTES, Ω)
      misc  = getindex(MISC, Ω)
      for i in rest
        scalefac = gain / getindex(GAIN, i)
        if scalefac != 1.0
          rmul!(getindex(X, i), scalefac)
        end
        if getindex(SRC, i) != getindex(SRC, Ω)
          push!(notes, string(note_head, "+src: ", getindex(SRC, i)))
        end
        if getindex(NAME, i) != getindex(NAME, Ω)
          push!(notes, string(note_head, "alternate name: ", getindex(NAME, i)))
        end
        append!(notes, getindex(NOTES, i))
        merge!(misc, getindex(MISC, i))
      end
      sort!(notes)

      # EventTraceData extra fields ===========================================
      if Y == EventTraceData
        pha   = PhaseCat()
        az    = getindex(getfield(S, :az), Ω)
        baz   = getindex(getfield(S, :baz), Ω)
        dist  = getindex(getfield(S, :dist), Ω)
        for i in rest
          if az == 0.0
            θ = getindex(getfield(S, :az), i)
            (θ != 0.0) && (az = θ)
          end
          if baz == 0.0
            β = getindex(getfield(S, :baz), i)
            (β != 0.0) && (baz = β)
          end
          if dist == 0.0
            # Δ is already in use, so...
            d = getindex(getfield(S, :dist), i)
            (d != 0.0) && (dist = d)
          end
          merge!(pha, getindex(getfield(S, :pha), i))
        end
        # This guarantees that the phase catalog of Ω overwrites others
        merge!(pha, getindex(getfield(S, :pha), Ω))
        setindex!(getfield(S, :az),     az, Ω)
        setindex!(getfield(S, :baz),   baz, Ω)
        setindex!(getfield(S, :dist), dist, Ω)
        setindex!(getfield(S, :pha),   pha, Ω)
      end

      # T,X ===================================================================
      nW = size(W,1)
      (src, dest) = get_next_pair(W)
      while (src, dest) != (zeros(Int64, 7), zeros(Int64, 7))
        ts_i = src[1];  te_i = src[2];  p = src[3];  p_i = src[4];  os_p = src[5];  W_p = src[7]
        ts_j = dest[1]; te_j = dest[2]; q = dest[3]; q_i = dest[4]; os_q = dest[5]; W_q = dest[7]
        ts_max = max(ts_i, ts_j)
        te_min = min(te_i, te_j)
        nov = 1 + div(te_min - ts_max, Δ)
        Xq = getindex(X, q)

        # (1) determine the times and indices of overlap within each pair
        # a. determine sample times of overlap
        Ti = collect(ts_max:Δ:te_min)
        Tj = deepcopy(Ti)

        # b. get sample indices within each overlap window
        # i
        xsi_i = div(ts_max - ts_i, Δ) + os_p
        xei_i = xsi_i + nov - 1
        # j
        xsi_j = div(ts_max - ts_j, Δ) + os_q
        xei_j = xsi_j + nov - 1

        # (2) Extract sample windows
        Xi = getindex(getindex(X, p), xsi_i:xei_i)
        Xj = getindex(getindex(X, q), xsi_j:xei_j)
        lxp = length(getindex(X, p))
        lxq = length(getindex(X, q))

        # ================================================================
        # check for duplicate windows
        if (ts_i == ts_j) && (te_i == te_j) && (Xi == Xj)
          # delete time window
          W = W[setdiff(1:end, W_p), :]
        else
          # Check for misalignment:
          τ, χ, do_xtmerge, δj = check_alignment(Ti, Tj, Xi, Xj, Δ)
          if do_xtmerge
            xtmerge!(τ, χ, div(Δ,2))
          end
          if δj != 0
            xsi_i += δj
            xei_j -= δj
          end

          # (3) Merge X,T into S[q]
          deleteat!(Xq, xsi_j:xei_j)
          if xsi_j == 1
            prepend!(Xq, χ)
          else
            splice!(Xq, xsi_j:xsi_j-1, χ)
          end

          # (4) Adjust start, end indices of windows ≥ q_i in q
          # structure: w_start, w_end, channel_number, window_number, x_start, x_end
          nxq = length(Xq) - lxq
          i = 0
          while i < nW
            i += 1
            if W[i, 3] == q && W[i, 4] ≥ q_i
              W[i, 1] += nxq*Δ
              W[i, 2] += nxq*Δ
              W[i, 5] += nxq
              W[i, 6] += nxq
            end
          end

          #= if xsi_i ≤ os_p (which is always true, at this point in
          the control flow), we decrease W[W_p, 1:2] =#
          nxp = xei_i-xsi_i+1
          W[W_p, 1] -= δj*Δ
          W[W_p, 2] -= (nxp + δj)*Δ

          #= Control for when window P is emptied; the above two statements
          make this possible =#
          if (W[W_p, 2] < W[W_p, 1])
            W = W[setdiff(1:end, W_p), :]
          else
            W[W_p, 6] -= nxp
          end
        end
        # Sort by end time, to ensure we pick the window with latest end next
        k = sortperm(W[:,2], rev=true)
        W = W[k,:]
        nW = size(W,1)
        (src, dest) = get_next_pair(W)
      end
      # Repeat until no further merges are possible
      kk = sortperm(W[:,1])
      W = W[kk,:]

      #= At this point, we have nothing left that can be merged. So we're going
      to arrange T[subgrp] and X[subgrp] in windows using t_win =#

      n = size(W, 1)
      nx = broadcast(+, getindex(W, :, 6).-getindex(W, :,5), 1)
      X_Ω = Array{eltype(X[Ω]),1}(undef, sum(nx))
      xi = 1
      i = 0
      while i < n
        i   = i + 1
        p   = getindex(W, i, 3)
        lx  = getindex(nx, i)
        copyto!(X_Ω, xi, getindex(X, p), getindex(W, i, 5), lx)
        xi  = xi + lx
      end

      # Shrink W and eliminate windows with no actual gap between them
      m = trues(n)
      while n > 1
        if W[n-1, 2] + Δ == W[n,1]
          W[n-1, 2] = W[n,2]
          m[n] = false
        end
        n = n - 1
      end
      W = W[m, [1,2]]
      setindex!(T, w_time(W, Δ), Ω)
      setindex!(X, X_Ω, Ω)
      note!(S, Ω, string("merge!, combined channels ",
                          replace(repr(subgrp), ","=>""),
                          " (N = ", N, ") into :t, :x"))
      append!(to_delete, rest)
    end
    # Done with SUBGRPS
  end
  if N_warn > 0
    @info(string("Total warnings: ", N_warn))
  end
  deleteat!(S, to_delete)
  sort!(S)
  return nothing
end

# The following must be the same (or unset) to merge:
# :loc
# :resp
# :fs         cannot be unset; not a nullable array
# :units

# The following are easily dealt with:
# :gain       can be translated with no trouble
# :misc       can call merge! method for dictionaries
# :notes      append and sort
# :name       not important, can log extra names to :notes
# :src        use most recent, log extras to :notes
