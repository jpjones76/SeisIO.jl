export resptofc

"""
    resptofc(R::Union{PZResp, PZResp64}))

Attempt to guess critical frequency of seismic instrument response R.
Assumes broadband sensors behave roughly like geophones (i.e., as harmonic
oscillators with a single lower corner frequency) at low frequencies.

### See Also
fctoresp, PZResp
"""

function resptofc(R::Union{PZResp, PZResp64})
  T = typeof(R.c)
  P = R.p
  i = argmin(abs.([real(P[j])-imag(P[j]) for j = 1:length(P)]))
  return T(rationalize(abs(P[i]) / 2pi, tol=eps(Float32)))
end
