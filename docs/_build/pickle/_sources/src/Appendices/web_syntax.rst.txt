####################
Data Requests Syntax
####################

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
| String          | Comma-delineated    | "PB.B004.01.BS1,PB.B002.01.BS1"         |
|                 | list of IDs         |                                         |
+-----------------+---------------------+-----------------------------------------+
| Array{String,1} | String array, one   | ["PB.B004.01.BS1","PB.B002.01.BS1"]     |
|                 | ID string per entry |                                         |
+-----------------+---------------------+-----------------------------------------+
| Array{String,2} | String array, one   | ["PB" "B004" "01" "BS1";                |
|                 | ID string per row   |  "PB" "B002" "01" "BS1"]                |
+-----------------+---------------------+-----------------------------------------+

The expected component order is always network, station, location, channel; thus, "UW.TDH..EHZ" is OK, but "UW.TDH.EHZ" fails.

.. function:: chanspec()

Type ``?chanspec`` in Julia to print the above info. to stdout.

Wildcards and Blanks
====================
Allowed wildcards are client-specific.

* The LOC field can be left blank in any client: ``"UW.ELK..EHZ"`` and ``["UW" "ELK" "" "EHZ"]`` are all valid. Blank LOC fields are set to ``--`` in IRIS, ``*`` in FDSN, and ``??`` in SeedLink.
* ``?`` acts as a single-character wildcard in FDSN & SeedLink. Thus, ``CC.VALT..???`` is valid.
* ``*`` acts as a multi-character wildcard in FDSN. Thus, ``CC.VALT..*`` and ``CC.VALT..???`` behave identically in FDSN.
* Partial specifiers are OK, but a network and station are always required: ``"UW.EL?"`` is OK, ``".ELK.."`` fails.

.. _ccfg:

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

.. _servers:

Server List
===========

  +--------+---------------------------------------+
  | String | Source                                |
  +========+=======================================+
  | BGR    | http://eida.bgr.de                    |
  +--------+---------------------------------------+
  | EMSC   | http://www.seismicportal.eu           |
  +--------+---------------------------------------+
  | ETH    | http://eida.ethz.ch                   |
  +--------+---------------------------------------+
  | GEONET | http://service.geonet.org.nz          |
  +--------+---------------------------------------+
  | GFZ    | http://geofon.gfz-potsdam.de          |
  +--------+---------------------------------------+
  | ICGC   | http://ws.icgc.cat                    |
  +--------+---------------------------------------+
  | INGV   | http://webservices.ingv.it            |
  +--------+---------------------------------------+
  | IPGP   | http://eida.ipgp.fr                   |
  +--------+---------------------------------------+
  | IRIS   | http://service.iris.edu               |
  +--------+---------------------------------------+
  | ISC    | http://isc-mirror.iris.washington.edu |
  +--------+---------------------------------------+
  | KOERI  | http://eida.koeri.boun.edu.tr         |
  +--------+---------------------------------------+
  | LMU    | http://erde.geophysik.uni-muenchen.de |
  +--------+---------------------------------------+
  | NCEDC  | http://service.ncedc.org              |
  +--------+---------------------------------------+
  | NIEP   | http://eida-sc3.infp.ro               |
  +--------+---------------------------------------+
  | NOA    | http://eida.gein.noa.gr               |
  +--------+---------------------------------------+
  | ORFEUS | http://www.orfeus-eu.org              |
  +--------+---------------------------------------+
  | RESIF  | http://ws.resif.fr                    |
  +--------+---------------------------------------+
  | SCEDC  | http://service.scedc.caltech.edu      |
  +--------+---------------------------------------+
  | TEXNET | http://rtserve.beg.utexas.edu         |
  +--------+---------------------------------------+
  | USGS   | http://earthquake.usgs.gov            |
  +--------+---------------------------------------+
  | USP    | http://sismo.iag.usp.br               |
  +--------+---------------------------------------+

  .. function:: seis_www()

  Type ``?seis_www`` in Julia to print the above info. to stdout.

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
