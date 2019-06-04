#####
Quake
#####

The Quake submodule (accessed with "using SeisIO.Quake") was introduced in
SeisIO v0.3.0 to isolate handling of discrete earthquake events from handling
of continuous geophysical data. While the channel data are similar, fully
describing an earthquake event requires many additional Types (objects) and
more information (fields) in channel descriptors.

*****
Types
*****
See Type help text for field descriptions and SeisIO behavior.

.. function:: EQMag

Earthquake magnitude object.

.. function:: EQLoc

Computed earthquake location.

.. function:: EventChannel

A single channel of trace data (digital seismograms) associated with a
discrete event (earthquake).

.. function:: EventTraceData

A custom structure designed to describe trace data (digital seismograms)
associated with a discrete event (earthquake).

.. function:: PhaseCat

A seismic phase catalog is a dictionary with phase names for keys (e.g. "pP", "PKP")
and SeisPha objects for values.

.. function:: SeisEvent

A compound Type comprising a SeisHdr (event header), SeisSrc (source process),
and EventTraceData (digital seismograms.)

.. function:: SeisHdr

Earthquake event header object.

.. function:: SeisPha

A description of a seismic phase measured on a data channel.

.. function:: SeisSrc

Seismic source process description.

.. function:: SourceTime

QuakeML-compliant seismic source-time parameterization.


***********
Web Queries
***********

Event Header Query
******************
.. function:: FDSNevq(ot)
   :noindex:

:ref:`Shared keywords<dkw>`: evw, rad, reg, mag, nev, src, to, v, w

Multi-server query for the event(s) with origin time(s) closest to `ot`. Returns
a tuple consisting of an Array{SeisHdr,1} and an Array{SeisSrc,1}, so that
the `i`th entry of each array describes the header and source process of event `i`.

Notes:

1. Specify `ot` as a string formatted YYYY-MM-DDThh:mm:ss in UTC (e.g. "2001-02-08T18:54:32"). Returns a SeisHdr array.
2. Incomplete string queries are read to the nearest fully-specified time constraint; thus, `FDSNevq("2001-02-08")` returns the nearest event to 2001-02-08T00:00:00.
3. If no event is found in the specified search window, FDSNevq exits with an error.

| :ref:`Shared keywords<dkw>`: evw, reg, mag, nev, src, to, w

Event Header and Data Query
***************************
.. function:: FDSNevt(ot::String, chans::String)

Get trace data for the event closest to origin time `ot` on channels `chans`.
Returns a SeisEvent.

| :ref:`Shared keywords<dkw>`: fmt, mag, nd, opts, pha, rad, reg, src, to, v, w
| Other keywords:
| ``--len``: desired record length *in minutes*.

Phase Onset Query
*****************
.. function:: get_pha(Δ::Float64, z::Float64)

Command-line interface to IRIS online implementation of the TauP travel time
calculator [1-2]. Returns a matrix of strings. Specify Δ in decimal degrees
and z in km with + = down.

| Shared keywords keywords: pha, to, v
| Other keywords:
| ``-model``: velocity model (defaults to "iasp91")

**References**

* Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit: Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.
* TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf

**************
QuakeML Reader
**************

.. function:: read_qml(fpat::String)

Read QuakeML files matching string pattern `fpat`. Returns a tuple containing
an array of `SeisHdr` objects and an array of `SeisSrc` objects, such that the
`i`th entry of each array is the preferred location (origin) and event source
(focal mechanism or moment tensor) of event `i`.

If multiple focal mechanisms, locations, or magnitudes are present in a single
Event element of the XML file(s), the following rules are used to select one of
each per event:

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

Non-essential QuakeML data are saved to `misc` in each SeisHdr or SeisSrc object
as appropriate.

************
File Readers
************

.. function:: uwpf(pf[, v])

Read UW-format seismic pick file `pf`. Returns a tuple of (SeisHdr, SeisSrc).

.. function:: uwpf!(W, pf[, v::Int64=KW.v])

Read UW-format seismic pick info from pickfile `f` into SeisEvent object `W`.
Overwrites W.source and W.hdr with pickfile information. Keyword `v` controls
verbosity.

.. function:: readuwevt(fpat)

 Read University of Washington-format event data with file pattern stub fpat
 into a SeisEvent object. ``fpat`` can be a datafile name, a pickfile name, or
 a stub.


*****************
Utility Functions
*****************

.. function:: distaz!(Ev::SeisEvent)

Compute distnace, azimuth, and backazimuth by the Haversine formula.
Overwrites Ev.data.dist, Ev.data.az, and Ev.data.baz.

.. function:: gcdist([lat_src, lon_src], rec)

Compute great circle distance, azimuth, and backazimuth from a single source
with coordinates `[s_lat, s_lon]` to receivers `rec` with coordinates
`[r_lat r_lon]` in each row.

.. function:: show_phases(P::PhaseCat)

Formatted display of seismic phases in dictionary P.
