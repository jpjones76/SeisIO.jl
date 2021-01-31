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

function channel_match( C::GphysChannel, D::GphysChannel ; use_gain::Bool=true )
  ff = use_gain ? (:id, :fs, :gain, :loc, :resp, :units) : (:id, :fs, :loc, :resp, :units)
  return all([isequal(getfield(C, f), getfield(D, f)) for f in ff ])
end

# This will seek out a match and correct unset values if a partial match is found
function cmatch_p!( C::GphysChannel, D::GphysChannel )
  fs_match    = max(    C.fs == D.fs   ,    C.fs == default_fs   ,    D.fs == default_fs   )
  gain_match  = max(  C.gain == D.gain ,  C.gain == default_gain ,  D.gain == default_gain )
  loc_match   = max(   C.loc == D.loc  ,   C.loc == default_loc  ,   D.loc == default_loc  )
  resp_match  = max(  C.resp == D.resp ,  C.resp == default_resp ,  D.resp == default_resp )
  units_match = max( C.units == D.units, C.units == ""           , D.units == ""           )
  m = min(C.id == D.id, fs_match, gain_match, loc_match, resp_match, units_match)
  if m
    # Fill any "unset" values in D from C
    (    D.fs == default_fs   ) && (    D.fs = C.fs               )
    (  D.gain == default_gain ) && (  D.gain = C.gain             )
    (   D.loc == default_loc  ) && (   D.loc = deepcopy(C.loc)    )
    (  D.resp == default_resp ) && (  D.resp = deepcopy(C.resp)   )
    ( D.units == ""           ) && ( D.units = identity(C.units)  )

    # Fill any "unset" values in C from D
    (    C.fs == default_fs   ) && (    C.fs = D.fs               )
    (  C.gain == default_gain ) && (  C.gain = D.gain             )
    (   C.loc == default_loc  ) && (   C.loc = deepcopy(D.loc)    )
    (  C.resp == default_resp ) && (  C.resp = deepcopy(D.resp)   )
    ( C.units == ""           ) && ( C.units = identity(D.units)  )
  end
  return m
end
