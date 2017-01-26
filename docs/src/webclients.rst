******************
:mod:`Web Clients`
******************



SeedLink
########
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

Associated Functions
====================
``has_sta, has_stream, parsetimewin, SeedLink!, SeedLink, SL_config, SL_info, SL_minreq!``


FDSN
####
`FDSN <http://www.fdsn.org/>`_ is a global organization that supports seismology research. The FDSN web protocol offers near-real-time access to data from thousands of instruments across the world.


FDSN clients
============
``FDSNevq`` queries FDSN for events, and, if successful, returns the event headers.

``FDSNevt`` retrieves event headers and data in a user-specified phase window.

``FDSNget`` is a highly customizable wrapper to FDSN data access. All arguments are keywords.

``FDSNsta`` retrieves and parses station information.

Public FDSN servers
--------------------
* IRIS, WA, USA: http://service.iris.edu/fdsnws/

* Réseau Sismologique et Géodesique Français, FR: http://ws.resif.fr/fdsnws/ (data only)

* Northern California Earthquake Data Center, CA, USA: http://service.ncedc.org/fdsnws/

* GFZ Potsdam, DE: http://geofon.gfz-potsdam.de/fdsnws/


.. Example
.. -------
.. Download 10 minutes of data from 4 stations at Mt. St. Helens (WA, USA), delete the low-gain channels, and save to the current directory:
..
.. ::
..
..   S = FDSNget(net="CC,UW", sta="SEP,SHW,HSR,VALT", cha="*", t=600)
..   S -= "SHW    ELZUW"
..   S -= "HSR    ELZUW"
..   writesac(S)

Associated Functions
====================
``FDSNevq, FDSNevt, FDSNget, FDSNsta, parsetimewin``


IRIS
####
Incorporated Research Institutions for Seismology `(IRIS) <http://www.iris.edu/>`_ is a consortium of universities dedicated to the operation of science facilities for the acquisition, management, and distribution of seismological data. IRIS maintains an exhaustive number of data services.


IRIS Client
===========
``IRISget`` is a wrapper for the `IRIS timeseries web service <http://service.iris.edu/irisws/timeseries/1/>`_. IRISget requires a list of channels (array of ASCII strings) as the first argument; all other arguments are :ref:`keywords <web_client_keywords>`.

The channel list should be an array of channel identification strings, formated either "net.sta.chan" or "net_sta_chan" (e.g. ``["UW.HOOD.BHZ"; "CC.TIMB.EHZ"]``). Location codes are not used.


Notes
-----
* Trace data are de-meaned, but instrument response is unchanged.

* The IRIS web server doesn't return station coordinates.

* Wildcards in the channel list are not supported.


.. Example
.. -------
.. Request 10 minutes of continuous data recorded during the May 2016 earthquake swarm at Mt. Hood, OR, USA:
..
.. ::
..
..   STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"]
..   TS = "2016-05-16T14:50:00"; TE = 600
..   S = IRISget(STA, s=TS, t=TE)

Associated Functions
====================
``IRISget, irisws, parsetimewin``

.. _web_client_keywords:

Web Client Keywords
###################
The SeisIO web clients use a similar set of keywords; a full glossary is provided below. For client-specific keywords, the client(s) that support each keyword are listed in parenthesis.


.. csv-table:: List of keywords
  :header: kw, def, type, srvc, meaning
  :delim: ;
  :widths: 8, 8, 8, 8, 24

  a; 240; R; SL; keepalive interval (s)
  cha; "EHZ"; S; IRIS; channel code
  f; 0x00; u8; SL; safety check level
  g; 3600; R; SL; maxmum gap since last packet received
  loc; "--"; S; IRIS; instrument location [1]_
  mode; "DATA"; S; SL; mode (DATA/TIME/FETCH)
  net; "UW"; S; IRIS; network code
  patts; ["*"]; A(S,1); SL; channel/loc/data (accepts ``patts=["*"]`` as a wildcard)
  port; 18000; I64; SL; port number
  Q; "R"; S; F, I; quality (uses standard `FDSN/IRIS codes <https://ds.iris.edu/ds/nodes/dmc/manuals/breq_fast/#quality-option>`_ [2]_ )
  r; 20; R; SL; refresh interval (s)
  s; 0; U(R,DT,S); All; start time
  src; "IRIS"; S; F,I; source name
  sta; "TDH"; S; IRIS; station code
  strict; false; B; SL; strict mode (exit on errors)
  t; ±300 [3]_; U(R,D,S); All; end time
  to; 10; R; F,I; timeout (s)
  url; (iris); S; SL; url
  v; 0; I; All; verbosity level
  w; false; B; All; write download directly to file? [4]_
  y; false; B; F,I; synchronize channel times and fill gaps?

(for types, A = Array, B = Boolean, DT = DateTime, F = Float, I = Integer, R = Real, S = String, u = Unsigned, U = Union)

Web Client Time Specification
#############################
``d0,d1 = parsetimewin(s,t)`` converts input times to a sorted pair of DateTime objects. Behavior depends on the data types of the inputs:

.. csv-table::
  :header: type(s), type(t), behavior
  :delim: ;
  :widths: 8, 8, 24

  DT; DT; Sort only
  R; DT; Add ``s`` seconds to ``t``
  DT; R; Add ``t`` seconds to ``s``
  S; R; Convert ``s`` to DateTime, add ``t`` [5]_
  R; S; Convert ``t`` to DateTime, add ``s``
  R; R; Add ``s, t`` seconds to ``now()``

(above, R = Real, DT = DateTime, S = String, I = Integer)

.. rubric:: Footnotes

.. [1] Use ``loc="--"`` for seismic instruments with empty location codes.
.. [2] ``Q=R`` is not recommended and will not work on some FDSN servers.
.. [3] Default is ``t=-300`` for IRIS and FDSN, ``t=300`` for SeedLink; the difference arises because IRIS and FDSN clients archive data.
.. [4] If ``w=true``, a file name is automatically generated based on the request parameters.
.. [5] String inputs for ``s`` and/or ``t`` must take the form YYYY-MM-DDThh:mm:ss.nnn, where ``T`` is the uppercase character "T" and ``nnn`` denotes microseconds.
