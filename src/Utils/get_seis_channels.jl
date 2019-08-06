export get_seis_channels

"""
    get_seis_channels(S::GphysData)

Get an array with the channel numbers of all seismic data channels in `S`.

Assumes each ID in S ends with an alphanumeric three-digit channel code and that
ID fields are separated by periods: for example, two channels with IDs
"XX.YYY.00.EHZ" and "_.YHY" both have an instrument code of 'H'.

Channel codes less than two characters long (e.g. "Z" in "AA.BBB.CC.Z") are ignored.

SEED channel codes of seismic and seismoacoustic data (for which operations
like detrend! and taper! are sane) include D, G, H, J, L, M, N, P, Z.

### See Also
get_inst_codes
"""
function get_seis_channels(S::GphysData)
  N = S.n
  chans = Int64[]
  @inbounds for i = 1:N
    id = S.id[i]
    L = length(id)
    for j = L:-1:1
      if id[j] == '.'
        j > L-2 && break
        if id[j+2] in seis_inst_codes
          push!(chans, i)
          break
        end
      end
    end
  end
  return chans
end
