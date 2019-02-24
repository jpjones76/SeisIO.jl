export lcfs

"""
    f = lcfs(fs::Array{Float64,1})

Find *L*owest *C*ommon *fs*, the lowest fs at which data sampled at each frequency in `fs` can be upsampled by repeating an integer number of copies of each data point.

For ridiculous or arbitrary combinations of sampling rates, e.g. `lcfs([62.5, 48.3, 3.0])`, you should really just use `DSP.resample` to approximate.
"""
function lcfs(F::Array{Float64,1})
  fs = unique(filter(i -> i>0.0, F))
  x = zero(Int64)
  n = length(fs)

  # This is generally easy if we have integer sampling frequencies
  int_fs = true
  j = 0
  for i = 1:n
    if !isapprox(fs[i], round(Int, fs[i]))
      int_fs = false
      j = 1
      break
    end
  end
  if int_fs
    return Float64(lcm(map(Int, fs)))
  else
    a = 1
    for i = 1:n
      while !isapprox(fs[i], round(Int, fs[i]))
        r = rationalize(fs[i])
        fs .*= r.den
        a *= r.den
      end
    end
    return lcm(map(Int, fs))/a
  end
end
