export ungap, ungap!

@doc """
    ungap!(S[, chans=CC, m=true, tap=false])
    ungap(S[, chans=CC, m=true, tap=false])

Fill time gaps in each channel of S with the mean of the channel data.

    ungap!(C[, m=true, tap=false])
    ungap(C[, m=true, tap=false])

As above for GphysChannel object C.

### Keywords
* `chans=CC`: only ungap channels `CC`.
* `m=false`: this flag fills gaps with NaNs instead of the mean.
* `tap=true`: taper data before filling gaps.

!!! warning

    If channel segments aren't in chronological order, call `merge` before using `ungap`.
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

@doc(@doc ungap!)
function ungap!(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  m::Bool=true,
  tap::Bool=false)

  if chans == Int64[]
    chans = 1:S.n
  end

  if tap
    taper!(S, chans=chans)
  end

  for i = 1:S.n
    if i in chans
      N = size(S.t[i],1)-2
      (N ≤ 0 || S.fs[i] == 0) && continue
      gapfill!(S.x[i], S.t[i], S.fs[i], m=m)
      note!(S, i, @sprintf("%s filled %i gaps (sum = %i μs)",
                            string("ungap!, m = ", m, ", tap = ", tap, ","),
                            N, sum(S.t[i][2:end-1, 2])))
      S.t[i] = [S.t[i][1:1,:]; [length(S.x[i]) 0]]
    end
  end
  return nothing
end

@doc (@doc ungap!)
ungap(S::GphysChannel; m::Bool=true, tap::Bool=false) = (T = deepcopy(S); ungap!(T, m=m, tap=tap); return T)

@doc(@doc ungap!)
ungap(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[],
  m::Bool=true,
  tap::Bool=false) = (T = deepcopy(S); ungap!(T, chans=chans, m=m, tap=tap); return T)
