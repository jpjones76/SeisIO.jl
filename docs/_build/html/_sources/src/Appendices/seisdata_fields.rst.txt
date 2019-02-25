..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>

################################
Structure and Field Descriptions
################################

.. _sdf:

******************
SeisChannel Fields
******************

+-------+---------------------+---------------------------------------+
| Name  | Type                | Meaning                               |
+=======+=====================+=======================================+
| id    | String              | unique channel ID formatted           |
|       |                     | :ref:`net.sta.loc.cha <cid>`          |
+-------+---------------------+---------------------------------------+
| name  | String              | freeform channel name string          |
+-------+---------------------+---------------------------------------+
| src   | String              | description of data source            |
+-------+---------------------+---------------------------------------+
| units | String              | units of dependent variable [#]_      |
+-------+---------------------+---------------------------------------+
| fs    | Float64             | sampling frequency in Hz              |
+-------+---------------------+---------------------------------------+
| gain  | Float64             | scalar to convert x to SI units in    |
|       |                     | flat part of power spectrum [#]_      |
+-------+---------------------+---------------------------------------+
| loc   | Array{Float64,1}    | sensor location: [lat, lon, ele, az,  |
|       |                     | inc] [#]_                             |
+-------+---------------------+---------------------------------------+
| resp  | Array{Complex       | complex instrument response [#]_      |
|       | {Float64},2}        |                                       |
+-------+---------------------+---------------------------------------+
| misc  | Dict{String,Any}    | miscellaneous information [#]_        |
+-------+---------------------+---------------------------------------+
| notes | Array{String,1}     | timestamped notes                     |
+-------+---------------------+---------------------------------------+
| t     | Array{Int64,2}      | time gaps                             |
|       |                     | :ref:`(see below) <seisdata_t>`       |
+-------+---------------------+---------------------------------------+
| x     | Array{Float64,1}    | univariate data                       |
+-------+---------------------+---------------------------------------+

.. rubric:: Table Footnotes
.. [#] Use `UCUM-compliant abbreviations <http://unitsofmeasure.org/trac>`_ wherever possible.
.. [#] Gain has an identical meaning to the "Stage 0 gain" of FDSN XML.
.. [#] Azimuth is measured clockwise from North; incidence of 0° = vertical; both use degrees.
.. [#] Zeros in ``:resp[i][:,1]``, poles in ``:resp[i][:,2]``.
.. [#] Arrays in ``:misc`` should each contain a single Type (e.g. Array{Float64,1}, never Array{Any,1}). See the :ref:`SeisIO file format description<smt>` for a full list of allowed value types in :misc.

******************
SeisData Fields
******************
As SeisChannel, plus

+-------+---------------------+---------------------------------------+
| Name  | Type                | Meaning                               |
+=======+=====================+=======================================+
| n     | Int64               | number of channels                    |
+-------+---------------------+---------------------------------------+
| c     | Array{TCPSocket,1}  | array of TCP connections              |
+-------+---------------------+---------------------------------------+

Time Convention
---------------

.. _seisdata_t:

The units of ``t`` are *integer microseconds*, measured from Unix epoch time
(1970-01-01T00:00:00.000).

For *regularly sampled* data (``fs > 0.0``), each ``t`` is a sparse
delta-compressed representation of *time gaps* in the corresponding ``x``.
The first column stores indices of gaps; the second, gap lengths.

Within each time field, ``t[1,2]`` stores the time of the first sample of the
corresponding ``x``. The last row of each ``t`` should always take the form `
`[length(x) 0]``. Other rows take the form ``[(starting index of gap) (length of gap)]``.

For *irregularly sampled data* (``fs = 0``), ``t[:,2]`` is a dense
representation of *time stamps for each sample*.


******************
SeisHdr Fields
******************
+-------+------------------------+--------------------------------------+
| Name  | Type                   | Meaning                              |
+=======+========================+======================================+
| id    | Int64                  | numeric event ID                     |
+-------+------------------------+--------------------------------------+
| ot    | DateTime               | origin time                          |
+-------+------------------------+--------------------------------------+
| loc   | Array{Float64, 1}      | hypocenter                           |
+-------+------------------------+--------------------------------------+
| mag   | Tuple{Float32, String} | magnitude, scale                     |
+-------+------------------------+--------------------------------------+
| int   | Tuple{UInt8, String}   | intensity, scale                     |
+-------+------------------------+--------------------------------------+
| mt    | Array{Float64, 1}      | moment tensor: (1-6) tensor,         |
|       |                        | (7) scalar moment, (8) \%dc          |
+-------+------------------------+--------------------------------------+
| np    | Array{Tuple{Float64,   | nodal planes                         |
|       | Float64, Float64},1}   |                                      |
+-------+------------------------+--------------------------------------+
| pax   | Array{Tuple{Float64,   | principal axes, ordered P, T, N      |
|       | Float64, Float64},1}   |                                      |
+-------+------------------------+--------------------------------------+
| src   | String                 | data source (e.g. url/filename)      |
+-------+------------------------+--------------------------------------+

******************
SeisEvent Fields
******************
+-------+------------------------+--------------------------------------+
| Name  | Type                   | Meaning                              |
+=======+========================+======================================+
| hdr   | SeisHdr                | event header                         |
+-------+------------------------+--------------------------------------+
| data  | SeisData               | event data                           |
+-------+------------------------+--------------------------------------+
