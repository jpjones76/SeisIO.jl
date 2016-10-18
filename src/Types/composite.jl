import Base:isequal

"""
    S = SeisEvent()

Create a seismic event. A SeisEvent comprises a SeisHdr object (S.hdr) plus
a SeisData object (S.data).
"""
type SeisEvent
  hdr::SeisHdr
  data::SeisData
  SeisEvent(; hdr=SeisHdr()::SeisHdr, data=SeisData()::SeisData) = return new(hdr, data)
end

# =============================================================================
# Equality
isequal(S::SeisEvent, T::SeisEvent) = minimum([isequal(S.hdr, T.hdr), isequal(S.data, T.data)])
==(S::SeisEvent, T::SeisEvent) = isequal(S,T)

## To do: SeisCat
