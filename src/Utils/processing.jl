using SeisIO

function autotuk!(x, v, u)
  g = find(diff(v) .> 1)
  L = length(g)
  if L > 0
    w = Array{Int64,2}(0,2)
    v[g[1]] > 1 && (w = cat(1, w, [1 v[g[1]]]))
    v[g[L]] < length(x) && (w = cat(1, w, [v[g[L]+1] length(x)]))
    L > 1 && ([w = cat(1, w, [v[g[i]+1] v[g[i+1]]]) for i = 1:L-1])
    for i = 1:size(w,1)
      (j,k) = w[i,:]
      if (k-j) >= u
        N = round(Int, k-j)
        x[j+1:k] .*= tukey(N, u/N)
      else
        warn(string(@sprintf("Channel %i: Time window too small, ",i),
          @sprintf("x[%i:%i]; replaced with zeros.", j+1, k)))
        x[j+1:k] = 0
      end
    end
  end
  return x
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

  # Then check for auto-fill values (i.e. values that don't change) and NaNs
  # autotuk!(U.x, find(diff(U.x).!=0), u)
  # Removed; leaving this would be a mistake

  # Then check for NaNs
  autotuk!(U.x, find(!isnan(U.x)), u)

  # Then replace NaNs with zeros
  U.x[find(isnan(U.x))] = 0

  # And note it
  note(U, "De-meaned, auto-tapered, and ungapped data; replaced all NaNs with zeros.")
  return U
end

function autotap!(U::SeisData)
  # Fill gaps with NaNs
  ungap!(U, m=false, w=false)

  for i = 1:U.n
    (U.fs[i] == 0 || isempty(U.x[i])) && continue
    j = find(!isnan(U.x[i]))
    mx = mean(U.x[i][j])
    U.x[i][j] .-= mx

    u = round(Int, max(20,0.2*U.fs[i]))

    # Check for NaNs and window around them
    autotuk!(U.x[i], find(!isnan(U.x[i])), u)

    # Replace NaNs with zeros
    U.x[i][find(isnan(U.x[i]))] = 0
    note(U, i, "De-meaned, auto-tapered, and ungapped data; replaced all NaNs with zeros.")
  end
  return U
end
