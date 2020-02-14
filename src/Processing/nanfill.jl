export nanfill!

"""
  nanfill!(S::SeisData)
  nanfill!(C::SeisChannel)

Replace NaNs in `:x` with mean of non-NaN values.
"""
function nanfill!(S::GphysData)
  for i = 1:S.n
    if !isempty(S.x[i])
      nn = nanfill!(S.x[i])
      if nn > 0
        note!(S, i, string("¦ processing ¦ nanfill!(S) ¦ replaced ",
                           nn, "NaNs with the mean of all non-NaN values"))
      end
    end
  end
  return nothing
end

function nanfill!(C::GphysChannel)
  nn = nanfill!(C.x)
  if nn > 0
    note!(C, string("¦ processing ¦ nanfill!(C) ¦ replaced ",
                    nn, "NaNs with the mean of all non-NaN values"))
  end
  return nothing
end
