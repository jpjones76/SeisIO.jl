==========
Appendices
==========

.. _timespec:

###########
Time Syntax
###########
Functions that allow time specification use two reserved keywords or arguments to track time:

* *s*: Start (begin) time
* *t*: Termination (end) time

Specify each as a DateTime, Real, or String.

* Real numbers are interpreted as seconds. Special behavior is invoked when both *s* and *t* are of Type Real.

* DateTime values should follow `Julia documentation\ <https://docs.julialang.org/en/v1/stdlib/Dates/>`_

* Strings have the expected format spec ``YYYY-MM-DDThh:mm:ss.ssssss``

  * Fractional second is optional and accepts up to 6 decimal places (μs)

  * Incomplete time Strings treat missing fields as 0.

  * Example: `s="2016-03-23T11:17:00.333"`

It isn't necessary to choose values so that *s* ≤ *t*. The two values are always sorted, so that *t* < *s* doesn't error.

***********************
Time Types and Behavior
***********************

.. csv-table::
  :header: typeof(s), typeof(t), Behavior
  :delim: |
  :widths: 1, 1, 4

  DateTime  | DateTime  | convert to String, then sort
  DateTime  | Real      | add *t* seconds to *s*, convert to String, then sort
  DateTime  | String    | convert *s* to String, then sort
  Real      | DateTime  | add *s* seconds to *t*, convert to String, then sort
  Real      | Real      | treat as relative (see below), convert to String, sort
  Real      | String    | add *s* seconds to *t*, convert to String, then sort
  String    | DateTime  | convert *t* to String, then sort
  String    | Real      | add *t* seconds to *s*, convert to String, then sort
  String    | String    | sort

Special Behavior with two Real arguments
========================================
If *s* and *t* are both Real numbers, they're treated as seconds measured relative to the *start of the current minute*. This convention may seem unusual, but it greatly simplifies web requests; for example, specifying *s=-1200.0, t=0.0* is a convenient shorthand for "the last 20 minutes of data".

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

.. csv-table::
  :header: Type, Description, Example
  :widths: 4, 8, 8
  :delim: |

  String          | Comma-delineated list of IDs          | \"PB.B004.01.BS1, PB.B002.01.BS1\"
  Array{String,1} | String array, one ID string per entry | [\"PB.B004.01.BS1\", \"PB.B002.01.BS1\"]
  Array{String,2} | String array, one set of IDs per row  | [\"PB\" \"B004\" \"01\" \"BS1\";
  | | \"PB\" \"B002\" \"01\" \"BS1\"]

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

.. _dkw:

########################
SeisIO Standard Keywords
########################

SeisIO.KW is a memory-resident structure of default values for common keywords
used by package functions. KW has one substructure, SL, with keywords specific
to SeedLink. These defaults can be modified, e.g., SeisIO.KW.nev=2 changes the
default for nev to 2.

+--------+----------------+--------+------------------------------------------+
| KW     | Default        | T [#]_ | Meaning                                  |
+========+================+========+==========================================+
| comp   | 0x00           | U8     |  compress data on write? [#]_            |
+--------+----------------+--------+------------------------------------------+
| fmt    | "miniseed"     | S      | request data format [#]_                 |
+--------+----------------+--------+------------------------------------------+
| mag    | [6.0, 9.9]     | A{F,1} | magnitude range for queries              |
+--------+----------------+--------+------------------------------------------+
| n_zip  | 100000         | I      | compress if length(:x) > n_zip           |
+--------+----------------+--------+------------------------------------------+
| nd     | 1              | I      | number of days per subrequest            |
+--------+----------------+--------+------------------------------------------+
| nev    | 1              | I      | number of events returned per query      |
+--------+----------------+--------+------------------------------------------+
| nx_add | 360000         | I      | length increase of undersized data array |
+--------+----------------+--------+------------------------------------------+
| nx_new | 8640000        | I      | number of samples for a new channel      |
+--------+----------------+--------+------------------------------------------+
| opts   | ""             | S      | user-specified options [#]_              |
+--------+----------------+--------+------------------------------------------+
| prune  | true           | B      | call prune! after get_data?              |
+--------+----------------+--------+------------------------------------------+
| rad    | []             | A{F,1} | radial search region [#]_                |
+--------+----------------+--------+------------------------------------------+
| reg    | []             | A{F,1} | rectangular search region [#]_           |
+--------+----------------+--------+------------------------------------------+
| si     | true           | B      | autofill station info on data req? [#]_  |
+--------+----------------+--------+------------------------------------------+
| src    | "IRIS"         | S      |  data source; type *?seis_www* for list  |
+--------+----------------+--------+------------------------------------------+
| to     | 30             | I      | read timeout for web requests (s)        |
+--------+----------------+--------+------------------------------------------+
| v      | 0              | I      | verbosity                                |
+--------+----------------+--------+------------------------------------------+
| w      | false          | B      | write requests to disk? [#]_             |
+--------+----------------+--------+------------------------------------------+
| y      | false          | B      | sync data after web request?             |
+--------+----------------+--------+------------------------------------------+


.. rubric:: Table Footnotes
.. [#] Types: A = Array, B = Boolean, C = Char, DT = DateTime, F = Float, I = Integer, S = String, U8 = Unsigned 8-bit integer (UInt8)
.. [#] If KW.comp == 0x00, never compress data; if KW.comp == 0x01, only compress channel *i* if *length(S.x[i]) > KW.n_zip*; if comp == 0x02, always compress data.
.. [#] Strings have the same names and spellings as file formats in `read_data`. Note that "sac" in a web request is aliased to "sacbl", i.e., binary little-endian SAC, to match the native endianness of the Julia language.
.. [#] String is passed as-is, e.g. "szsrecs=true&repo=realtime" for FDSN. String should not begin with an ampersand.
.. [#] Specify region **[center_lat, center_lon, min_radius, max_radius, dep_min, dep_max]**, with lat, lon, and radius in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] Specify region **[lat_min, lat_max, lon_min, lon_max, dep_min, dep_max]**, with lat, lon in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] FDSNWS timeseries only.
.. [#] If **w=true**, a file name is automatically generated from the request parameters, in addition to parsing data to a SeisData structure. Files are created from the raw download even if data processing fails, in contrast to get_data(... wsac=true).
.. _function_list:

#################
Utility Functions
#################
This appendix covers utility functions that belong in no other category.

.. function:: d2u(DT::DateTime)

Aliased to ``Dates.datetime2unix``.

.. function:: fctoresp(fc, c)

Generate a generic PZResp object for a geophone with critical frequency ``fc`` and damping constant ``c``. If no damping constant is specified, assumes c = 1/sqrt(2).

.. function:: find_regex(path::String, r::Regex)

OS-agnostic equivalent to Linux `find`. First argument is a path string, second is a Regex. File strings are postprocessed using Julia's native PCRE Regex engine. By design, `find_regex` only returns file names.

.. function:: getbandcode(fs, fc=FC)

Get SEED-compliant one-character band code corresponding to instrument sample rate ``fs`` and corner frequency ``FC``. If unset, ``FC`` is assumed to be 1 Hz.

.. function:: get_file_ver(fname::String)

Get the version of a SeisIO native format file.

.. function:: get_seis_channels(S::GphysData)

Get numeric indices of channels in S whose instrument codes indicate seismic data.

.. function:: guess(fname::String)

Attempt to guess data file format and endianness using known binary file markers.

.. function:: inst_code(C::GphysChannel)
.. function:: inst_code(S::GphysData, i::Int64)
.. function:: inst_code(S::GphysData)

Get instrument codes.

.. function:: ls(s::String)

Similar functionality to Bash ls with OS-agnostic output. Accepts wildcards in paths and file names.
* Always returns the full path and file name.
* Partial file name wildcards (e.g. "`ls(data/2006*.sac)`) invoke `glob`.
* Path wildcards (e.g. `ls(/data/*/*.sac)`) invoke `find_regex` to circumvent glob limitations.
* Passing ony "*" as a filename (e.g. "`ls(/home/*)`) invokes `find_regex` to recursively search subdirectories, as in the Bash shell.

.. function:: ls()

Return full path and file name of files in current working directory.

.. function:: j2md(y, j)

Convert Julian day **j** of year **y** to month, day.

.. function:: md2j(y, m, d)

Convert month **m**, day **d** of year **y** to Julian day **j**.

.. function namestrip(s::String[, convention="File")

Remove unwanted characters from S.

.. function:: parsetimewin(s, t)

Convert times **s** and **t** to strings :math:`\alpha, \omega` sorted :math:`\alpha < \omega`. **s** and **t** can be real numbers, DateTime objects, or ASCII strings. Expected string format is "yyyy-mm-ddTHH:MM:SS.nnn", e.g. 2016-03-23T11:17:00.333.

.. function:: resp_a0!(R::InstrumentResponse)
.. function:: resp_a0!(S::GphysData)

Update sensitivity :a0 of PZResp/PZResp64 responses.

.. function:: resptofc(R)

Attempt to guess critical frequency from poles and zeros of a PZResp/PZResp64.

.. function:: set_file_ver(fname::String)

Sets the SeisIO file version of file fname.

.. function:: u2d(x)

Alias to ``Dates.unix2datetime``.

.. function:: validate_units(S::GphysData)

Validate strings in :units field to ensure UCUM compliance.

.. function:: vucum(str::String)

Check whether ``str`` contains valid UCUM units.
.. _seisio_file_format:

####################
SeisIO Native Format
####################
Invoking the command *wseis* writes SeisIO structures to a native data format
in little-endian byte order. This page documents the low-level file format.
Abbreviations used:

.. csv-table::
  :header: Type, Meaning, C, Fortran 77
  :widths: 3, 10, 4, 4

  Char, Unicode character, wchar, CHARACTER*4
  Float32, 32-bit float, float, REAL
  Float64, 64-bit float, double, REAL*8
  Int8, signed 8-bit int, short, INTEGER
  Int16, signed 16-bit int, int, INTEGER*2
  Int32, signed 32-bit int, long, INTEGER*4
  Int64, signed 64-bit integer, long long, INTEGER*8
  UInt8, unsigned 8-bit int, unsigned short, CHARACTER
  UInt16, unsigned 16-bit int, unsigned,
  UInt32, unsigned 32-bit int, unsigned long,
  UInt64, unsigned 64-bit int, unsigned long long,

| Special instructions:
|
| Parentheses, "()", denote a custom object Type.
| "{ (condition)" denotes the start of a loop; (condition) is the control flow.
| "}" denotes the end of a loop.

Note that String in Julia has no exact C equivalence. SeisIO writes each String
in two parts: an Int64 (String length in bytes) followed by the String contents
(as bytes, equivalent to UInt8). Unlike C/Fortran, there are no issues with
strings that contain the null character (0x00 or ``'\x0'``).

***********
SeisIO File
***********

.. csv-table::
  :header: Var, Meaning, T, N
  :widths: 4, 32, 8, 8

  ,\"SEISIO\",UInt8,6
  ``V``,SeisIO file format version,Float32,1
  ``J``,\# of SeisIO objects in file,UInt32,1
  ``C``,:ref:`SeisIO object codes<object_codes>` for each object,UInt32,J
  ``B``,Byte indices for each object,UInt64,J
  { , , , for i = 1:J
  ,(Objects),variable,J
  } , , ,
  ``ID``,ID hashes,UInt64, variable
  ``TS``,Start times,Int64, variable
  ``TE``,End times,Int64, variable
  ``P``,Parent object index in C and B, variable
  ``bID``,Byte offset of ``ID`` array, Int64, 1
  ``bTS``,Byte offset of ``TS`` array, Int64, 1
  ``bTE``,Byte offset of ``TE`` array, Int64, 1
  ``bP``,Byte offset of ``P`` array, Int64, 1

ID, TS, and TE are the ID, data start time, and data end time of each channel
in each object. P is the index of the parent object in C and B. TS and TE are
measured from Unix epoch time (1970-01-01T00:00:00Z) in integer microseconds.

Intent: when seeking data from channel ``i`` between times ``s`` and ``t``,
if ``hash(i)`` matches ``ID[j]`` and the time windows overlap, retrieve index
``k = P[j]`` from NP, seek to byte offset ``B[k]``, and read an object of
type ``C[k]`` from file.

If an archive contains no data objects, ID, TS, TE, and P are empty;
equivalently, ``bID == bTS``.

*******************
Simple Object Types
*******************
Fields of these objects are written in one of three ways: as "plain data" types,
such as UInt8 or Float64; as arrays; or as strings.

In a simple object, each array is stored as follows:
1. Int64 number of dimensions (e.g. 2)
2. Int64 array of dimensions themselves (e.g. 2, 2)
3. Array values (e.g. 0.08250153, 0.023121119, 0.6299772, 0.79595184)

EQLoc
=====
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8

  lat, Float64, 1, latitude
  lon, Float64, 1, longitude
  dep, Float64, 1, depth
  dx, Float64, 1, x-error
  dy, Float64, 1, y-error
  dz, Float64, 1, z-error
  dt, Float64, 1, t-error (error in origin time)
  se, Float64, 1, standard error
  rms, Float64, 1, rms pick error
  gap, Float64, 1, azimuthal gap
  dmin, Float64, 1, minimum source-receiver distance in location
  dmax, Float64, 1, maximum source-receiver distance in location
  nst, Int64, 1, number of stations used to locate earthquake
  flags, UInt8, 1, one-bit flags for special location properties
  Ld, Int64, 1, length of "datum" string in bytes
  datum, UInt8, Ld, Datum string
  Lt, Int64, 1, length of "typ" (event type) string in bytes
  typ, UInt8, Lt, earthquake type string
  Li, Int64, 1, length of "sig" (error significance) string in bytes
  sig, UInt8, Li, earthquake location error significance string
  Lr, Int64, 1, length of "src" (data source) string in bytes
  src, UInt8, Lr, data source string

| flag meanings: (0x01 = true, 0x00 = false)
| 1. x fixed?
| 2. y fixed?
| 3. z fixed?
| 4. t fixed?
| In Julia, get the value of flag[n] with ``>>(<<(flags, n-1), 7)``.

EQMag
=====
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8
  :delim: |

  val | Float32 | 1 | magnitude value
  gap | Float64 | 1 | largest azimuthal gap between stations in magnitude
  nst | Int64 | 1 | number of stations used in magnitude computation
  Lsc | Int64 | 1 | length of magnitude scale string
  msc | UInt8 | Lsc | magnitude scale string
  Lr | Int64 | 1 | length of data source string
  src | UInt8 | Lr | data source string

SeisPha
=======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8
  :delim: |

  F | Float64 | 8 | amplitude, distance, incidence angle, residual,
    | | | ray parameter, takeoff angle, travel time, uncertainty
  C | Char | 2 | polarity, quality

SourceTime
==========
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8
  :delim: |

  Ld | Int64 | 1 | size of descriptive string in bytes
  desc | UInt8 | 1 | descriptive string
  F | Float64 | 3 | duration, rise time, decay time

StringVec
=========
A vector of variable-length strings; its exact Type in Julia is Array{String,1}.

.. csv-table:: StringVec
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8

  ee, UInt8, 1, is this string vector empty? [#]_
  L, Int64, 1, number of strings to read
  { , , , i = 1:L
  nb, Int64, 1, length of string in bytes
  str, UInt8, nb, string
  } , , ,

.. [#] If ``ee == 0x00``, then no values are stored for L, nb, or str.

**************
Location Types
**************

GenLoc
======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8

  Ld, Int64, 1, length of datum string in bytes
  datum, UInt8, Ld, datum string
  Ll, Int64, 1, length of location vector in bytes
  loc, Float64, Ll, location vector

GeoLoc
======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8
  :delim: |

  Ld | Int64 | 1 | length of datum string in bytes
  datum | UInt8 | Ld | datum string
  F | Float64 | 6 | latitude, longitude, elevation,
    | | | depth, azimuth, incidence

UTMLoc
======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8
  :delim: |

  Ld | Int64 | 1 | length of datum string in bytes
  datum | UInt8 | N | datum string
  zone | Int8 | 1 | UTM zone number
  hemi | Char | 1 | hemisphere
  E | UInt64 | 1 | Easting
  N | UInt64 | 1 | Northing
  F | Float64 | 4 | elevation, depth, azimuth, incidence

XYLoc
=====
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8
  :delim: |

  Ld | Int64 | 1 | Length of datum string in bytes
  datum | UInt8 | Ld | datum string
  F | Float64 | 8 | x, y, z, azimuth, incidence, origin x, origin y, origin z

**************
Response Types
**************
GenResp
=======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 3, 1, 8
  :delim: |

  Ld| Int64| 1| length of descriptive string in bytes
  desc| UInt8| Ld| descriptive string
  nr| Int64| 1| Number of rows in complex response matrix
  nc| Int64| 1| Number of columns in complex response matrix
  resp| Complex{Float64,2}| nr*nc| complex response matrix

PZResp
======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 3, 1, 8
  :delim: |

  c| Float32| 1| damping constant
  np| Int64| 1| number of complex poles
  p| Complex{Float32,1}| np| complex poles vector
  nz| Int64| 1| number of complex zeros
  z| Complex{Float32,1}| nz| complex zeros vector

PZResp64 is identical to PZResp with Float64 values for c, p, z, rather than Float32.

*******************
The Misc Dictionary
*******************
Most compound objects below contain a dictionary (Dict{String,Any}) for
non-essential information in a field named ``:misc``. The tables below describe
how this field is written to disk.

Misc
====
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8

  N, Int64, 1, number of items in dictionary [#]_
  K, (StringVec), 1, dictionary keys
  { , , , for i = 1:N
  c , UInt8, 1, :ref:`Type code <type_codes>` of object i
  o, variable, 1, object i
  } , , ,

.. [#] If ``N == 0``, then N is the only value present.

Dictionary Contents
*******************
These subtables describe how to read the possible data types in a Misc dictionary.

String Array (c == 0x81)
========================
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8

  A, (StringVec), 1, string vector

Other Array (c == 0x80 or c > 0x81)
===================================
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 2, 8

  nd, Int64, 1, number of dimensions in array
  dims, Int64, nd, array dimensions
  arr, varies, prod(nd), array

String (c == 0x01)
==================
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8

  L, Int64, 1, size of string in bytes
  str, UInt8, 1, string

Bits Type (c == 0x00 or 0x01 < c < 0x7f)
========================================
Read a single value whose Type corresponds to the UInt8 :ref:`Type code <type_codes>`.

*********************
Compound Object Types
*********************
Each of these objects contains at least one of the above simple object types.

PhaseCat
========
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8
  :delim: |

  N | Int64 | 1 | number of SeisPha objects to read  [#]_
  K | (StringVec) | 1 | dictionary keys
  pha | (SeisPha) | N | seismic phases

.. [#] If ``N == 0``, then N is the only value present.

EventChannel
============
A single channel of data related to a seismic event

.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8

  Ni, Int64, 1, size of id string in bytes
  id, UInt8, Ni, id string
  Nn, Int64, 1, size of name string in bytes
  name, UInt8, Nn, name string
  Lt, UInt8, 1, :ref:`location Type code<loc_codes>`
  loc, (Loc Type), 1, instrument position
  fs, Float64, 1, sampling frequency in Hz
  gain, Float64, 1, scalar gain
  Rt, UInt8, 1, :ref:`response Type code<resp_codes>`
  resp, (Resp Type), 1, instrument response
  Nu, Int64, 1, size of units string in bytes
  units, UInt8, Nu, units string
  az, Float64, 1, azimuth
  baz, Float64, 1, backazimuth
  dist, Float64, 1, source-receiver distance
  pha, (PhaseCat), 1, phase catalog
  Nr, Int64, 1, size of data source string in bytes
  src, UInt8, Nr, data source string
  misc, (Misc), 1, dictionary for non-essential information
  notes, (StringVec), 1, notes and automated logging
  Nt, Int64, 1, length of time gaps matrix
  T, Int64, 2Nt, time gaps matrix
  Xc, UInt8, 1, :ref:`Type code <type_codes>` of data vector
  Nx, Int64, 1, number of samples in data vector
  X, variable, NX, data vector

SeisChannel
============
A single channel of univariate geophysical data

  .. csv-table::
    :header: Var, Type, N, Meaning
    :widths: 1, 2, 1, 8

    Ni, Int64, 1, size of id string in bytes
    id, UInt8, Ni, id string
    Nn, Int64, 1, size of name string in bytes
    name, UInt8, Nn, name string
    Lt, UInt8, 1, :ref:`location Type code<loc_codes>`
    loc, (Loc Type), 1, instrument position
    fs, Float64, 1, sampling frequency in Hz
    gain, Float64, 1, scalar gain
    Rt, UInt8, 1, :ref:`response Type code<resp_codes>`
    resp, (Resp Type), 1, instrument response
    Nu, Int64, 1, size of units string in bytes
    units, UInt8, Nu, units string
    Nr, Int64, 1, size of data source string in bytes
    src, UInt8, Nr, data source string
    misc, (Misc), 1, dictionary for non-essential information
    notes, (StringVec), 1, notes and automated logging
    Nt, Int64, 1, length of time gaps matrix
    T, Int64, 2Nt, time gaps matrix
    Xc, UInt8, 1, :ref:`Type code <type_codes>` of data vector
    Nx, Int64, 1, number of samples in data vector
    X, variable, NX, data vector

EventTraceData
==============
A multichannel record of time-series data related to a seismic event.

  .. csv-table::
    :header: Var, Type, N, Meaning
    :widths: 1, 2, 1, 8

    N, Int64, 1, number of data channels
    Lc, UInt8, N, :ref:`location Type codes<loc_codes>` for each data channel
    Rc, UInt8, N, :ref:`response Type codes<resp_codes>` for each data channel
    Xc, UInt8, N, data :ref:`Type codes <type_codes>` for each data channel
    cmp, UInt8, 1, are data compressed? (0x01 = yes)
    Nt, Int64, N, number of rows in time gaps matrix for each channel
    Nx, Int64, N, length of data vector for each channel [#]_
    id, (StringVec), 1, channel ids
    name, (StringVec), 1, channel names
    loc, (Loc Type), N, instrument positions
    fs, Float64, N, sampling frequencies of each channel in Hz
    gain, Float64, N, scalar gains of each channel
    resp, (Resp Type), N, instrument responses
    units, (StringVec), 1, units of each channel's data
    az, Float64, N, event azimuth
    baz, Float64, N, backazimuths to event
    dist, Float64, N, source-receiver distances
    pha, (PhaseCat), N, phase catalogs for each channel
    src, (StringVec), 1, data source strings for each channel
    misc, (Misc), N, dictionaries of non-essential information for each channel
    notes, (StringVec), N, notes and automated logging for each channel
    { , , , for i = 1:N
    T, Int64, 2Nt[i], Matrix of time gaps for channel i
    } , , ,
    { , , , for i = 1:N
    X, Xc[i], Nx[i], Data vector i [#]_
    } , , ,

.. [#] If cmp == 0x01, each value in Nx is the number of bytes of compressed data to read; otherwise, this is the number of samples in each channel.
.. [#] If cmp == 0x01, read Nx[i] samples of type UInt8 and pass through lz4 decompression to generate data vector i; else read Nx[i] samples of the type corresponding to code Xc[i].

SeisData
========
A record containing multiple channels of univariate geophysical data.

  .. csv-table::
    :header: Var, Type, N, Meaning
    :widths: 1, 2, 1, 8

    N, Int64, 1, number of data channels
    Lc, UInt8, N, :ref:`location Type codes<loc_codes>` for each data channel
    Rc, UInt8, N, :ref:`response Type codes<resp_codes>` for each data channel
    Xc, UInt8, N, data :ref:`Type codes <type_codes>` for each data channel
    cmp, UInt8, 1, are data compressed? (0x01 = yes)
    Nt, Int64, N, number of rows in time gaps matrix for each channel
    Nx, Int64, N, length of data vector for each channel [#]_
    id, (StringVec), 1, channel ids
    name, (StringVec), 1, channel names
    loc, (Loc Type), N, instrument positions
    fs, Float64, N, sampling frequencies of each channel in Hz
    gain, Float64, N, scalar gains of each channel
    resp, (Resp Type), N, instrument responses
    units, (StringVec), 1, units of each channel's data
    src, (StringVec), 1, data source strings for each channel
    misc, (Misc), N, dictionaries of non-essential information for each channel
    notes, (StringVec), N, notes and automated logging for each channel
    { , , , for i = 1:N
    T, Int64, 2Nt[i], Matrix of time gaps for channel i
    } , , ,
    { , , , for i = 1:N
    X, Xc[i], Nx[i], Data vector i [#]_
    } , , ,

.. [#] If cmp == 0x01, each value in Nx is the number of bytes of compressed data to read; otherwise, this is the number of samples in each channel.
.. [#] If cmp == 0x01, read Nx[i] samples of type UInt8 and pass through lz4 decompression to generate data vector i; else read Nx[i] samples of the type corresponding to code Xc[i].

SeisHdr
=======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 1, 8
  :delim: |

  Li | Int64 | 1 | length of event ID string
  id | UInt8 | Li | event ID string
  iv | UInt8 | 1 | intensity value
  Ls | Int64 | 1 | length of intensity scale string
  isc | UInt8 | Ls | intensity scale string
  loc | (EQLoc) | 1 | earthquake location
  mag | (EQMag) | 1 | earthquake magnitude
  misc | (Misc) | 1 | dictionary containing non-essential information
  notes | (StringVec) | 1 | notes and automated logging
  ot | Int64 | 1 | origin time [#]_
  Lr | Int64 | 1 | length of data source string
  src | UInt8 | Lr | data source string
  Lt | Int64 | 1 | length of event type string
  typ | UInt8 | Lt | event type string

.. [#] Measured from Unix epoch time (1970-01-01T00:00:00Z) in integer microseconds

SeisSrc
=======
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 2, 2, 8
  :delim: |

  Li | Int64 | 1 | length of source id string
  id | UInt8 | Li | id string
  Le | Int64 | 1 | length of event id string
  eid | UInt8 | Le | event id string
  m0 | Float64 | 1 | scalar moment
  Lm | Int64 | 1 | length of moment tensor vector
  mt | Float64 | Lm | moment tensor vector
  Ld | Int64 | 1 | length of moment tensor misfit vector
  dm | Float64 | Ld | moment tensor misfit vector
  np | Int64 | 1 | number of polarities
  gap | Float64 | 1 | max. azimuthal gap
  pad | Int64 | 2 | dimensions of principal axes matrix
  pax | Float64 | pad[1]*pad[2] | principal axes matrix
  pld | Int64 | 2 | dimensions of nodal planes matrix
  planes | Float64 | pld[1]*pld[2] | nodal planes matrix
  Lr | Int64 | 1 | length of data source string
  src | UInt8 | 1 | data source string
  st | (SourceTime) | 1 | source-time description
  misc | (Misc) | 1 | Dictionary containing non-essential information
  notes | (StringVec) | 1 | Notes and automated logging

SeisEvent
=========
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 3, 1, 8
  :delim: |

  hdr | (SeisHdr) | 1 | event header
  source | (SeisSrc) | 1 | event source process
  data | (EventTraceData) | 1 | event trace data


***************
Data Type Codes
***************
Each Type code is written to disk as a UInt8, with the important exception of
SeisIO custom object Type codes (which use UInt32).

.. _loc_codes:

Loc Type Codes
==============

.. csv-table::
  :header: UInt8, Type
  :widths: 1, 2

  0x00, GenLoc
  0x01, GeoLoc
  0x02, UTMLoc
  0x03, XYLoc

.. _resp_codes:

Resp Type Codes
===============

.. csv-table::
  :header: UInt8, Type
  :widths: 1, 2

  0x00, GenResp
  0x01, PZResp
  0x02, PZResp64

.. _type_codes:

Other Type Codes
================
Only the Types below are faithfully preserved in write/read of a :misc field
dictionary; other Types are not written to file and can cause ``wseis`` to
throw errors.

.. csv-table::
  :header: Type, UInt8, Type, UInt8
  :widths: 3, 1, 4, 1
  :delim: |

  Char             |0x00| Array{Char,N}             |0x80
  String           |0x01| Array{String,N}           |0x81
  UInt8            |0x10| Array{UInt8,N}            |0x90
  UInt16           |0x11| Array{UInt16,N}           |0x91
  UInt32           |0x12| Array{UInt32,N}           |0x92
  UInt64           |0x13| Array{UInt64,N}           |0x93
  UInt128          |0x14| Array{UInt128,N}          |0x94
  Int8             |0x20| Array{Int8,N}             |0xa0
  Int16            |0x21| Array{Int16,N}            |0xa1
  Int32            |0x22| Array{Int32,N}            |0xa2
  Int64            |0x23| Array{Int64,N}            |0xa3
  Int128           |0x24| Array{Int128,N}           |0xa4
  Float16          |0x30| Array{Float16,N}          |0xb0
  Float32          |0x31| Array{Float32,N}          |0xb1
  Float64          |0x32| Array{Float64,N}          |0xb2
  Complex{UInt8}   |0x50| Array{Complex{UInt8},N}   |0xd0
  Complex{UInt16}  |0x51| Array{Complex{UInt16},N}  |0xd1
  Complex{UInt32}  |0x52| Array{Complex{UInt32},N}  |0xd2
  Complex{UInt64}  |0x53| Array{Complex{UInt64},N}  |0xd3
  Complex{UInt128} |0x54| Array{Complex{UInt128},N} |0xd4
  Complex{Int8}    |0x60| Array{Complex{Int8},N}    |0xe0
  Complex{Int16}   |0x61| Array{Complex{Int16},N}   |0xe1
  Complex{Int32}   |0x62| Array{Complex{Int32},N}   |0xe2
  Complex{Int64}   |0x63| Array{Complex{Int64},N}   |0xe3
  Complex{Int128}  |0x64| Array{Complex{Int128},N}  |0xe4
  Complex{Float16} |0x70| Array{Complex{Float16},N} |0xf0
  Complex{Float32} |0x71| Array{Complex{Float32},N} |0xf1
  Complex{Float64} |0x72| Array{Complex{Float64},N} |0xf2

.. _object_codes:

SeisIO Object Type codes
************************

.. csv-table::
  :header: UInt32 Code, Object Type
  :widths: 2, 3

  0x20474330, EventChannel
  0x20474331, SeisChannel
  0x20474430, EventTraceData
  0x20474431, SeisData
  0x20495030, GenLoc
  0x20495031, GeoLoc
  0x20495032, UTMLoc
  0x20495033, XYLoc
  0x20495230, GenResp
  0x20495231, PZResp64
  0x20495232, PZResp
  0x20504330, PhaseCat
  0x20534530, SeisEvent
  0x20534830, SeisHdr
  0x20535030, SeisPha
  0x20535330, SeisSrc
  0x20535430, SourceTime
  0x45514c30, EQLoc
  0x45514d30, EQMag

***************************
File Format Version History
***************************
  File format versions <0.50 are no longer supported; please email us if you
  need to read in very old data.

.. csv-table::
  :header: Version, Date, Change
  :delim: ;
  :widths: 5, 12, 55

  0.53; 2019-09-11; removed :i, :o from CoeffResp
  ; ; added :i, :o to MultiStageResp
  0.52; 2019-09-03; added CoeffResp, MultiStageResp
  0.51; 2019-08-01; added :f0 to PZResp, PZResp64
  0.50; 2019-06-05; all custom Types can now use write() directly
  ; ; rewrote how :misc is stored
  ; ; Type codes for :misc changed
  ; ; deprecated BigFloat/BigInt support in :misc
  ; ; :n is no longer stored as a UInt32
  ; ; :x compression no longer automatic
  ; ; :x compression changed from Blosc to lz4
