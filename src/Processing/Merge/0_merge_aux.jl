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
