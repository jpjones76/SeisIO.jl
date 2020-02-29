#=
Purpose: time utilities that depend on custom Types go here

Difference from CoreUtils/time.jl functions here require SeisIO Types to work
=#
function mk_t!(C::GphysChannel, nx::Integer, ts_new::Int64)
  T = Array{Int64, 2}(undef, 2, 2)
  setindex!(T, one(Int64), 1)
  setindex!(T, nx, 2)
  setindex!(T, ts_new, 3)
  setindex!(T, zero(Int64), 4)
  setfield!(C, :t, T)
  return nothing
end

function check_for_gap!(S::GphysData, i::Integer, ts_new::Int64, nx::Integer, v::Integer)
  Δ = round(Int64, sμ / getindex(getfield(S, :fs), i))
  T = getindex(getfield(S, :t), i)
  nt = size(T, 1)
  lxi = T[nt, 1]
  te_old = endtime(T, Δ)
  δt = ts_new - te_old - Δ
  if abs(δt) > div(Δ, 2)
    v > 1 && println(stdout, S.id[i], ": gap = ", δt, " μs (old end = ",
    te_old, ", New start = ", ts_new)
    setindex!(T, getindex(T, nt) + 1, nt)
    setindex!(T, getindex(T, 2*nt) + δt, 2*nt)
    setindex!(getfield(S, :t), vcat(T, [lxi + nx zero(Int64)]), i)
  else
    setindex!(T, lxi + nx, nt)
  end
  return nothing
end
