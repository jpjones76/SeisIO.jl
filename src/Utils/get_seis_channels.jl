export filt_seis_chans!, filt_seis_chans, get_seis_channels

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
function get_seis_channels(S::GphysData;
  chans::Union{Integer, UnitRange, Array{Int64,1}}=Int64[])

  if chans == Int64[]
    chans = Int64.(collect(1:S.n))
  elseif typeof(chans) == UnitRange
    chans = Int64.(collect(chans))
  elseif typeof(chans) <: Integer
    chans = [Int64(chans)]
  end
  keep = falses(length(chans))

  @inbounds for (n,i) in enumerate(chans)
    id = S.id[i]
    L = length(id)
    for j = L:-1:1
      if id[j] == '.'
        j > L-2 && break
        if id[j+2] in seis_inst_codes
          keep[n] = true
          break
        end
      end
    end
  end

  return chans[keep]
end

@doc """
    filt_seis_chans!(chans::Union{Integer, UnitRange, Array{Int64,1}}, S::GphysData)
    filt_seis_chans(chans::Union{Integer, UnitRange, Array{Int64,1}}, S::GphysData)

Filter a channel list `chans` to channels in `S` that contain seismic data.

Assumes each ID in S ends with an alphanumeric three-digit channel code and that
ID fields are separated by periods: for example, if two channels have IDs
"XX.YYY.00.EHZ" and "_.YHY", each has an instrument code of 'H'.

Channel codes less than two characters long (e.g. "Z" in "AA.BBB.CC.Z") are ignored.

SEED channel codes of seismic and seismoacoustic data (for which operations
like detrend! and taper! are sane) include D, G, H, J, L, M, N, P, Z.

### See Also
get_inst_codes
""" filt_seis_chans!
function filt_seis_chans!(chans::Union{Integer, UnitRange, Array{Int64,1}}, S::GphysData)

  if typeof(chans) == UnitRange
    chans = Int64.(collect(chans))
  elseif typeof(chans) <: Integer
    chans = [Int64(chans)]
  end

  @inbounds for n = length(chans):-1:1
    id = S.id[chans[n]]
    L = length(id)
    for j = L:-1:1
      if id[j] == '.'
        j > L-2 && deleteat!(chans, n)
        if id[j+2] in seis_inst_codes == false
            deleteat!(chans, n)
        end
        break
      elseif j == 1
        deleteat!(chans, n)
      end
    end
  end
  return nothing
end

@doc (@doc filt_seis_chans!)
function filt_seis_chans(chans::Union{Integer, UnitRange, Array{Int64,1}}, S::GphysData)
  CC = deepcopy(chans)
  filt_seis_channels!(CC, S)
  return CC
end
