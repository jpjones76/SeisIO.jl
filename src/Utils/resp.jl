# TO DO: accelerometer equation, unit-dependent conversion to pz format
"""
    resp = fctopz(fc)

Convert critical frequency fc to a matrix of complex poles and zeros. zeros are
in resp[:,1], poles in resp[:,2].
"""
function fctopz(fc; hc=1/sqrt(2)::Real, units="m/s"::String)
  if units == "m/s"
    cp = complex(zeros(2))
    cz = [(-hc + sqrt(complex(hc^2-1)))*2*pi*fc, (-hc - sqrt(complex(hc^2-1)))*2*pi*fc]
    return [cp cz]
  else
    error("NYI")
  end
end
