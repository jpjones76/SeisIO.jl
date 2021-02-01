#####
Quake
#####

The Quake submodule was introduced in SeisIO v0.3.0 to isolate handling of discrete earthquake events from handling of continuous geophysical data. While the channel data are similar, fully describing an earthquake event requires many additional Types (objects) and more information (fields) in channel descriptors.

*****
Types
*****
See Type help text for field descriptions and SeisIO behavior.

.. function:: EQMag

Earthquake magnitude object.
:raw-html:`<br /><br />`

.. function:: EQLoc

Structure to hold computed earthquake location data.
:raw-html:`<br /><br />`

.. function:: EventChannel

A single channel of trace data (digital seismograms) associated with a
discrete event (earthquake).
:raw-html:`<br /><br />`

.. function:: EventTraceData

A custom structure designed to describe trace data (digital seismograms)
associated with a discrete event (earthquake).
:raw-html:`<br /><br />`

.. function:: PhaseCat

A seismic phase catalog is a dictionary with phase names for keys (e.g. "pP", "PKP")
and SeisPha objects for values.
:raw-html:`<br /><br />`

.. function:: SeisEvent

A compound Type comprising a SeisHdr (event header), SeisSrc (source process),
and EventTraceData (digital seismograms.)
:raw-html:`<br /><br />`

.. function:: SeisHdr

Earthquake event header object.
:raw-html:`<br /><br />`

.. function:: SeisPha

A description of a seismic phase measured on a data channel.
:raw-html:`<br /><br />`

.. function:: SeisSrc

Seismic source process description.
:raw-html:`<br /><br />`

.. function:: SourceTime

QuakeML-compliant seismic source-time parameterization.


***********
Web Queries
***********
Keyword descriptions for web queries appear at the end of this section.
:raw-html:`<br /><br />`

.. function:: FDSNevq(ot)

Event header query. Multi-server query for the event(s) with origin time(s) closest to `ot`. Returns a tuple consisting of an Array{SeisHdr,1} and an Array{SeisSrc,1}, so that the `i`th entry of each array describes the header and source process of event `i`.

Keywords: evw, mag, nev, rad, reg, src, to, v

Notes
=====

* Specify `ot` as a string formatted YYYY-MM-DDThh:mm:ss in UTC (e.g. "2001-02-08T18:54:32").
* Incomplete string queries are read to the nearest fully-specified time constraint; thus, `FDSNevq("2001-02-08")` returns the nearest event to 2001-02-08T00:00:00.
* If no event is found in the specified search window, FDSNevq exits with an error.
* For FDSNevq, keyword `src` can be a comma-delineated list of sources, provided each has a value in `?seis_www`; for example, ``src="IRIS, INGV, NCEDC"`` is valid.

.. function:: FDSNevt(ot::String, chans::String)

Get header and trace data for the event closest to origin time `ot` on channels
`chans`. Returns a SeisEvent structure.

Keywords: evw, fmt, len, mag, model, nd, opts, pha, rad, reg, src, to, v, w

Notes
=====

* Specify `ot` as a string formatted YYYY-MM-DDThh:mm:ss in UTC (e.g. "2001-02-08T18:54:32").
* Incomplete string queries are read to the nearest fully-specified time constraint; thus, `FDSNevq("2001-02-08")` returns the nearest event to 2001-02-08T00:00:00.
* If no event is found in the specified search window, FDSNevt exits with an error.
* Unlike `FDSNevq`, number of events cannot be specified and `src` must be a single source String in `?seis_www`.

:raw-html:`<br />`

.. function:: get_pha!(S::Data[, keywords])

Command-line interface to IRIS online travel time calculator, which calls TauP. Returns a matrix of strings.

Keywords: pha, model, to, v

References
==========
1. TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf
2. Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit: Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.

Web Query Keywords
==================

+--------+----------------+--------+------------------------------------------+
| KW     | Default        | T [#]_ | Meaning                                  |
+========+================+========+==========================================+
| evw    | [600.0, 600.0] | A{F,1} | search window in seconds [#]_            |
+--------+----------------+--------+------------------------------------------+
| fmt    | "miniseed"     | S      | request data format                      |
+--------+----------------+--------+------------------------------------------+
| len    | 120.0          | I      | desired trace length [s]                 |
+--------+----------------+--------+------------------------------------------+
| mag    | [6.0, 9.9]     | A{F,1} | magnitude range for queries              |
+--------+----------------+--------+------------------------------------------+
| model  | "iasp91"       | S      | Earth velocity model for phase times     |
+--------+----------------+--------+------------------------------------------+
| nd     | 1              | I      | number of days per subrequest            |
+--------+----------------+--------+------------------------------------------+
| nev    | 0              | I      | number of events returned per query [#]_ |
+--------+----------------+--------+------------------------------------------+
| opts   | ""             | S      | user-specified options [#]_              |
+--------+----------------+--------+------------------------------------------+
| pha    | "P"            | S      | phases to get [#]_                       |
+--------+----------------+--------+------------------------------------------+
| rad    | []             | A{F,1} | radial search region [#]_                |
+--------+----------------+--------+------------------------------------------+
| reg    | []             | A{F,1} | rectangular search region [#]_           |
+--------+----------------+--------+------------------------------------------+
| src    | "IRIS"         | S      |  data source; type *?seis_www* for list  |
+--------+----------------+--------+------------------------------------------+
| to     | 30             | I      | read timeout for web requests [s]        |
+--------+----------------+--------+------------------------------------------+
| v      | 0              | I      | verbosity                                |
+--------+----------------+--------+------------------------------------------+
| w      | false          | B      | write requests to disk? [#]_             |
+--------+----------------+--------+------------------------------------------+

.. rubric:: Table Footnotes
.. [#] Types: A = Array, B = Boolean, C = Char, DT = DateTime, F = Float, I = Integer, S = String, U8 = Unsigned 8-bit integer (UInt8)
.. [#] search range is always ``ot-|evw[1]| ≤ t ≤ ot+|evw[2]|``
.. [#] nev=0 returns all events in the query
.. [#] String is passed as-is, e.g. "szsrecs=true&repo=realtime" for FDSN. String should not begin with an ampersand.
.. [#] Comma-separated String, like `"P, pP"`; use `"ttall"` for all phases
.. [#] Specify region **[center_lat, center_lon, min_radius, max_radius, dep_min, dep_max]**, with lat, lon, and radius in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] Specify region **[lat_min, lat_max, lon_min, lon_max, dep_min, dep_max]**, with lat, lon in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] If **w=true**, a file name is automatically generated from the request parameters, in addition to parsing data to a SeisData structure. Files are created from the raw download even if data processing fails, in contrast to get_data(... wsac=true).

Example
=======
Get seismic and strainmeter records for the P-wave of the Tohoku-Oki great earthquake on two borehole stations and write to native SeisData format:
::

  S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
  wseis("201103110547_evt.seis", S)

Utility Functions
=================

.. function:: distaz!(Ev::SeisEvent)

Compute distance, azimuth, and backazimuth by the Haversine formula.
Overwrites Ev.data.dist, Ev.data.az, and Ev.data.baz.
:raw-html:`<br /><br />`

.. function:: gcdist([lat_src, lon_src], rec)

Compute great circle distance, azimuth, and backazimuth from a single source
with coordinates `[s_lat, s_lon]` to receivers `rec` with coordinates
`[r_lat r_lon]` in each row.
:raw-html:`<br /><br />`

.. function:: show_phases(P::PhaseCat)

Formatted display of seismic phases in dictionary P.

.. function:: fill_sac_evh!(Ev::SeisEvent, fname[; k=N])

Fill (overwrite) values in *Ev.hdr* with data from SAC file *fname*. Keyword
*k=i* specifies the reference channel *i* from which the absolute origin time
*Ev.hdr.ot* is set. Potentially affects header fields *:id*, *:loc* (subfields
.lat, .lon, .dep only), and *:ot*.

*****************************
Reading Earthquake Data Files
*****************************
.. function:: S = read_quake(fmt::String, filename [, KWs])

| Read data in file *fmt* from file *filename* into memory.
|
| **fmt**
| Case-sensitive string describing the file format. See below.
|
| **KWs**
| Keyword arguments; see also :ref:`SeisIO standard KWs<dkw>` or type ``?SeisIO.KW``.
| Standard keywords: full, nx_add, nx_new, v
| Other keywords: See below.

Supported File Formats
======================
.. csv-table::
  :header: File Format, String, Notes
  :delim: |
  :widths: 1, 1, 3

  PC-SUDS     | suds            |
  QuakeML     | qml, quakeml    | only reads first event from file
  UW          | uw              |

******************
Supported Keywords
******************

.. csv-table::
  :header: KW, Used By, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 1, 2

  full    | suds, uw  | Bool    | false     | read full header into *:misc*?
  v       | all       | Integer | 0         | verbosity

QuakeML
=======

.. function:: read_qml(fpat::String)

Read QuakeML files matching string pattern **fpat**. Returns a tuple containing an array of **SeisHdr** objects **H** and an array of **SeisSrc** objects **R**. Each pair (H[i], R[i]) describes the preferred location (origin, SeisHdr) and event source (focal mechanism or moment tensor, SeisSrc) of event **i**.

If multiple focal mechanisms, locations, or magnitudes are present in a single Event element of the XML file(s), the following rules are used to select one of each per event:

| **FocalMechanism**
|   1. **preferredFocalMechanismID** if present
|   2. Solution with best-fitting moment tensor
|   3. First **FocalMechanism** element
|
| **Magnitude**
|   1. **preferredMagnitudeID** if present
|   2. Magnitude whose ID matches **MomentTensor/derivedOriginID**
|   3. Last moment magnitude (lowercase scale name begins with "mw")
|   4. First **Magnitude** element
|
| **Origin**
|   1. **preferredOriginID** if present
|   2. **derivedOriginID** from the chosen **MomentTensor** element
|   3. First **Origin** element

Non-essential QuakeML data are saved to `misc` in each SeisHdr or SeisSrc object as appropriate.
:raw-html:`<br /><br />`

.. function:: write_qml(fname, Ev::SeisEvent; v::Integer=0)
   :noindex:

See :ref:`writing<write>`.
