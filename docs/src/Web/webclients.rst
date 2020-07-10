.. _getdata:

############
Web Services
############

Data requests use ``get_data!`` for FDSN, IRISWS, and IRIS PH5WS data services; for (near)
real-time streaming, see :ref:`SeedLink<seedlink-section>`.

****************
Time-Series Data
****************

.. function:: get_data!(S, method, channels; KWs)
.. function:: S = get_data(method, channels; KWs)

| Retrieve time-series data from a web archive to SeisData structure **S**.
|
| **method**
| **"FDSN"**: :FDSNWS dataselect. Change FDSN servers with keyword
| ``src`` using the :ref:`server list<servers>` (see ``?seis_www``).
| **"IRIS"**: IRISWS timeseries.
| **"PH5"**: PH5WS timeseries.
|
| **channels**
| :ref:`Channels to retrieve<cid>` -- string, string array, or parameter file.
| Type ``?chanspec`` at the Julia prompt for more info.
|

Keywords
========
:ref:`Shared Keywords<dkw>`

| fmt, nd, opts, rad, reg, si, to, v, w, y
|
| **Seismic Processing Keywords**

* ``unscale``: divide gain from data after download
* ``demean``: demean data after download
* ``detrend``: detrend data after download
* ``taper``: taper data after download
* ``ungap``: remove gaps in data after download
* ``rr``: remove seismic instrument response after download

| **Other Keywords**

* ``autoname``: determine file names from channel ID?
* ``msr``: get instrument responses as ``MultiStageResonse``? ("FDSN" only)
* ``s``: start time
* ``t``: termination (end) time
* ``xf``: XML file name for output station XML

Special Behavior
-----------------

1. `autoname=true` attempts to emulate IRISWS channel file naming conventions. For this to work, however, each request must return *exactly one* channel. A wildcard ("*" or "?") in a channel string deactivates ``autoname=true``.
2. Seismic processing keywords follow an order of operations that matches the ordering of the above list.
3. IRISWS requests always remove the stage zero gain on the server side, because the service doesn't include the gain constant in the request. This ensures that `:gain` is accurate in SeisIO.
4. IRISWS requests don't fill `:loc` or `:resp` fields in mini-SEED and don't fill the `:resp` field in SAC. For cross-format consistency, the stage-zero (scalar) gain is removed from any request to IRISWS and the `:gain` field in such channels is 1.0.

Data Formats
------------
SeisIO supports the following data format strings in timeseries web requests, subject to the limitations of the web service:

* "miniseed" or "mseed" for mini-SEED
* "sac" or "sacbl" for binary little-endian SAC
* "geocsv" for two-column (tspair) GeoCSV

****************
Station Metadata
****************

.. function:: FDSNsta!(S, chans, KW)
   :noindex:
.. function:: S = FDSNsta(chans, KW)
   :noindex:

Fill channels `chans` of SeisData structure `S` with information retrieved from
remote station XML files by web query.

:ref:`Shared Keywords<dkw>`

| src, to, v
|
| **Other Keywords**
|

* ``msr``: get instrument responses as ``MultiStageResonse``?
* ``s``: start time
* ``t``: termination (end) time
* ``xf``: XML file name for output station XML


********
Examples
********
Note that the "src" keyword is used by FDSNWS dataselect queries, but not by IRISWS or PH5WS timeseries queries.

1. Download 10 minutes of data from four stations at Mt. St. Helens (WA, USA), delete the low-gain channels, and save as SAC files in the current directory.
::

  S = get_data("FDSN", "CC.VALT, UW.SEP, UW.SHW, UW.HSR", src="IRIS", t=-600)
  S -= "UW.SHW..ELZ"
  S -= "UW.HSR..ELZ"
  writesac(S)

2. Get 5 stations, 2 networks, all channels, last 600 seconds of data at IRIS
::

  CHA = "CC.PALM, UW.HOOD, UW.TIMB, CC.HIYU, UW.TDH"
  TS = u2d(time())
  TT = -600
  S = get_data("FDSN", CHA, src="IRIS", s=TS, t=TT)

3. A request to FDSN Potsdam, time-synchronized, with some verbosity
::

  ts = "2011-03-11T06:00:00"
  te = "2011-03-11T06:05:00"
  R = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s=ts, t=te, v=1, y=true)

4. Get channel information for strain and seismic channels at station PB.B001:
::

  S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")


5. Get trace data from IRISws from ``TS`` to ``TT`` at channels ``CHA``

::

  S = SeisData()
  CHA = "UW.TDH..EHZ, UW.VLL..EHZ, CC.VALT..BHZ"
  TS = u2d(time()-86400)
  TT = 600
  get_data!(S, "IRIS", CHA, s=TS, t=TT)

6. Get synchronized trace data from IRISws with a 55-second timeout on HTTP requests, written directly to disk.
::

  CHA = "UW.TDH..EHZ, UW.VLL..EHZ, CC.VALT..BHZ"
  TS = u2d(time())
  TT = -600
  S = get_data("IRIS", CHA, s=TS, t=TT, y=true, to=55, w=true)

7. Request 10 minutes of continuous vertical-component data from a small May 2016 earthquake swarm at Mt. Hood, OR, USA, and cosine taper after download:
::

  STA = "UW.HOOD.--.BHZ,CC.TIMB.--.EHZ"
  TS = "2016-05-16T14:50:00"; TE = 600
  S = get_data("IRIS", STA, s=TS, t=TE)

8. Grab data from a predetermined time window in two different formats
::

  ts = "2016-03-23T23:10:00"
  te = "2016-03-23T23:17:00"
  S = get_data("IRIS", "CC.JRO..BHZ", s=ts, t=te, fmt="sacbl")
  T = get_data("IRIS", "CC.JRO..BHZ", s=ts, t=te, fmt="miniseed")


************
Bad Requests
************
Failed data requests are saved to special channels whose IDs begin with "XX.FAIL". The HTTP response message is stored as a String in ``:misc["msg"]``; display to STDOUT with ``println(stdout, S.misc[i]["msg"])``.

Unparseable data requests are saved to special channels whose IDs begin with "XX.FMT". The raw response bytes are stored as an Array{UInt8,1} in ``:misc["raw"]`` and can be dumped to file or parsed with external programs as needed.

One special channel is created per bad request.
