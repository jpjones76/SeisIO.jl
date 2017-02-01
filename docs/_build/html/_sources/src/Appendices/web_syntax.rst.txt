###################################
Appendix D: Web Keywords and Syntax
###################################

.. _cid:

*****************
Channel ID Syntax
*****************
``NN.SSSSS.LL.CC`` (net.sta.loc.cha, separated by periods) is the expected syntax for all web functions. The maximum field width in characters corresponds to the length of each field (e.g. 2 for network). Fields can't contain whitespace.

``NN.SSSSS.LL.CC.T`` (net.sta.loc.cha.tflag) is allowed in SeedLink. ``T`` is a single-character data type flag and must be one of ``DECOTL``: Data, Event, Calibration, blOckette, Timing, or Logs. Calibration, timing, and logs are not in the scope of SeisIO and may crash SeedLink sessions.

The table below specifies valid types and expected syntax for channel lists.

+-----------------+---------------------+-----------------------------------------+
| Type            | Description         | Example                                 |
+=================+=====================+=========================================+
| String          | Comma-delineated ID | "PB.B004.01.BS1,PB.B002.01.BS1"         |
|                 | list                |                                         |
+-----------------+---------------------+-----------------------------------------+
| Array{String,1} | String array, one   | ["PB.B004.01.BS1","PB.B002.01.BS1"]     |
|                 | ID string per entry |                                         |
+-----------------+---------------------+-----------------------------------------+
| Array{String,2} | String array, one   | ["PB" "B004" "01" "BS1";                |
|                 | ID string per row   |  "PB" "B002" "01" "BS1"]                |
+-----------------+---------------------+-----------------------------------------+

The expected component order is always network, station, location, channel; thus, "UW.TDH..EHZ" is OK, but "UW.TDH.EHZ" fails.


Wildcards and Blanks
====================
Allowed wildcards are client-specific.

* The LOC field can be left blank in any client because it was rarely used until the mid-2000s: ``"UW.ELK..EHZ"`` and ``["UW" "ELK" "" "EHZ"]`` are all valid. Blank LOC fields are set to ``--`` in IRIS, ``*`` in FDSN, and ``??`` in SeedLink.

* ``?`` acts as a single-character wildcard in FDSN & SeedLink. Thus, ``CC.VALT..???`` is valid.

* ``*`` acts as a multi-character wildcard in FDSN. Thus, ``CC.VALT..*`` and ``CC.VALT..???`` behave identically in FDSN.

* Partial specifiers are OK, but a network and station are always required: ``"UW.EL?"`` is OK, ``".ELK.."`` fails.


Channel Configuration Files
===========================
One entry per line, ASCII text, format NN.SSSSS.LL.CCC.D. Due to client-specific wildcard rules, the most versatile configuration files are those that specify each channel most completely:
::

  # This only works with SeedLink
  GE.ISP..BH?.D
  NL.HGN
  MN.AQU..BH?
  MN.AQU..HH?
  UW.KMO
  CC.VALT..BH?.D

  # This works with FDSN and SeedLink, but not IRIS
  GE.ISP..BH?
  NL.HGN
  MN.AQU..BH?
  MN.AQU..HH?
  UW.KMO
  CC.VALT..BH?

  # This works with all three:
  GE.ISP..BHZ
  GE.ISP..BHN
  GE.ISP..BHE
  MN.AQU..BHZ
  MN.AQU..BHN
  MN.AQU..BHE
  MN.AQU..HHZ
  MN.AQU..HHN
  MN.AQU..HHE
  UW.KMO..EHZ
  CC.VALT..BHZ
  CC.VALT..BHN
  CC.VALT..BHE


.. _time_syntax:

************
Time Syntax
************
Specify time inputs for web queries as a DateTime, Real, or String. The latter must take the form YYYY-MM-DDThh:mm:ss.nnn, where ``T`` is the uppercase character `T` and ``nnn`` denotes milliseconds; incomplete time strings treat missing fields as 0.

.. csv-table::
  :header: type(s), type(t), behavior
  :delim: ;
  :widths: 8, 8, 24

  DT; DT; Sort only
  R; DT; Add ``s`` seconds to ``t``
  DT; R; Add ``t`` seconds to ``s``
  S; R; Convert ``s`` to DateTime, add ``t``
  R; S; Convert ``t`` to DateTime, add ``s``
  R; R; Add ``s, t`` seconds to ``now()``

(above, R = Real, DT = DateTime, S = String, I = Integer)


.. _dkw:

*******************
Data Query Keywords
*******************
.. csv-table::
  :header: kw, def, type [#]_, srvc [#]_, meaning
  :delim: ;
  :widths: 8, 8, 8, 8, 24

  a; 240; R; SL; keepalive interval (s)
  f; 0x00; u8; SL; safety check level
  g; 3600; R; SL; maxmum gap since last packet received
  m; "DATA"; S; SL; mode (DATA/TIME/FETCH)
  p; 18000; I64; SL; port number
  q; 'R'; c; FD, IW; quality (uses standard `FDSN/IRIS codes <https://ds.iris.edu/ds/nodes/dmc/manuals/breq_fast/#quality-option>`_ [#]_ )
  r; 20; R; SL; refresh interval (s)
  s; 0; U(R,DT,S); All; start time
  src; "IRIS"; S; FD,IW; :ref:`source institution<fdsn_src>`
  x; false; B; SL; strict mode (exit on errors)
  t; 300 [#]_; U(R,D,S); All; end time
  to; 10; R; FD,IW; timeout (s)
  u; (iris); S; SL; url
  v; 0; IW; All; verbosity level
  w; false; B; All; write download directly to file? [#]_
  y; false; B; FD,IW; synchronize channel times and fill gaps?


.. rubric:: Table Footnotes

.. [#] A = Array, B = Boolean, c = Char, DT = DateTime, F = Float, I = Integer, R = Real, S = String, u = Unsigned, U = Union
.. [#] SL = SeedLink, IW = IRISws, FD = FDSN
.. [#] ``Q='R'`` won't work on some FDSN servers.
.. [#] Default is ``t=-300`` for IRIS and FDSN, ``t=300`` for SeedLink; the sign difference arises because of differences in service scope.
.. [#] If ``w=true``, a file name is automatically generated from the request parameters.

.. _fdsn_src:

``src`` Options
===============
.. csv-table::
  :header: ``src=``, URL Queried, Source Institution
  :widths: 1, 4, 4
  :delim: |

  \"IRIS\"  | http://service.iris.edu/fdsnws/ | Incorporated Research Institutions for Seismology, US
  \"RESIF\" | http://ws.resif.fr/fdsnws/ | Réseau Sismologique et Géodesique Français, FR
  \"NCEDC\" | http://service.ncedc.org/fdsnws/ | Northern California Earthquake Data Center, US
  \"GFZ\"   | http://geofon.gfz-potsdam.de/fdsnws/ | GFZ Potsdam, DE
  \"All\"   | All of the above | All of the above [#]_

.. rubric:: Table Footnotes

.. [#] Presently only supported in event queries.

.. _ekw:

********************
Event Query Keywords
********************
.. csv-table::
  :header: Keyword, Type, Default, Description
  :widths: 1, 1, 2, 4
  :delim: |

  dep | A{F64,2}  | \[-30.0 700.0\]   | depth range in km
  lat | A{F64,2}  | \[-90.0 90.0\]    | latitude range in degrees
  lon | A{F64,2}  | \[-180.0 180.0\]  | longitude range in degrees
  mag | A{F64,2}  | \[6.0 9.9\]       | magnitude range
  n   | Int       | 1                 | return N events with closest origin times
  src | String    | \"IRIS\"          | :ref:`source institution<fdsn_src>`
  w   | Int       | 86400             | search W seconds around T for events
  x   | Bool      | false             | treat T as exact to one second; overrides w
