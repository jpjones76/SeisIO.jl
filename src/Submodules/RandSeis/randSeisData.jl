# Populate a SeisData structure with random channels
"""
    randSeisData()

Generate 8 to 24 channels of random seismic data as a SeisData object.

    randSeisData(N)

Generate `N` channels of random seismic data as a SeisData object.

### Keywords
| KW      | Default | Type      | Meaning                                 |
|-------- |:--------|:----------|:-------------------------------         |
| s       | 0.6     | Float64   | chance each channel is seismic data     |
| c       | 0.2     | Float64   | chance each channel is irregular (fs=0) |
| nx      | 0       | Int64     | number of samples in each channel       |
| fs_min  | 0.0     | Float64   | regular channels have fs ≥ fs_min       |
| a0      | false   | Bool      | recalculate :resp constants?            |

### Behavior
* If `nx` ≤ 0, the number of samples is determined randomly for each channel
* `100*s` is the minimum percentage of channels with guaranteed seismic data
* `100*c` is the maximum percentage of channels with irregularly-sampled data
* `s` takes precedence over `c`; they are not renormalized. Thus, for example:
  + `randSeisData(12, c=1.0, s=1.0)` works like `randSeisData(12, c=0.0, s=1.0)`
  + `randSeisData(c=1.0)` works like `randSeisData(s=0.0)`
* For `N` channels, `s*N` is rounded up; `c*N` is rounded down. Thus:
  + `randSeisData(10, c=0.28)` and `randSeisData(10, c=0.2)` are equivalent
  + `randSeisData(10, s=0.28)` and `randSeisData(10, s=0.3)` are equivalent
* By default, `:resp.a0 = 1.0` for all channels; `a0=true` calls `resp_a0!(S)`
  + `:resp.p` and `:resp.z` are random; `a0=true` isn't guaranteed to work

See also: `randSeisChannel`, `resp_a0!`
"""
function randSeisData(N::Int64; c::Float64=0.2, s::Float64=0.6, nx::Integer=0, fs_min::Float64=0.0, a0::Bool=false)
  S = SeisData(N)

  # Evaluate probabilities, with s taking precedence
  if s != 0.6
    c = max(0.0, 1.0-s)
  end
  if c != 0.2
    s = max(0.0, 1.0-c)
  end

  # determine number of channels of each
  n_seis = max(min(ceil(Int, s*S.n), S.n), 0)
  n_irr = max(min(floor(Int, c*S.n), S.n-n_seis), 0)

  # fill in and shuffle data_spec
  data_spec = zeros(UInt8, S.n)
  data_spec[1:n_seis] .= 0x01
  data_spec[n_seis+1:n_seis+n_irr] .= 0x02
  shuffle!(data_spec)

  # populate all channels according to data_spec
  for i = 1:S.n
    if data_spec[i] == 0x01
      S[i] = randSeisChannel(s=true, nx=nx, fs_min=fs_min)
    elseif data_spec[i] == 0x02
      S[i] = randSeisChannel(c=true, nx=nx, fs_min=fs_min)
    else
      S[i] = randSeisChannel(nx=nx, fs_min=fs_min)
    end
  end
  a0 && resp_a0!(S)
  return S
end
randSeisData(; c::Float64=0.2, s::Float64=0.6, nx::Int64=0, fs_min::Float64=0.0, a0::Bool=false) = randSeisData(rand(8:24), c=c, s=s, nx=nx, fs_min=fs_min, a0=a0)
