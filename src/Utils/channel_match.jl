export channel_match

channel_match( S::GphysData, j::Integer, fs::Float64) = (j == 0 ? 0 : S.fs[j] == fs ? j : 0)
function channel_match( S::GphysData,
                        j::Integer,
                        fs::Float64,
                        gain::AbstractFloat,
                        loc::InstrumentPosition,
                        resp::InstrumentResponse,
                        units::String
                      )
  (j == 0) && (return 0)
  return (
    try
      @assert(S.fs[j] == fs)
      @assert(S.gain[j] == gain)
      @assert(S.units[j] == units)
      @assert(loc == S.loc[j])
      @assert(resp == S.resp[j])
      j
    catch err
      0
    end
  )
end
function channel_match( S::GphysData, C::GphysChannel )
  j = findid(S, C.id)
  j = channel_match( S, j, C.fs, C.gain, C.loc, C.resp, C.units)
  return j
end
