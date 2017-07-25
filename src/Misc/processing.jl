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
    demean!(S::SeisData)

Remove the mean from all channels `i` with `S.fs[i] > 0.0`. Specify `all=true`
to also remove the mean from irregularly sampled channels (with S.fs[i] == 0.0)

"""
function demean!(S::SeisData; all::Bool=false)
  @inbounds for i = 1:S.n
    (all==false && S.fs[i]<=0.0) && continue
    K = find(isnan(S.x[i]))
    if isempty(K)
      L = length(S.x[i])
      μ = sum(S.x[i])/Float64(L)
      for j = 1:L
        S.x[i][j] -= μ
      end
    else
      J = find(!isnan(S.x[i]))
      L = length(J)
      μ = sum(S.x[i][J])/Float64(L)
      for j in J
        S.x[i][j] -= μ
      end
    end
  end
  return nothing
end

"""
    unscale!(S::SeisData)

Divide out the gains of all channels `i` : `S.fs[i] > 0.0`. Specify `all=true`
to also remove the gain of irregularly-sampled channels (i.e., channels `i` : `S.fs[i] == 0.0`)

"""
function unscale!(S::SeisData; all::Bool=false)
  for i = 1:S.n
    (all==false && S.fs[i]<=0.0) && continue
    if S.gain[i] != 1.0
      scale!(S.x[i], 1.0/S.gain[i])
      note!(S, string(S.id[i], " removed gain =", S.gain[i]))
      S.gain[i] = 1.0
    end
  end
  return nothing
end

"""
    namestrip!(s::String)

Remove bad characters from S: \,, \\, !, \@, \#, \$, \%, \^, \&, \*, \(, \),
  \+, \/, \~, \`, \:, \|, and whitespace.
"""
namestrip!(S::String) = (strip(S, ['\,', '\\', '!', '\@', '\#', '\$',
  '\%', '\^', '\&', '\*', '\(', '\)', '\+', '\/', '\~', '\`', '\:', '\|', ' ']); return S)
namestrip!(S::Array{String,1}) = [namestrip!(i) for i in S]
namestrip!(S::SeisData) = [namestrip!(i) for i in S.name]

"""
    autotap!(S::SeisData)

Data in `S.x` are cosine tapered around time gaps in `S.t`, then gaps are filled with zeros.

"""
function autotap!(U::SeisData)
  # Fill gaps with NaNs
  ungap!(U, m=false, w=false)

  for i = 1:U.n
    (U.fs[i] == 0 || isempty(U.x[i])) && continue
    j = find((isnan.(U.x[i])).==false)
    μ = mean(U.x[i][j])
    u = max(20, round(Int64, 0.2*U.fs[i]))

    # Check for NaNs and window around them
    autotuk!(U.x[i], j, u)

    # Then replace NaNs with the mean
    U.x[i][isnan.(U.x[i])] = μ
    note!(U, i, "+p: tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
  end
  return nothing
end

"""
    !autotap(U)

Automatically cosine taper (Tukey window) all data in U
"""
function autotap!(U::SeisChannel)
  (U.fs == 0 || isempty(U.x)) && return

  # Fill time gaps with NaNs
  ungap!(U, m=false, w=false)

  j = find(!isnan(U.x))
  μ = mean(U.x[j])
  u = max(20, round(Int64, 0.2*U.fs))

  # Then check for NaNs
  autotuk!(U.x, j, u)

  # Then replace NaNs with the mean
  U.x[isnan(U.x)] = μ
  note!(U, "+p: tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
  return nothing
end
