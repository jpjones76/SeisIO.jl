function mk_t!(C::GphysChannel, nx::Integer, ts::Int64)
  t = Array{Int64, 2}(undef, 2, 2)
  setindex!(t, one(Int64), 1)
  setindex!(t, nx, 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)
  setfield!(C, :t, t)
  return nothing
end

function mk_t(nx::Integer, ts::Int64)
  t = Array{Int64, 2}(undef, 2, 2)
  setindex!(t, one(Int64), 1)
  setindex!(t, nx, 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)
  return t
end
