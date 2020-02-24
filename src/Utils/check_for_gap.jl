# check for gaps in channel i of struct S
"""
    check_for_gap!(S::GphysData, i::Integer, t0::Int64, nx::Integer, v::Integer)

Check for gaps between the end of `S.t[i]` and time `t0`. Assumes the data
segment being added is `nx` samples long.

`t_extend` applies the same functionality in a more general sense to a
two-dimensional time matrix `t`.

See Also: t_extend, check_for_resize!
"""
function check_for_gap!(S::GphysData, i::Integer, t0::Int64, nx::Integer, v::Integer)
  Δ = round(Int64, sμ / getindex(getfield(S, :fs), i))
  t = getindex(getfield(S, :t), i)
  nt = size(t,1)
  lxi = t[nt,1]
  te = endtime(t, Δ)
  τ = t0 - te - Δ
  if abs(τ) > div(Δ, 2)
    v > 1 && println(stdout, S.id[i], ": gap = ", τ, " μs (old end = ",
    te, ", New start = ", τ + te + Δ)
    setindex!(t, getindex(t, nt)+1, nt)
    setindex!(t, getindex(t, 2*nt)+τ, 2*nt)
    setindex!(getfield(S, :t), vcat(t, [lxi+nx zero(Int64)]), i)
  else
    setindex!(t, lxi+nx, nt)
  end
  return nothing
end
