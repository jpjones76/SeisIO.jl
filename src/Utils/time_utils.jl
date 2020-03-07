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
  T1 = t_extend(T, ts_new, nx, Δ)
  if T1 != nothing
    if v > 1
      te_old = endtime(T, Δ)
      δt = ts_new - te_old
      (v > 1) && println(stdout, lpad(S.id[i], 15), ": time difference = ", lpad(δt, 16), " μs (old end = ", lpad(te_old, 16), ", new start = ", lpad(ts_new, 16), ", gap = ", lpad(δt-Δ, 16), " μs)")
    end
    S.t[i] = T1
  end
  return nothing
end
