export SeisEvent

mutable struct SeisEvent
  hdr::SeisHdr
  source::SeisSrc
  data::EventTraceData

  SeisEvent(hdr::SeisHdr, source::SeisSrc, data::EventTraceData) = new(hdr, source, data)
end

function SeisEvent(;
                    hdr ::SeisHdr     = SeisHdr(),
                    source::SeisSrc   = SeisSrc(),
                    data::T           = EventTraceData()
                    ) where {T<:GphysData}

  if T != EventTraceData
    return SeisEvent(hdr, source, convert(EventTraceData, data))
  else
    return SeisEvent(hdr, source, data)
  end
end

# =============================================================================
# Methods from Base
isequal(S::SeisEvent, T::SeisEvent) = min(isequal(S.hdr, T.hdr),
                                          isequal(S.source, T.source),
                                          isequal(S.data, T.data))
==(S::SeisEvent, T::SeisEvent) = isequal(S,T)
sizeof(Ev::SeisEvent) = 24 + sizeof(Ev.hdr) + sizeof(Ev.source) + sizeof(Ev.data)


# SeisEvent
write(io::IO, W::SeisEvent) = ( write(io, getfield(W, :hdr));
                                write(io, getfield(W, :source));
                                write(io, getfield(W, :data))
                                )

read(io::IO, ::Type{SeisEvent}) = SeisEvent(read(io, SeisHdr),
                                            read(io, SeisSrc),
                                            read(io, EventTraceData))

summary(V::SeisEvent) = string("Event ", V.hdr.id, ": SeisEvent with ",
  V.data.n, " channel", V.data.n == 1 ? "" : "s")

function show(io::IO, S::SeisEvent)
  println(io, summary(S))
  println(io, "\n(.hdr)")
  show(io, getfield(S, :hdr))
  println(io, "\n(.source)")
  show(io, getfield(S, :source))
  println(io, "\n(.data)")
  println(io, summary(getfield(S, :data)))
  return nothing
end
show(S::SeisEvent) = show(stdout, S)
