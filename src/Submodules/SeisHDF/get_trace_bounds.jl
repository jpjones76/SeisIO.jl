function get_trace_bounds(ts::Int64, te::Int64, t0::Int64, t1::Int64, Δ::Int64, i1::Int64)
  i0 = 1
  while i0 < i1
    if t0 >= ts
      break
    end
    t0 += Δ
    i0 += 1
  end

  while i1 > i0
    if t1 <= te
      break
    end
    t1 -= Δ
    i1 -= 1
  end

  return i0, i1, t0
end
