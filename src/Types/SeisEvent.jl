export SeisEvent

mutable struct SeisEvent
  hdr::SeisHdr
  data::EventTraceData

  SeisEvent(hdr::SeisHdr, data::EventTraceData) = new(hdr, data)
end

function SeisEvent(;
                    hdr ::SeisHdr = SeisHdr(),
                    data::T       = EventTraceData()
                    ) where {T<:GphysData}

  if T != EventTraceData
    return SeisEvent(hdr, convert(EventTraceData, data))
  else
    return SeisEvent(hdr, data)
  end
end

# =============================================================================
# Methods from Base
isequal(S::SeisEvent, T::SeisEvent) = min(isequal(S.hdr, T.hdr), isequal(S.data, T.data))
==(S::SeisEvent, T::SeisEvent) = isequal(S,T)
sizeof(Ev::SeisEvent) = 16 + sizeof(Ev.hdr) + sizeof(Ev.data)
