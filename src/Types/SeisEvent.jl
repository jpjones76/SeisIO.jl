import Base:isequal, ==, sizeof
export SeisEvent

@doc (@doc SeisData)
mutable struct SeisEvent
  hdr::SeisHdr
  data::SeisData

  SeisEvent(; hdr=SeisHdr()::SeisHdr, data=SeisData()::SeisData) = return new(hdr, data)
end

# =============================================================================
# Methods from Base
isequal(S::SeisEvent, T::SeisEvent) = min(isequal(S.hdr, T.hdr), isequal(S.data, T.data))
==(S::SeisEvent, T::SeisEvent) = isequal(S,T)
sizeof(Ev::SeisEvent) = 16 + sizeof(Ev.hdr) + sizeof(Ev.data)
