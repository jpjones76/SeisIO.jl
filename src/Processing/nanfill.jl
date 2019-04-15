export nanfill!

function nanfill!(S::SeisData)
  for i = 1:S.n
    if !isempty(S.x[i])
      nanfill!(S.x[i])
      note!(S, i, "nanfill! replaced NaNs with mean of non-NaNs.")
    end
  end
  return nothing
end
nanfill!(C::SeisChannel) = nanfill!(C.x)
nanfill!(Ev::SeisEvent) = nanfill!(Ev.data)
