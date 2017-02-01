
"""
    merge!(S::SeisData)

Merge all channels of S with redundant fields.
"""
function merge!(S::SeisData)
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
merge(S::SeisData) = (T = deepcopy(S); merge!(T); return(T))

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

  T = SeisData()
  for i = 1:length(j)
    T += S[j[i]]
  end
  return T
end

"""
    autotap!(S::SeisData)

Data in `S.x` are de-meaned and cosine tapered around time gaps in `S.t`, then gaps are filled with zeros.

"""
function autotap!(U::SeisData)
  # Fill gaps with NaNs
  ungap!(U, m=false, w=false)

  for i = 1:U.n
    (U.fs[i] == 0 || isempty(U.x[i])) && continue
    j = find(!isnan(U.x[i]))
    mx = mean(U.x[i][j])
    U.x[i][j] .-= mx

    u = max(20, round(Int, 0.2*U.fs[i]))

    # Check for NaNs and window around them
    autotuk!(U.x[i], find(!isnan(U.x[i])), u)

    # Replace NaNs with zeros
    U.x[i][find(isnan(U.x[i]))] = 0.0
    note!(U, i, "De-meaned, auto-tapered, and ungapped data; replaced all NaNs with zeros.")
  end
  return U
end

"""
    equalize_resp!(S::SeisData, resp_new::Array{Complex{T},2})

Translate all data in S.x to instrument response resp_new. zeros are in resp[:,1], poles in resp[:,2]. If channel `i` has key `S.misc[i]["hc"]`, this is used as the critical damping constant, else a value of 1.0 is assumed.
"""
function equalize_resp!{T}(S::SeisData, resp_new::Array{Complex{T},2})
  pp = 2.0*Float64(pi)
  for i = 1:1:S.n
    if haskey(S.misc[i],"hc")
      h = S.misc[i]["hc"]
    else
      h = 1.0
    end
    X = S.x[i]
    Nx = length(X)
    N2 = nextpow2(Nx)
    fs = S.fs[i]
    f = [collect(0:N2/2); collect(-N2/2+1:-1)]*fs/N2

    # Old instrument response
    F0 = resp_f(S.resp[i], S.gain[i], h, f, fs) #hc_old*freqs(mkresp(S.resp[i], S.gain[i]), f, fs)

    # New instrument response
    F1 = resp_f(resp_new, 1.0, 1.0/sqrt(2), f, fs)

    # FFT
    xf = fft([X; zeros(T, N2-Nx)])
    rf = F1.*conj(F0)./(F0.*conj(F0).+eps())

    # Changes: x, resp, gain, misc["normfac"]
    S.x[i] = real(ifft(xf.*rf))[1:Nx]
    S.resp[i] = resp_new
    S.gain[i] = 1.0
    S.misc[i]["hc"] = 1.0
  end
  return S
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
  mx = mean(U.x[j])
  u = round(Int, max(20,0.2*U.fs))

  # remove mean
  U.x[j] .-= mx

  # Then check for NaNs
  autotuk!(U.x, find(!isnan(U.x)), u)

  # Then replace NaNs with zeros
  U.x[find(isnan(U.x))] = 0

  # And note it
  note!(U, "De-meaned, auto-tapered, and ungapped data; replaced all NaNs with zeros.")
  return U
end
