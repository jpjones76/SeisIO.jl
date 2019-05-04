.. _getdata:

************
Web Requests
************

Data requests use ``get_data!`` for FDSN or IRIS data services; for (near)
real-time streaming, see :ref:`SeedLink<seedlink-section>`.

.. function:: get_data!(S, method, channels; KWs)
.. function:: S = get_data(method, channels; KWs)

| Retrieve time-series data from a web archive to SeisData structure **S**.
|
| **method**
| **"IRIS"**: :ref:`IRISWS<IRISWS>`.
| **"FDSN"**: :ref:`FDSNWS dataselect<FDSNWS>`. Change FDSN servers with keyword ``--src`` using the :ref:`server list<servers>` (also available by typing ``?seis_www``).
|
| **channels**
| Channels to retrieve; can be passed as a :ref:`string, string array, or parameter file<cid>`. Type ``?chanspec`` at the Julia prompt for more info.
|
| **KWs**
| Keyword arguments; see also :ref:`SeisIO standard KWs<dkw>` or type ``?SeisIO.KW``.
| Standard keywords: fmt, nd, opts, rad, reg, si, to, v, w, y
| Other keywords:
| ``--s``: Start time
| ``--t``: Termination (end) time

Examples
========

1. ``get_data!(S, "FDSN", "UW.SEP..EHZ,UW.SHW..EHZ,UW.HSR..EHZ", "IRIS", t=(-600))``: using FDSNWS, get the last 10 minutes of data from three short-period vertical-component channels at Mt. St. Helens, USA.
2. ``get_data!(S, "IRIS", "CC.PALM..EHN", "IRIS", t=(-120), f="sacbl")``: using IRISWS, fetch the last two minutes of data from component EHN, station PALM (Palmer Lift (Mt. Hood), OR, USA,), network CC (USGS Cascade Volcano Observatory, Vancouver, WA, USA), in bigendian SAC format, and merge into SeisData structure `S`.
3. ``get_data!(S, "FDSN", "CC.TIMB..EHZ", "IRIS", t=(-600), w=true)``: using FDSNWS, get the last 10 minutes of data from channel EHZ, station TIMB (Timberline Lodge, OR, USA), save the data directly to disk, and add it to SeisData structure `S`.
4. ``S = get_data("FDSN", "HV.MOKD..HHZ", "IRIS", s="2012-01-01T00:00:00", t=(-3600))``: using FDSNWS, fill a new SeisData structure `S` with an hour of data ending at 2012-01-01, 00:00:00 UTC, from HV.MOKD..HHZ (USGS Hawai'i Volcano Observatory).


FDSN Queries
============

.. _FDSNWS:

`The International Federation of Digital Seismograph Networks (FDSN) <http://www.fdsn.org/>`_ is a global organization that supports seismology research. The FDSN web protocol offers near-real-time access to data from thousands of instruments across the world.

FDSN queries in SeisIO are highly customizable; see :ref:`data keywords list <dkw>` and :ref:`channel id syntax <cid>`.


Data Query
**********
.. function:: get_data!(S, "FDSN", channels; KWs)
   :noindex:
.. function:: S = get_data("FDSN", channels; KWs)
   :noindex:

FDSN data query with get_data! wrapper.

| :ref:`Shared keywords<dkw>`: fmt, nd, opts, rad, reg, s, si, t, to, v, w, y
| Other keywords:
| ``--s``: Start time
| ``--t``: Termination (end) time
| ``xml_file``: Name of XML file to save station metadata

Station Query
*************
.. function:: FDSNsta!(S, chans, KW)
   :noindex:
.. function:: S = FDSNsta(chans, KW)
   :noindex:

Fill channels `chans` of SeisData structure `S` with information retrieved from
remote station XML files by web query.

| :ref:`Shared keywords<dkw>`: src, to, v
| Other keywords:
| ``--s``: Start time
| ``--t``: Termination (end) time

Event Header Query
******************
.. function:: H = FDSNevq(ot)
   :noindex:

:ref:`Shared keywords<dkw>`: evw, rad, reg, mag, nev, src, to, v, w

Multi-server query for the event(s) with origin time(s) closest to `ot`. Returns
a SeisHdr.

Notes:

1. Specify `ot` as a string formatted YYYY-MM-DDThh:mm:ss in UTC (e.g. "2001-02-08T18:54:32"). Returns a SeisHdr array.
2. Incomplete string queries are read to the nearest fully-specified time constraint; thus, `FDSNevq("2001-02-08")` returns the nearest event to 2001-02-08T00:00:00.
3. If no event is found in the specified search window, FDSNevq exits with an error.

| :ref:`Shared keywords<dkw>`: evw, reg, mag, nev, src, to, w

Event Header and Data Query
***************************
.. function:: Ev = FDSNevt(ot::String, chans::String)

Get trace data for the event closest to origin time `ot` on channels `chans`.
Returns a SeisEvent.

| :ref:`Shared keywords<dkw>`: fmt, mag, nd, opts, pha, rad, reg, src, to, v, w
| Other keywords:
| ``--len``: desired record length *in minutes*.


IRIS Queries
============

.. _IRISWS:

Incorporated Research Institutions for Seismology `(IRIS) <http://www.iris.edu/>`_ is a consortium of universities dedicated to the operation of science facilities for the acquisition, management, and distribution of seismological data.

Data Query Features
*******************
* Stage zero gains are removed from trace data; all IRIS data will appear to have a gain of 1.0.
* IRISWS disallows wildcards in channel IDs.
* Channel spec *must* include the net, sta, cha fields; thus, CHA = "CC.VALT..BHZ" is OK; CHA = "CC.VALT" is not.

Phase Onset Query
*****************
.. function: get_pha(Δ::Float64, z::Float64)

Command-line interface to IRIS online travel time calculator, which calls TauP [1-2]. Returns a matrix of strings.

Specify Δ in decimal degrees, z in km with + = down.

| Shared keywords keywords: pha, to, v
| Other keywords:
| ``-model``: velocity model (defaults to "iasp91")

**References**

* Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit: Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.
* TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf
