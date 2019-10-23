function get_trace_bounds(ts::Int64, te::Int64, t0::Int64, t1::Int64, Δ::Int64, nx::Int64)
  i0 = 1
  i1 = nx
  while t0 < ts
    if i0 >= i1
      break
    end
    t0 += Δ
    i0 += 1
  end

  while t1 > te
    if i1 <= i0
      break
    end
    t1 -= Δ
    i1 -= 1
  end

  return i0, i1, t0
end
