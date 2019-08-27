# check for gaps in channel i of struct S
function check_for_gap!(S::GphysData, i::Integer, t0::Int64, nx::Integer, v::Int64)
  Δ = round(Int64, sμ / getindex(getfield(S, :fs), i))
  t = getindex(getfield(S, :t), i)
  nt = size(t,1)
  lxi = t[nt,1]
  te = endtime(t, Δ)
  τ = t0 - te - Δ
  if τ > div(Δ, 2)
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
