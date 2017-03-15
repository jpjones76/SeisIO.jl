"""
    getbandcode(fs, fc=FC)

Get SEED-compliant one-character band code corresponding to instrument sample
rate `fs` and corner frequency `FC`. If unset, `FC` is assumed to be 1 Hz.
"""
function getbandcode(fs::Real; fc = 1::Real)
  fs ≥ 1000 && return fc ≥ 0.1 ? 'G' : 'F'
  fs ≥ 250 && return fc ≥ 0.1 ? 'C' : 'D'
  fs ≥ 80 && return fc ≥ 0.1 ? 'E' : 'H'
  fs ≥ 10 && return fc ≥ 0.1 ? 'S' : 'B'
  fs > 1 && return 'M'
  fs > 0.1 && return 'L'
  fs > 1.0e-2 && return 'V'
  fs > 1.0e-3 && return 'U'
  fs > 1.0e-4 && return 'R'
  fs > 1.0e-5 && return 'P'
  fs > 1.0e-6 && return 'T'
  return 'Q'
end
