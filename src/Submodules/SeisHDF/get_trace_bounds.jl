function get_trace_bounds(ts::Int64, te::Int64, t0::Int64, t1::Int64, Δ::Int64, nx::Int64)
  i0 = 1
  i1 = nx
  while t0 < ts
    (i0 >= i1) && break
    t0 += Δ
    i0 += 1
  end

  while t1 > te
    (i1 <= i0) && break
    t1 -= Δ
    i1 -= 1
  end

  return i0, i1, t0
end

function get_trace_bound(t0::Int64, ts::Int64, Δ::Int64, nx::Int64)
  i0 = 1
  while ts < t0
    (i0 >= nx) && break
    ts  += Δ
    i0 += 1
  end

  return i0
end
