import Base:isequal

"""
    S = SeisEvt()

Create a seismic event. A SeisEvt comprises a SeisHdr object (S.hdr) plus
a SeisData object (S.data).
"""
type SeisEvt
  hdr::SeisHdr
  data::SeisData
  SeisEvt(; hdr=SeisHdr()::SeisHdr, data=SeisData()::SeisData) = return new(hdr, data)
end

# =============================================================================
# Equality
isequal(S::SeisEvt, T::SeisEvt) = minimum([isequal(S.hdr, T.hdr), isequal(S.data, T.data)])
==(S::SeisEvt, T::SeisEvt) = isequal(S,T)

## To do: SeisCat
