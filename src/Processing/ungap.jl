export ungap, ungap!

function gapfill!(x::Array{Float64,1}, t::Array{Int64,2}, fs::Float64; m=true::Bool, w=true::Bool)
  (fs == 0.0 || isempty(x)) && (return x)
  mx = m ? mean(x[isnan.(x).==false]) : NaN
  u = round(Int64, max(20, 0.2*fs))
  for i = size(t,1):-1:2
    # Gap fill
    g = round(Int64, fs*μs*t[i,2])
    g < 0 && (@warn(string("Negative time gap (i = ", i, ", t = ", Float64(g)/fs, "; skipped.")); continue)
    g == 0 && continue
    j = t[i-1,1]
    k = t[i,1]
    N = k-j
    splice!(x, k:k-1, mx.*ones(g))

    # Window if selected
    if w
      if N >= u
        x[j+1:k] .*= tukey(N, u/N)
      else
        @warn(string("segment ", i, " too short; x[", j+1, ":", k, "] replaced with mean(x)."))
        x[j+1:k] .= mx
      end
    end
  end
  return x
end

gapfill(x::Array{Float64,1}, t::Array{Int64,2}, f::Float64) =
  (y = deepcopy(x); gapfill!(y,t,f); return y)


"""
    ungap!(S[, m=true, w=true])

Fill time gaps in S with the mean of data in S. If S is a SeisData structure,
time gaps in channel [i] are filled with the mean value of each channel's data.

If m=false, gaps are filled with NANs.

If w=true, data points near gaps are cosine tapered.
"""
function ungap!(S::SeisChannel; m=true::Bool, w=true::Bool)
  N = size(S.t,1)-2
  (N ≤ 0 || S.fs == 0) && return nothing
  gapfill!(S.x, S.t, S.fs, m=m, w=w)
  note!(S, @sprintf("ungap! filled %i gaps (sum = %i microseconds)", N, sum(S.t[2:end-1,2])))
  S.t = [S.t[1:1,:]; [length(S.x) 0]]
  return nothing
end

function ungap!(S::SeisData; m=true::Bool, w=true::Bool)
  for i = 1:S.n
    N = size(S.t[i],1)-2
    (N ≤ 0 || S.fs[i] == 0) && continue
    gapfill!(S.x[i], S.t[i], S.fs[i], m=m, w=w)
    note!(S, i, @sprintf("ungap! filled %i gaps (sum = %i microseconds)", N, sum(S.t[i][2:end-1,2])))
    S.t[i] = [S.t[i][1:1,:]; [length(S.x[i]) 0]]
  end
  return nothing
end

ungap(S::Union{SeisData,SeisChannel}; m=true::Bool, w=true::Bool) = (T = deepcopy(S); ungap!(T, m=m, w=w); return T)
ungap!(Ev::SeisEvent) = (S = deepcopy(Ev.data); ungap!(S); Ev.data = deepcopy(S); return nothing)
