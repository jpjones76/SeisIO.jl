export inst_codes, inst_code

@doc """
    inst_codes(S::GphysData)

Get the instrument code of each channel in `S`.

    inst_code(S::GphysData, i::Integer)

Get the instrument code of channel `i`.

inst_code(C::GphysChannel)

Get the instrument code from `C.id`.

Assumes each ID ends with an alphanumeric three-digit channel code and that
ID fields are separated by periods: for example, two channels with IDs
"XX.YYY.00.EHZ" and "_.YHY" each have an instrument code of 'H'.

Channel codes less than two characters long (e.g. "Z" in "AA.BBB.CC.Z") are ignored.

SEED channel codes of seismic and seismoacoustic data (for which operations
like `detrend!` and `taper!` are sane) include D, G, H, J, L, M, N, P, Z.

SEED channel codes of seismometers (for which `translate_resp!` and
`remove_resp!` are sane) are H, J, L, M, N, P, Z.
""" inst_codes
function inst_codes(S::GphysData)
  N = S.n
  codes = Array{Char, 1}(undef, N)
  fill!(codes, '\0')
  @inbounds for i = 1:N
    id = S.id[i]
    L = length(id)
    for j = L:-1:1
      if id[j] == '.'
        j > L-2 && break
        setindex!(codes, id[j+2], i)
        break
      end
    end
  end
  return codes
end

@doc (@doc inst_codes)
function inst_code(S::GphysData, i::Integer)
  N = S.n
  id = S.id[i]
  L = length(id)
  for j = L:-1:1
    if id[j] == '.'
      j > L-2 && break
      return id[j+2]
    end
  end
  return '\0'
end

@doc (@doc inst_codes)
function inst_code(C::GphysChannel)
  L = length(C.id)
  for j = L:-1:1
    if C.id[j] == '.'
      j > L-2 && break
      return C.id[j+2]
    end
  end
  return '\0'
end
