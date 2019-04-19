export nanfill!

"""
  nanfill!(S::SeisData)
  nanfill!(C::SeisChannel)

Replace NaNs in `:x` with mean of non-NaN values.

  nanfill!(Ev::SeisEvent)

Replace NaNs in `Ev.data.x` with mean of non-NaN values.
"""
function nanfill!(S::SeisData)
  for i = 1:S.n
    if !isempty(S.x[i])
      nanfill!(S.x[i])
      note!(S, i, "nanfill!")
    end
  end
  return nothing
end
nanfill!(C::SeisChannel) = (nanfill!(C.x); note!(C, "nanfill!"))
nanfill!(Ev::SeisEvent) = nanfill!(Ev.data)
