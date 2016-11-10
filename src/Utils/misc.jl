using DSP:tukey, resample

# ============================================================================
# Logging
note(S::SeisChannel, s::AbstractString) = (S.notes = cat(1, S.notes, string(now(), "  ", s)))
note(S::SeisData, i::Integer, s::AbstractString) = push!(S.notes[i], string(now(), "  ", s))
note(S::SeisData, s1::AbstractString, s2::AbstractString) = note(S, findname(s1, S), s2)

# In case all we care about is a header match
"""
    samehdr(S, T)

Test for equality of headers for S, T.
"""
samehdr(S::SeisChannel, T::SeisChannel) = minimum([isequal(hash(getfield(S,v)), hash(getfield(T,v))) for v in headerfields(S)])
samehdr(S::SeisData, T::SeisChannel, i) = minimum([isequal(hash(getfield(S, v)[i]), hash(getfield(T, v))) for v in headerfields(S)])
samehdr(S::SeisChannel, T::SeisData, i) = minimum([isequal(hash(getfield(S, v)[i]), hash(getfield(T, v))) for v in headerfields(S)])

# Extract to SeisChannel
"""
    T = pull(S::SeisData, n::String)

Extract the first channel named `n` from `S` and return it as a SeisChannel structure.

    T = pull(S::SeisData, i::integer)

Extract channel `i` from `S` as a SeisChannel.
"""
pull(S::SeisData, n::String) = (i = findname(n, S); T = getindex(S, i);
  delete!(S,i); note(T, "Extracted from a SeisData object"); return T)
pull(S::SeisData, i::Integer) = (T = getindex(S, i); delete!(S,i);
  note(T, "Extracted from a SeisData object"); return T)

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
    T = chan_sort(S::SeisData)

Sort data in `S` by channel ID, and arrange seismic data in order (Z, {N,1}, {E,2}, ...)

    T = chan_sort(S::SeisData, sort_ord = CS::Array{String,1})

As above, with custom sort order `CS`.

    T = chan_sort(S::SeisData, sort_ord = CS::Array{String,1}, inst_codes = IC::Array{Char,1})

As above for channels with instrument codes in `IC`. The instrument code is the second character of the channel field of each S.id string.

Note that `inst_codes` is a Char array, but `sort_ord` is a String array.

In-place channel sorting is not possible.
"""

function chan_sort(S::SeisData;
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

  T = SeisData()
  for i = 1:length(j)
    T += S[j[i]]
  end
  return T
end
