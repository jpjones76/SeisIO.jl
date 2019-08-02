export fctoresp

"""
    fctoresp(f)
    fctoresp(f, c)

Create PZResp or PZResp64 instrument response from lower corner frequency `f` and damping constant `c`. If no damping constant is supplies, assumes `c = 1/sqrt(2)`.

### See Also
PZResp, PZResp64
"""
function fctoresp(f::AbstractFloat, c::AbstractFloat=1.0f0/sqrt(2.0f0))
  T = typeof(f)
  fxp = T(2.0*pi)*f
  r = sqrt(Complex(c^2 - one(T)))
  z = zeros(Complex{T}, 1)
  p = Complex{T}[r-c, -r-c].*fxp
  if T == Float32
    return PZResp(f0 = Float32(f), p = p, z = z)
  else
    return PZResp64(f0 = Float64(f), p = p, z = z)
  end
end
