export ungap, ungap!

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
