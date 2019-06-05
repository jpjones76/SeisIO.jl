S = SeisData( randSeisData(),
              randSeisChannel(),
              convert(EventChannel, randSeisChannel()),
              convert(EventTraceData, randSeisData()),
              randSeisEvent())

T = EventTraceData( randSeisData(),
                    randSeisChannel(),
                    convert(EventChannel, randSeisChannel()),
                    convert(EventTraceData, randSeisData()),
                    randSeisEvent())
