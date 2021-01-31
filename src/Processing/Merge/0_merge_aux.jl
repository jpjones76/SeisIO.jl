merge_ext!(S::SeisData, Ω::Int64, rest::Array{Int64, 1}) = nothing

function merge_ext!(C::T1, D::T2) where {T1<:GphysChannel, T2<:GphysChannel}
  if T1 == T2
    ff = setdiff(fieldnames(T1), SeisIO.datafields)
    for f in ff
      setfield!(C, f, deepcopy(getfield(D, f)))
    end
  end
  return nothing
end

function dup_check!(subgrp::Array{Int64, 1}, to_delete::Array{Int64, 1}, T::Array{Array{Int64, 2}, 1}, X::Array{FloatArray, 1})
  N = length(subgrp)
  if N > 1
    # Check for duplicates
    sort!(subgrp)
    u = falses(N)
    while N > 1
      t1 = getindex(T, getindex(subgrp, N))
      x1 = getindex(X, getindex(subgrp, N))

      # if a channel is already known to be a duplicate, skip it
      if getindex(u, N) == false
        j = N
        while j > 1
          j = j-1
          t2 = getindex(T, getindex(subgrp, j))
          x2 = getindex(X, getindex(subgrp, j))
          if t1 == t2 && x1 == x2
            setindex!(u, true, j)
          end
        end
      end

      N = N-1
    end

    # flag duplicates for deletion
    for i in 1:length(u)
      if u[i]
        push!(to_delete, subgrp[i])
      end
    end

    # remove duplicates from merge targets
    deleteat!(subgrp, u)
  end
  return length(subgrp)
end

function get_δt(t::Int64, Δ::Int64)
  δts = rem(t, Δ)
  if δts > div(Δ,2)
    δts -= Δ
  end
  return δts
end

function check_alignment(Ti::Array{Int64,1}, Tj::Array{Int64,1}, Xi::Array{T,1}, Xj::Array{T,1}, Δ::Int64) where {T<:AbstractFloat}
  z = zero(Int64)

  # Rare case, but possible: they're the same data
  if first(Ti) == first(Tj) && last(Ti) == last(Tj) && Xi == Xj
    return Ti, Xi, false, z
  else

    # Find a time correction δt that gets applied to Ti, ts[i], te[i], etc.
    # Find overlapping region, if one exists
    L = length(Ti)
    for n = 1:4
      if n > L-1
        break
      end

      xi_f = view(Xi, n+1:L)
      xj_f = view(Xj, 1:L-n)
      if isapprox(xi_f, xj_f)
        return Tj[1:L-n], xj_f, false, 1*n
      end

      xi_b = view(Xi, 1:L-n)
      xj_b = view(Xj, n+1:L)
      if isapprox(xi_b, xj_b)
        return Ti[1:L-n], xi_f, false, -1*n
      end
    end
  end
  return vcat(Ti,Tj), vcat(Xi,Xj), true, z
end

function xtmerge!(t::Array{Int64,1}, x::Array{T,1}, d::Int64) where {T<:AbstractFloat}
  # Sanity check
  (length(t) == length(x)) || error(string("Badly set times (Nt=", length(t), ",Nx=", length(x), "); can't merge!"))

  # Sort
  i = sortperm(t)
  sort!(t)
  x[:] = x[i]

  # Check for duplicates
  J0 = findall((diff(t).==0).*(diff(x).==0))
  while !isempty(J0)
    deleteat!(x, J0)
    deleteat!(t, J0)
    J0 = findall(diff(t) .== 0)
  end

  J0 = findall(diff(t) .< d)
  while !isempty(J0)
    J1 = J0.+1
    K = [isnan.(x[J0]) isnan.(x[J1])]

    # Average nearly-overlapping x that are either both NaN or neither Nan
    ii = findall(K[:,1].==K[:,2])
    i0 = J0[ii]
    i1 = J1[ii]
    t[i0] = div.(t[i0].+t[i1], 2)
    x[i0] = 0.5.*(x[i0].+x[i1])

    # Delete nearly-overlapping x with only one NaN (and delete all x ∈ i1)
    i3 = findall(K[:,1].*(K[:,2].==false))
    i4 = findall((K[:,1].==false).*K[:,2])
    II = sort([J0[i4]; J1[i3]; i1])
    deleteat!(t, II)
    deleteat!(x, II)

    J0 = findall(diff(t) .< d)
  end
  return nothing
end


# get hash of each non-empty loc, resp, units, fs ( fs should never be empty )
function get_subgroups( LOC   ::Array{InstrumentPosition,1},
                        FS    ::Array{Float64,1},
                        RESP  ::Array{InstrumentResponse,1},
                        UNITS ::Array{String,1},
                        group ::Array{Int64,1} )
  zh = zero(UInt64)
  N_grp = length(group)
  N_grp == 1 && return([group])

  H = Array{UInt,2}(undef, N_grp, 4)
  for (n,g) in enumerate(group)
    H[n,1] = hash(getindex(FS, g))
    H[n,2] = isempty(getindex(LOC, g)) ? zh : hash(getindex(LOC, g))
    H[n,3] = isempty(getindex(RESP, g)) ? zh : hash(getindex(RESP, g))
    H[n,4] = isempty(getindex(UNITS, g)) ? zh : hash(getindex(UNITS, g))
  end

  # If an entire column is unset, we don't care
  H = H[:, findall([sum(H[:,i])>0 for i in 1:4])]
  (Nh,Nc) = size(H)

  # Find unique rows of H; sort
  H_filled = sum(H .!= zh, dims=2)[:]
  H_inds = sortperm(H_filled, rev=true)
  N_subgrp = length(H_inds)
  N_subgrp == 1 && return([group])

  subgrp_inds = Array{Array{Int64,1},1}(undef, N_subgrp)

  H = H[H_inds, :]
  group = group[H_inds]
  H_sub = deepcopy(H)

  for i = 1:N_subgrp
    subgrp_inds[i] = Array{Int64,1}(undef, 0)
    subgrp_hash = H_sub[i, :]
    for j = N_grp:-1:1
      m = prod([H[j,k] in (zh, subgrp_hash[k]) for k=1:Nc])
      if m
        push!(subgrp_inds[i], group[j])
        deleteat!(group, j)
        H = H[setdiff(1:end, j), :]
      end
      N_grp = length(group)
    end
    if N_grp == 0
      subgrp_inds = subgrp_inds[1:i]
      N_subgrp = length(subgrp_inds)
      break
    end
  end
  deleteat!(subgrp_inds, [isempty(subgrp_inds[j]) for j=1:length(subgrp_inds)])
  return subgrp_inds
end

function get_next_pair(W::Array{Int64,2})
  L = size(W,1)
  i = 1

  # dest loop
  while i < L
    si = getindex(W, i)
    ei = getindex(W, i + L)
    j = i + 1

    # src loop
    while j ≤ L
      sj = getindex(W, j)
      ej = getindex(W, j+L)
      if min(si ≤ ej, ei ≥ sj) == true
        # src    # dest
        return vcat(W[j,:], j), vcat(W[i,:], i)
      end
      j = j + 1
    end
    i = i + 1
  end
  return zeros(Int64, 7), zeros(Int64, 7)
end

function get_merge_w(Δ::Int64, subgrp::Array{Int64,1}, T::Array{Array{Int64, 2}, 1}, X::Array{FloatArray, 1})

  N = length(subgrp)
  w_tmp = Array{Array{Int64,2}, 1}(undef, N)
  te    = Array{Int64, 1}(undef, N)
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

  #= added 2019-11-19:
  fixes a rare off-by-one bug with slightly-offset windows (issue #29)
  issue creator only sees bug in one file from 20 years of data

  clumsy fix based on sound principles:
  * force X to start an integer # of samples from the epoch
    - prevents a discrepancy between length(X) and length(T)
  * add the offset back to the start time of the merged channel data
  =#

  # Let Ω be the channel number in subgrp with the last end time
  Ω = subgrp[argmax(te)]

  return W, Ω
end

function segment_merge(Δ::Int64, Ω::Int64, W::Array{Int64, 2}, X::Array{FloatArray, 1})
  nW = size(W,1)
  i = argmin(W[:,1])
  δts = get_δt(W[i,1], Δ)
  if δts != 0
    for i in 1:size(W,1)
      W[i,1] -= δts
      W[i,2] -= δts
    end
  end
  (src, dest) = get_next_pair(W)

  while (src, dest) != (zeros(Int64, 7), zeros(Int64, 7))
    ts_i = src[1];  te_i = src[2];  p = src[3];  p_i = src[4];  os_p = src[5];  W_p = src[7]
    ts_j = dest[1]; te_j = dest[2]; q = dest[3]; q_i = dest[4]; os_q = dest[5]; W_q = dest[7]
    ts_max = max(ts_i, ts_j); ts_max -= get_δt(ts_max, Δ)
    te_min = min(te_i, te_j); te_min -= get_δt(te_min, Δ)
    nov = 1 + div(te_min - ts_max, Δ)
    Xq = getindex(X, q)

    # (1) determine the times and indices of overlap within each pair
    # a. determine sample times of overlap
    Ti = collect(ts_max:Δ:te_min)
    Tj = deepcopy(Ti)

    # b. get sample indices within each overlap window
    # i
    xsi_i = round(Int64, (ts_max - ts_i)/Δ) + os_p
    xei_i = xsi_i + nov - 1
    # j
    xsi_j = round(Int64, (ts_max - ts_j)/Δ) + os_q
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
    k = sortperm(W[:, 2], rev=true)
    W = W[k, :]
    nW = size(W, 1)

    # Repeat until no further merges are possible
    (src, dest) = get_next_pair(W)
  end

  kk = sortperm(W[:, 1])
  W = W[kk, :]
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
  W = W[m,[1,2]]
  broadcast!(+, W, W, δts)
  T_Ω = w_time(W, Δ)
  return T_Ω, X_Ω
end

# merges into the channel with the most recent data
function merge_non_ts!(S::GphysData, subgrp::Array{Int64,1})
  te = [maximum(t[:,2]) for t in S.t[subgrp]]
  Ω = subgrp[argmax(te)]
  T = vcat(S.t[subgrp]...)[:,2]
  X = vcat(S.x[subgrp]...)
  Z = unique(collect(zip(T,X)))
  T = first.(Z)
  X = last.(Z)
  ii = sortperm(T)
  S.t[Ω] = hcat(collect(1:1:length(T)), T[ii])
  S.x[Ω] = X[ii]
  return Ω
end

function merge_non_ts!(C::GphysChannel, D::GphysChannel)
  T = vcat(C.t, D.t)[:, 2]
  X = vcat(C.x, D.x)
  Z = unique(collect(zip(T,X)))
  T = first.(Z)
  X = last.(Z)
  ii = sortperm(T)
  C.t = hcat(collect(1:length(T)), T[ii])
  C.x = X[ii]
  return nothing
end
