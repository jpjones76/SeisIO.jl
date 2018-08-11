***************
:mod:`SeedLink`
***************

`SeedLink <https://www.seiscomp3.org/wiki/doc/applications/seedlink>`_ is a TCP/IP-based data transmission protocol for near-real-time access.

SeedLink client
================
``SeedLink!(S, ...)`` invokes a native Julia SeedLink client on SeisData object ``S``. A channel list (array of ASCII strings) or config filename (ASCII string) must be passed as the first argument. Other other arguments are passed as keywords.


Valid Channel Specification
---------------------------
::

  nn sssss llccc.d
  nn sssss ccc.d
  nn sssss ccc
  nn sssss

n = network, s = station, l = location, c = channel, d = data flag; field length corresponds to expected number of characters. Selectors should follow `SeedLink offical specifications <https://www.seiscomp3.org/wiki/doc/applications/seedlink>`_ with ? indicating a wildcard; see Examples.

If passing a list of channels, construct an array of ASCII strings, e.g. ``["UW TDH","CC VALT BHZ.D"]``

If using a config file, the expected format is identical to `SLtool <http://ds.iris.edu/ds/nodes/dmc/software/downloads/slinktool/>`_ config files.


Working with SeedLink
---------------------
``SeedLink!(S, ...)`` operates on SeisData object ``S`` by appending a new TCP/IP connection handle to ``S.c``. Data are periodically parsed until the connection is closed. One SeisData object can support multiple connections provided each connection's streams feed different channels.

``close(S.c[i])`` ends a SeedLink connection. After the next refresh interval, remaining data in ``S.c[i]`` are parsed.

``!deleteat(S.c, i)`` removes a handle to a connection.

``SeedLink!(... , w=true)`` directly writes packets from a SeedLink connection to file.

``S = SeedLink(...)`` creates a new SeisData object fed by a new SeedLink connection.


Checking for Dead Streams
-------------------------
Not every data stream is always active.

``has_stream`` checks the time gaps of specified streams. Streams with two hours or more since last packet received return ``false``. Keyword ``g=XX`` sets the maximum allowed gap in seconds.


``has_sta`` checks whether a station exists on a given server.

``SeedLink!(... f=0x01)`` calls ``has_sta`` automatically, before initiating the new session.

``SeedLink!(... f=0x02)`` calls ``has_stream`` automatically, before initiating the new session.


Examples
--------
1. An unattended SeedLink download in TIME mode:

::

  sta = "UW.GPW,UW.MBW,UW.SHUK"
  s0 = now()
  S = SeedLink(sta, mode="TIME", s=s0, t=120, r=10)
  sleep(180)
  isopen(S.c[1]) && close(S.c[1])
  sleep(20)
  sync!(S)
  fname = string("GPW_MBW_SHUK", s0, ".seis")
  wseis(fname, S)

Get the next two minutes of data from stations GPW, MBW, SHUK in the UW network. Put the Julia REPL to sleep while the request fills. If the connection is still open, close it (SeedLink's time bounds arent precise in TIME mode, so this may or may not be necessary). Pause briefly so that the last data packets are written. Synchronize results and write data in native SeisIO file format.

2. An attended SeedLink session in DATA mode:

::

  S = SeisData()
  SeedLink!(S, "SL.conf", mode="DATA", r=10, w=true)

Initiate a SeedLink session in DATA mode using config file SL.conf and write all packets received directly to file (in addition to parsing to S itself). Set nominal refresh interval for checking for new data to 10 s. A mini-seed file will be generated automatically.


Associated Functions
====================
``has_sta, has_stream, parsetimewin, SeedLink!, SeedLink, SL_config, SL_info``
