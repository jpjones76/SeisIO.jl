******************
:mod:`Web Clients`
******************



SeedLink
########
`SeedLink <https://www.seiscomp3.org/wiki/doc/applications/seedlink>`_ is a TCP/IP-based data transmission protocol. It can be used to receive near-real-time data.


SeedLink client
================
``SeedLink`` is an experimental client for the SeedLink protocol in TIME acquisition mode. A channel list (array of ASCII strings) or config filename (ASCII string) must be passed as the first argument. All other arguments are passed as keywords.


Channel Specification
---------------------
If passing a list of channels as a keyword, construct an array of ASCII strings of the form ["sssss nn", "sssss nn", (etc.)], where nn is the two-letter network code and sssss is the station code.

If using a config file, the expected format is identical to `SLtool <http://ds.iris.edu/ds/nodes/dmc/software/downloads/slinktool/>`_ config files, nn sssss (selectors). Selectors should follow `SeedLink <https://www.seiscomp3.org/wiki/doc/applications/seedlink>`_ specifications, with ? indicating a wildcard; see Examples.


Example
-------
Download a minute of real-time data from stations GPW (Glacier Peak, WA, USA) and MBW (Mt. Baker, WA, USA) to a SeisData object named seis:

::

  sta = ["GPW UW"; "MBW UW"]
  seis = SeedLink(sta, t=60.0)



FDSN
####
`FDSN <http://www.fdsn.org/>`_ is a global organization that supports seismology research. The FDSN web protocol offers near-real-time access to data from thousands of instruments across the world.


FDSN client
===========
``FDSNget`` is a highly customizable wrapper to FDSN services. All arguments to FDSNget are keywords.


Public FDSN servers
--------------------
* IRIS, WA, USA: http://service.iris.edu/fdsnws/

* Réseau Sismologique et Géodesique Français, FR: http://ws.resif.fr/fdsnws/

* Northern California Earthquake Data Center, CA, USA: http://service.ncedc.org/fdsnws/

* GFZ Potsdam, DE: http://geofon.gfz-potsdam.de/fdsnws/


Example
-------
Download 10 minutes of data from 4 stations at Mt. St. Helens (WA, USA), delete the low-gain channels, plot, and save to the current directory:

::

  S = FDSNget(net="CC,UW", sta="SEP,SHW,HSR,VALT", cha="*", t=600)
  S -= "SHW    ELZUW"
  S -= "HSR    ELZUW"
  plotseis(S)
  writesac(S)



IRIS
####
Incorporated Research Institutions for Seismology `(IRIS) <http://www.iris.edu/>`_ is a consortium of universities dedicated to the operation of science facilities for the acquisition, management, and distribution of seismological data. IRIS maintains an exhaustive number of data services.


IRIS Client
===========
``IRISget`` is a wrapper for the `IRIS timeseries web service <http://service.iris.edu/irisws/timeseries/1/>`_. IRISget requires a list of channels (array of ASCII strings) as the first argument; all other arguments are keywords

The channel list should be an array of channel identification strings, formated either "net.sta.chan" or "net_sta_chan" (e.g. ``["UW.HOOD.BHZ"; "CC.TIMB.EHZ"]``). Location codes are not used.


Notes
-----
* Trace data are de-meaned and the stage zero gain is removed; however, instrument response is unchanged.

* The IRIS web server doesn't return station coordinates.

* Wildcards in the channel list are not supported.


Example
-------
Request 10 minutes of continuous data recorded during the May 2016 earthquake swarm at Mt. Hood, OR, USA:

::

  STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"]
  TS = "2016-05-16T14:50:00"; TE = 600
  S = IRISget(STA, s=TS, t=TE)


Web Client Keywords
###################
The SeisIO web clients use a similar set of keywords; a full glossary is provided below. For client-specific keywords, the client(s) that support each keyword are listed in parenthesis.


* ``N`` (SeedLink): Number of 520-byte mini-SEED packets to buffer before calling the parser subroutine. Setting this value too high can make the length of the data returned unreliable.

* ```Q`` (FDSNget, IRISget): Quality. Uses standard `FDSN/IRIS codes <https://ds.iris.edu/ds/nodes/dmc/manuals/breq_fast/#quality-option>`_. ``Q=R`` is not recommended and will not work on some FDSN servers.

* ``loc`` (FDSNget): Location code. Specify wildcard with ``loc=""--"``.

* ``net``, ``sta``, ``cha`` (FDSNget): ASCII strings. Wildcards are OK; specify with "???".

* ``patts`` (SeedLink): Array of selector patterns. Not used if a config file is passed as the first argument.

* ``port`` (SeedLink): Connection port. Defaults to 18000.

* ``s``: Start time. See below for specification and expected argument types.

* ``t``: End time. See below for specification and expected argument types.

* ``to`` (FDSNget, IRISget): Timeout in seconds.

* ``v``: Verbose mode (boolean).

* ``vv``: Very verbose mode (boolean).

* ``y``: Synchronize (boolean).


Time Syntax
===========
The "time" keywords ``s`` and ``t`` can be real numbers, DateTime objects, or ASCII strings. Strings must follow the format ``yyyy-mm-ddTHH:MM:SS``, e.g. ``s="2016-03-23T11:17:00"``.


Time Specification for Backwards Fill
-------------------------------------
Passing an Int or Float64 with keyword `t` sets the mode to backwards fill. Retrieved data begin `t` seconds before `s`.

* ``t`` is interpreted as a *duration in seconds*.

* ``s=0``: Ends at the *start of the current minute* on your system.

* ``s==F``, an Integer or Float64 value: s is treated as *Unix (Epoch) time in seconds*.

* ``s=D``, a DateTime object or ASCIIString value: Backfill *ends* at ``s``.

Time Specification for Range Retrieval
--------------------------------------
Passing a string or DateTime object with keyword ``t`` sets the mode to range retrieval.

* Retrieved data *begin* at ``s`` and *end* at ``t``.

* ``s=D``, a DateTime object or ASCIIString.
