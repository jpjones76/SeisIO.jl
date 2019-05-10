export ungap, ungap!

@doc """
    ungap!(S[, m=true])

Fill time gaps in S with the mean of data in S. If S is a SeisData structure,
time gaps in channel [i] are filled with the mean value of each channel's data.

If m=false, gaps are filled with NANs.
""" ungap!
function ungap!(C::GphysChannel; m::Bool=true, tap::Bool=false)
  if tap
    taper!(C)
  end
  N = size(C.t,1)-2
  (N ≤ 0 || C.fs == 0) && return nothing
  gapfill!(C.x, C.t, C.fs, m=m)
  note!(C, @sprintf("%s filled %i gaps (sum = %i μs)",
                    string("ungap!, m = ", m, ", tap = ", tap, ","),
                    N, sum(C.t[2:end-1, 2])))
  C.t = [C.t[1:1,:]; [length(C.x) 0]]
  return nothing
end

function ungap!(S::GphysData; m::Bool=true, tap::Bool=false)
  if tap
    taper!(S)
  end
  for i = 1:S.n
    N = size(S.t[i],1)-2
    (N ≤ 0 || S.fs[i] == 0) && continue
    gapfill!(S.x[i], S.t[i], S.fs[i], m=m)
    note!(S, i, @sprintf("%s filled %i gaps (sum = %i μs)",
                          string("ungap!, m = ", m, ", tap = ", tap, ","),
                          N, sum(S.t[i][2:end-1, 2])))
    S.t[i] = [S.t[i][1:1,:]; [length(S.x[i]) 0]]
  end
  return nothing
end

@doc (@doc ungap!)
ungap(S::Union{GphysData,GphysChannel}; m::Bool=true, tap::Bool=false) = (T = deepcopy(S); ungap!(T, m=m, tap=tap); return T)
ungap!(Ev::SeisEvent; m::Bool=true, tap::Bool=false) = (S = deepcopy(Ev.data); ungap!(S, m=m, tap=tap); Ev.data = deepcopy(S); return nothing)
ungap(Ev::SeisEvent; m::Bool=true, tap::Bool=false) = (S = deepcopy(Ev.data); ungap!(S, m=m, tap=tap); return SeisEvent(hdr=deepcopy(Ev.hdr), data=S))
