import Base:isequal, ==
export SeisEvent

"""
    S = SeisEvent()

Create a seismic event. A SeisEvent comprises a SeisHdr object (S.hdr) plus
a SeisData object (S.data).
"""
mutable struct SeisEvent
  hdr::SeisHdr
  data::SeisData

  SeisEvent(; hdr=SeisHdr()::SeisHdr, data=SeisData()::SeisData) = return new(hdr, data)
end

# =============================================================================
# Methods from Base
isequal(S::SeisEvent, T::SeisEvent) = min(isequal(S.hdr, T.hdr), isequal(S.data, T.data))
==(S::SeisEvent, T::SeisEvent) = isequal(S,T)
# isempty(S::SeisEvent) = min(isempty(S.data),isempty(S.hdr))
