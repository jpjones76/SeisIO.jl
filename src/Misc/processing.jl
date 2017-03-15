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
    namestrip!(s::String)

Remove bad characters from S: \,, \\, !, \@, \#, \$, \%, \^, \&, \*, \(, \),
  \+, \/, \~, \`, \:, \|, and whitespace.
"""
namestrip!(S::String) = (strip(S, ['\,', '\\', '!', '\@', '\#', '\$',
  '\%', '\^', '\&', '\*', '\(', '\)', '\+', '\/', '\~', '\`', '\:', '\|', ' ']); return S)
namestrip!(S::Array{String,1}) = [namestrip!(i) for i in S]
namestrip!(S::SeisData) = [namestrip!(i) for i in S.name]

"""
    T = pol_sort(S::SeisData)

Sort data in `S` by channel ID; return a SeisData structure with seismic data channels arranged {Z, {N,1}, {E,2}, ... }.

    T = pol_sort(S::SeisData, sort_ord = CS::Array{String,1})

As above, with custom sort order `CS`.

    T = pol_sort(S::SeisData, sort_ord = CS::Array{String,1}, inst_codes = IC::Array{Char,1})

As above for channels with instrument codes in `IC`. The instrument code is the second character of the channel field of each S.id string.

Note that `inst_codes` is a Char array, but `sort_ord` is a String array.

In-place channel sorting is not possible as pol_sort discards non-seismic data channels.
"""

function pol_sort(S::SeisData;
  sort_ord = ["Z","N","E","0","1","2","3","4","5","6","7","8","9"]::Array{String,1},
  inst_codes = ['G', 'H', 'L', 'M', 'N', 'P']::Array{Char,1})
  id = Array{String,1}(S.n)
  j = Array{Int64,1}(S.n)
  for i = 1:1:S.n
    id[i] = S.id[i][1:end-1]
  end

  ids = sort(unique(id))
  k = 0
  for i in ids
    c = find(ids.==i)
    d = find(id.==i)
    L = length(d)
    if i[end] in inst_codes
      for m in sort_ord
        cc = findfirst(S.id .== i*m)
        if cc > 0
           k += 1; j[k] = cc; deleteat!(d, findfirst(d.==cc))
        end
      end

      # assign other components
      L = length(d)
      if L == 1
        k += 1
        j[k] = d[1]
      elseif L > 0
        j[k+1:k+L] = sortperm(S.id[d])
        k += L
      end
    else
      j[k+1:k+L] = sortperm(S.id[d])
      k += L
    end
  end

  T = SeisData(length(j))
  for i = 1:length(j)
    T[i] = S[j[i]]
  end
  return T
end

"""
    autotap!(S::SeisData)

Data in `S.x` are cosine tapered around time gaps in `S.t`, then gaps are filled with zeros.

"""
function autotap!(U::SeisData)
  # Fill gaps with NaNs
  ungap!(U, m=false, w=false)

  for i = 1:U.n
    (U.fs[i] == 0 || isempty(U.x[i])) && continue
    j = find(!isnan(U.x[i]))
    μ = mean(U.x[i][j])
    u = max(20, round(Int, 0.2*U.fs[i]))

    # Check for NaNs and window around them
    autotuk!(U.x[i], j, u)

    # Then replace NaNs with the mean
    U.x[i][isnan(U.x[i])] = μ
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
  u = max(20, round(Int, 0.2*U.fs))

  # Then check for NaNs
  autotuk!(U.x, j, u)

  # Then replace NaNs with the mean
  U.x[isnan(U.x)] = μ
  note!(U, "+p: tapered and ungapped data; replaced NaNs with mean of non-NaNs.")
  return nothing
end
