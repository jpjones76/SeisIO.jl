.. _seisio_file_format:

********************
SeisIO Write Formats
********************
Files are written in little-endian byte order. Abbreviations used:

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

SeisIO File
===========

.. csv-table::
  :header: Var, Meaning, T, N
  :widths: 5, 32, 5, 5

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
  :widths: 1, 1, 1, 8

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
  :widths: 1, 1, 1, 8

  A, (StringVec), 1, string vector

Other Array (c == 0x80 or c > 0x81)
===================================
.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8

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
  K, (StringVec), 1, dictionary keys
  pha, (SeisPha), N, seismic phases

.. [#] If ``N == 0``, then N is the only value present.

EventChannel
============
A single channel of data related to a seismic event

.. csv-table::
  :header: Var, Type, N, Meaning
  :widths: 1, 1, 1, 8

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
  T, Int64, 2*Nt, time gaps matrix
  Xc, UInt8, 1, :ref:`Type code <type_codes>` of data vector
  Nx, Int64, 1, number of samples in data vector
  X, variable, NX, data vector

SeisChannel
============
A single channel of univariate geophysical data

  .. csv-table::
    :header: Var, Type, N, Meaning
    :widths: 1, 1, 1, 8

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
    T, Int64, 2*Nt, time gaps matrix
    Xc, UInt8, 1, :ref:`Type code <type_codes>` of data vector
    Nx, Int64, 1, number of samples in data vector
    X, variable, NX, data vector

EventTraceData
==============
A multichannel record of time-series data related to a seismic event.

  .. csv-table::
    :header: Var, Type, N, Meaning
    :widths: 1, 1, 1, 8

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
    T, Int64, 2*Nt[i], Matrix of time gaps for channel i
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
    :widths: 1, 1, 1, 8

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
    T, Int64, 2*Nt[i], Matrix of time gaps for channel i
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
  :widths: 1, 2, 1, 8
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
