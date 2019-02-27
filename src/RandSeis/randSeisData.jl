export randSeisData

# Populate a SeisData structure with random channels
"""
    randSeisData([, c=0.2, s=0.6])

Generate 8 to 24 channels of random seismic data as a SeisData object.
* 100*c is the percentage of channels _after the first_ with irregularly-sampled data (fs = 0.0)
* 100*s is the percentage of channels _after the first_ with guaranteed seismic data.

    randSeisData(N[, c=0.2, s=0.6])

Generate N channels of random seismic data as a SeisData object.
"""
function randSeisData(N::Int; c=0.2::Float64, s=0.6::Float64)
  S = SeisData(N)
  n_seis = max(min(ceil(Int, s*S.n), S.n-1),0)
  n_irr = max(min(floor(Int, c*S.n), S.n-n_seis-1),0)
  data_spec = zeros(UInt8, S.n)
  data_spec[1:n_seis] .= 0x01
  data_spec[n_seis+1:n_seis+n_irr] .= 0x02
  data_spec = shuffle!(data_spec)
  for i = 1:S.n
    if data_spec[i] == 0x01
      S[i] = randSeisChannel(s=true)
    elseif data_spec[i] == 0x02
      S[i] = randSeisChannel(c=true)
    else
      S[i] = randSeisChannel()
    end
  end
  return S
end
randSeisData(; c=0.2::Float64, s=0.6::Float64) = randSeisData(rand(8:24), c=c, s=s)
