import Base:*, merge!, merge

# ============================================================================
# No export
function fastmerge!(X::Array{Array{Float64,1}}, T::Array{Array{Int64,2},1},
  ts::Array{Int64,1}, te::Array{Int64,1}, p::Array{Int64,1}, sμs::Int64,
  flag::BitArray{1}, w::Array{Int64,1}, id::String)
  c = argmax(ts[p])
  ω = p[c]
  for k = 1:length(p)
    k == c && continue
    κ = p[k]
    δs = (ts[κ] - ts[ω])
    δe = (te[κ] - te[ω])

    # Rare case, but possible: they're the same data
    if δs == 0 && δe == 0 && X[κ] == X[ω]
      flag[κ] = false
      empty!(X[κ])
      continue

    end
    m = abs(div(δs, sμs))
    n = abs(div(δe, sμs))

    # indices of overlapping region
    Lω = length(X[ω])-n
    ω0 = 1
    κ0 = m+1
    κ1 = length(X[κ])
    xω = view(X[ω], ω0:Lω)
    xκ = view(X[κ], κ0:κ1)
    if xω != xκ && Lω > 10 && κ1-κ0 > 10
      # try to find a matching segment to align -- faster than correlation
      ff = false
      δt = 1
      lx = length(xω)
      ly = length(xκ)
      while δt < 3
        if isapprox(xω[1:lx-δt], xκ[1+δt:ly])
          δt = -δt
          break
        end
        if isapprox(xω[1+δt:lx], xκ[1:ly-δt])
          break
        end
        if δt == 2
          δt = 0
          break
        end
        δt += 1
      end

      # Adjust all "κ" time vals if δt is non-null
      if δt != 0
        Lω -= δt
        T[κ][1,2] -= δt*sμs
        ts[κ] -= δt*sμs
        te[κ] -= δt*sμs
        ff = true
      end

      # If not flagged, no match was found; average and warn
      if !ff
        X[ω][ω0:Lω] = 0.5*(xω + xκ)
        @warn(stdout, string(id, " (serious): data discrepancy! Two or more ",
              "traces with different data at the same sample time(s)."))
        w[1] += 1
      else
        @warn(stdout, string(id, ": mismatched start times! Trace ", κ,
              " of id ", id, " adjusted ", (δt < 0 ? "+" : "") , -δt*sμs,
              " μs (", (δt < 0 ? "+" : ""), -δt, " sample", (abs(δt) > 1 ? "s" : ""),
              ")"))
        w[1] += 1
      end
    elseif xω != xκ
      @warn(stdout, string(id, " (serious): data discrepancy with X too short to align! Averaging!"))
      X[ω][ω0:Lω] = 0.5*(xω + xκ)
      w[1] += 1
    end
    if δe > 0
      T[κ] = [T[κ][1:1,:]; [κ1 sμs*Lω]; [length(X[κ])-Lω 0]]
    else
      T[κ] = [T[κ][1:1,:]; [length(X[κ])-Lω 0]]
    end
    deleteat!(X[κ], κ0:κ1)
  end
  return nothing
end

function ufar!(X::Array{Array{Float64,1}}, T::Array{Array{Int64,2},1},
  HC::Array{Float64,1}, FS::Array{Float64,1},
  RE::Array{Array{Complex{Float64},2},1}, p::Array{Int64,1}, c::Int64,
  ts::Array{Int64,1}, te::Array{Int64,1})

  sμs = round(Int64, SeisIO.sμ/FS[c])
  for k = 1:length(p)
    κ = p[k]

    # Set S.t[κ][1,2] to integer \# of samples from epoch at reference fs
    δt = round(Int64, rem(ts[k], sμs))
    if δt != 0
      ts[κ] -= δt
      te[κ] -= δt
      T[κ][1,2] -= δt
    end

    # Check: do we resample frequency? Do we translate response?
    f = (FS[κ] == FS[c]) ? false : true
    r = (RE[κ] == RE[c] && HC[κ] == HC[c]) ? false : true
    ((f || r) == true) || continue

    χ = Array{Float64,1}(0)
    ρ = FS[c]/FS[κ]
    L_min = Int64(128)
    J = size(T[κ],1)
    os = 1

    # Resample / translate each segment ----------------------------------
    for j = 1:J
      j == 1 && continue
      si = T[κ][j-1,1]
      if j == J
        os = 0
      end
        x = X[κ][si:max(si, T[κ][j,1]-os)]

      # Ensure segment that we resample has L ≥ L_min (truncate to L below)
      L = length(x)
      if L < L_min
        append!(x, zeros(Float64, L_min-L))
      end
      L = floor(Int64, L*ρ)

      # Resample ---------------------------------------------------------
      if f == true
        x = resample(x, ρ)
        T[κ][j,1] = L + T[κ][j-1,1] - Int64(1)
      end

      # Translate response -----------------------------------------------
      if r == true
        translate_resp!(x, FS[c], RE[κ], RE[c]; hc_old=HC[κ], hc_new=HC[c])
      end

      # Append to χ ------------------------------------------------------
      append!(χ, x[1:L])
    end
    # Done iterating over each segment
    X[κ] = χ
  end
  return nothing
end

function xtmerge!(t::Array{Int64,1}, x::Array{Float64,1}, d::Int64)
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
function merge!(S::SeisData)
  U = unique(S.id)
  A = Array{Array{Int64,1}}([findall(S.id.==i) for i in U])

  # Initialize variables
  L = length(U)
  i = 0
  w = Array{Int64, 1}(undef, 1)
  w[1] = 0
  note_head = string(SeisIO.timestamp(), ": ")
  β = Array{Int64, 1}(undef, 0)

  while true
    (i ≥ length(U)) && break
    i += 1
    id = U[i]
    C = findall(S.id.==id)
    K = length(C)
    (K == 1) && continue

    # Sanity check
    if length(unique(getfield(S, :units)[C])) != 1
      error(string(id, ": data type changes across inputs!"))
    end

    # LOC ====================================================================
    LOC = getfield(S, :loc)[C]  # LOC
    ul = unique(LOC)
    nl = length(ul)
    P = ones(Float64, K)
    if nl > 1
      if nl == 2
        # Check for simple polarity reversals
        if (ul[1][1:4] == ul[2][1:4]) && (mod(ul[1][5],180)==mod(ul[2][5],180))
          println(stdout, string(id, ": polarity reversal; sign of affected data will be flipped."))
          fl = findall([LOC[k]==ul[2] for k=1:K])
          P[fl] = -1.0
        end
      else
        # Generate a new ID by iterating on the location subfield ll
        @warn(string(id, ": LOC changes! Iterating over LOC field; separating by location."))
        w[1] += 1
        (nn,ss,ll,cc) = map(String, split(identity(id), "."))
        lc = Array{String,1}(undef, n-1)
        l0 = (length(ll) == 1) ? UInt8[0x30, UInt8(ll[1])] : ((length(ll) > 1) ? Vector{UInt8}(ll[1:2]) : ones(UInt8,2).*0x30)
        for (j,u) in enumerate(ul)
          # Stupid bug in Julia compiler: for loops that start at j>1 can be compiled as type "Core.Box", which is slow
          j == 1 && continue
          b = true
          lh = findall(LOC.==u)
          testid = join([nn,ss,ll,cc],".")
          while b
            if l0[2] == 0xff
              l0[1] = max(0x30, l0[1]+0x01)
            else
              l0[2] += 1
            end
            test_id = join([nn,ss,String(l0),cc],".")
            b = Base.in(test_id, U)
          end
          push!(U, test_id)
          S.id[C[lh]] = test_id
        end
        L += nl-1
        C = findall(S.id.==id)
        K = length(C)
        P = ones(Float64, K)
      end
    end
    # Below this line, IDs are stable
    # ========================================================================
    FS = getfield(S,:fs)[C]       # FS
    GAIN = getfield(S,:gain)[C]   # GAIN
    RESP = getfield(S, :resp)[C]  # RESP
    T = getfield(S,:t)[C]         # T
    X = getfield(S,:x)[C]         # X

    fs = minimum(FS)
    if fs == 0.0
      if maximum(FS) > 0.0
        error(string(id, ": can't merge timeseries data with irregularly sampled data!"))
      else
        merge_non_ts!(S, C)
      end
      continue
    end

    sμs = round(Int64, SeisIO.sμ/fs)

    # Get start, end times of all traces in C
    HC = ones(Float64, K).*1.0/sqrt(2.0)
    ts = Array{Int64,1}(undef, K)
    te = Array{Int64,1}(undef, K)
    ng = Array{Int64,1}(undef, K)
    groups = falses(K,K)
    flag = trues(K)
    G = Array{Array{Int64,1},1}(undef, 0)
    c = 0
    ω = 0
    @inbounds for k = 1:K
      κ = C[k]
      if haskey(S.misc[κ], "hc")
        HC[k] = S.misc[κ]["hc"]
      end
      ts[k] = S.t[κ][1,2]
      if fs > 0.0
        te[k] = sum(S.t[κ][:,2]) + S.t[κ][end,1]*round(Int64, SeisIO.sμ/S.fs[κ])
        ng[k] = max(0, size(S.t[κ],1)-2)
        for j = 1:k-1
          if min(ts[j]<te[k], te[j]>ts[k]) == true
            groups[j,k] = true
            groups[k,j] = true
          end
        end
      else
        te[k] = maximum(S.t[κ][:,2])
      end
    end

    # Let c be the index in C to the member whose start time is earliest
    # Let ω be the corresponding index in S
    c = argmax(te)
    ω = C[c]

    # NAME ====================================================================
    (length(unique(S.name[C])) == 1) || println(stdout, id, ": name changes across inputs; using most recent.")

    # NOTES =================================================================
    D = C[C.!=ω]
    S.notes[ω] = vcat(S.notes[ω], filter(n -> !occursin("Channel initialized", n), vcat(getfield(S, :notes)[D]...)))

    # MISC ==================================================================
    merge!(S.misc[ω], getfield(S, :misc)[D]...)

    # GAIN, SRC ==============================================================
    g = GAIN[c]
    @inbounds for k = 1:K
      m = P[k] * g / GAIN[k]
      if !isapprox(m, 1.0)
        X[k] .*= m
      end
      if S.src[C[k]] != S.src[ω]
        resize!(S.notes[ω], length(S.notes[ω])+1)
        S.notes[ω][end] = string(note_head, "+src:", S.src[C[k]])
      end
    end

    # T, X, FS, RESP =========================================================
    if length(unique(FS)) != 1
      @warn(string(id, ": non-constant fs among merged traces; resampling to fs = ", fs, " Hz!"))
      w[1] += 1
    end
    if length(unique(RESP)) != 1
      @warn(string(id, ": non-constant resp among merged traces; correcting to p/z of trace ", ω))
      w[1] += 1
    end

    # Convert from BitArray to lists of overlapping traces ___________________
    if maximum(groups) == true
      s = sum(groups, dims=1)[:]            # How many traces group with each k?
      while maximum(s) > 0
        p = findall(s.>0)                   # Indices of non-singleton groups
        q = argmin(s[p])                    # Find smallest non-singleton group
        q = p[q]                            # column of group
        p = findall(groups[:,q])            # rows of other members in group
        p = sort(pushfirst!(p,q))
        if something(findfirst(isequal(p), G), 0) == 0 #findfirst(G, p) == 0
          push!(G, p)
        end
        s[q] = 0
      end
    end

    # Loop over each eligible group to merge them ___________________________
    for k = 1:length(G)
      p = G[k]
      ufar!(X, T, HC, FS, RESP, p, p[argmax(ts[p])], ts, te)
      if maximum(ng[p]) == 0
        fastmerge!(X, T, ts, te, p, sμs, flag, w, id)
      else
        τ = Array{Int64,1}(undef, 0)
        χ = Array{Float64,1}(undef, 0)
        n = argmax(ts[p])
        for q = 1:length(p)
          k = p[q]
          append!(τ, SeisIO.t_expand(T[k], fs))
          append!(χ, X[k])
          if k != n
            flag[k] = false
            empty!(X[k])
          end
        end
        xtmerge!(τ, χ, div(sμs, 2))
        T[p[n]] = SeisIO.t_collapse(τ, fs)
        X[p[n]] = χ
      end
    end

    # Now all that's left are channels that can't merge with each other.
    dels = findall(flag.==false)
    if !isempty(dels)
      deleteat!(ts, dels)
      deleteat!(te, dels)
      deleteat!(T, dels)
      deleteat!(X, dels)
      deleteat!(HC, dels)
      deleteat!(FS, dels)
      deleteat!(RESP, dels)
    end
    if fs > 0.0
      ufar!(X, T, HC, FS, RESP, collect(1:length(X)), argmax(ts), ts, te)
    end

    # We arrange their X values according to end time, from earliest to latest
    p = sortperm(te)
    S.x[ω] = vcat(X[p]...)

    # Then we adjust their times using simple differences. No t_expand.
    n = Int64(0)
    ti = Array{Int64,1}(undef, 0)
    tv = Array{Int64,1}(undef, 0)
    ll = Int64(0)
    for k = 1:length(p)
      κ = p[k]

      # Push start time if k=1 or a gap exists
      if k == 1
        push!(ti, T[κ][1,1]+n)
        push!(tv, T[κ][1,2])
      else
        δt = T[κ][1,2]-tv[1]-sμs*ll
        if δt != 0
          push!(ti, T[κ][1,1]+n)
          push!(tv, δt)
        end
      end

      # All other rows, second column is preserved
      λ = size(T[κ],1)
      if λ > 2
        for ri = 2:(T[κ][λ,2] == 0 ? λ-1 : λ)
          push!(tv, T[κ][ri,2])
          push!(ti, T[κ][ri,1]+n)
        end
      end
      ll = T[κ][λ,1]
      n += ll
    end
    append!(ti, n)
    append!(tv, 0)
    S.t[ω] = hcat(ti, tv)

    # Flag all but ω for delete
    append!(β, D)
  end
  sort!(β)
  deleteat!(S, β)
  if w[1] > 0
    println(stdout, "Total warnings: ", w[1])
  end
  return sort!(S)
end
merge!(S::SeisData, U::SeisData) = ([append!(getfield(S, f), getfield(U, f)) for f in SeisIO.datafields]; S.n += U.n; merge!(S))
merge!(S::SeisData, C::SeisChannel) = merge!(S, SeisData(C))
merge!(C::SeisChannel, D::SeisChannel) = (S = SeisData(C); merge!(S, SeisData(D)); return S[1])
# merge!(C::SeisChannel, S::SeisData) = merge!(SeisData(C), S)

"""
    S = merge(A::Array{SeisData,1})

Merge an array of SeisData objects, creating a single output with the merged
input data.

See also: merge!
"""
function merge(A::Array{SeisIO.SeisData,1})
  L::Int64 = length(A)
  n = sum([A[i].n for i = 1:L])
  T = SeisData(n)
  [setfield!(T, f, vcat([getfield(A[i],f) for i = 1:L]...)) for f in SeisIO.datafields]
  return merge!(T)
end
merge(S::SeisData, U::SeisData) = merge(Array{SeisData,1}([S,U]))
merge(S::SeisData, C::SeisChannel) = merge(S, SeisData(C))
merge(C::SeisChannel, S::SeisData) = merge(SeisData(C),S)
*(S::SeisData, U::SeisData) = merge(Array{SeisData,1}([S,U]))
*(S::SeisData, C::SeisChannel) = merge(S,SeisData(C))
*(C::SeisChannel, D::SeisChannel) = (s1 = deepcopy(C); s2 = deepcopy(D); S = merge(SeisData(s1),SeisData(s2)); return S)

"""
    mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures at once.

See also: merge!
"""
function mseis!(S...)
  U = Union{SeisData,SeisChannel,SeisEvent}
  L = Int64(length(S))
  (L < 2) && return
  (typeof(S[i]) == SeisData) || error("Target must be type SeisData!")
  for i = 2:L
    if !(typeof(S[i]) <: U)
      @warn(string("Object of incompatible type passed to wseis at ",i+1,"; skipped!"))
      continue
    end
    if typeof(S[i]) == SeisData
      append!(S[1], S[i])
    elseif typeof(S[i]) == SeisChannel
      append!(S[1], SeisData(S[i]))
    elseif typeof(S[i]) == SeisEvent
      append!(S[1], S[i].data)
    end
  end
  return merge!(S[1])
end
