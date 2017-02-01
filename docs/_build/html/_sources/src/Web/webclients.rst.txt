###########
Web Clients
###########

Three sets of web clients are included: FDSN, IRIS web services (IRISws), and SeedLink.

*************
Configuration
*************
All web clients are invoked at the command line. Specify channels as a :ref:`string, string array, or parameter file<cid>`; the same channel syntax is expected for all web clients and utilities.

****
FDSN
****
`FDSN <http://www.fdsn.org/>`_ is a global organization that supports seismology research. The FDSN web protocol offers near-real-time access to data from thousands of instruments across the world.

FDSN queries in SeisIO are highly customizable; see :ref:`data keywords list <dkw>` and :ref:`channel id syntax <cid>`.

.. function:: S = FDSNget(C)

Retrieve data from channels ``C`` in a SeisData structure.

.. function:: S = FDSNsta(C)

Retrieve station/channel info for ``C`` in an empty SeisData structure.

.. function:: H = FDSNevq(T)

Multi-server query for event with origin time(s) closest to ``T``. Returns a SeisHdr array. ``T`` should be formatted YYYY-MM-DDThh:mm:ss with times in UTC. Incomplete time queries are read to the nearest fully specified time constraint, e.g., FDSNevq("2001-02-08") returns the nearest event to 2001-02-08T00:00:00 UTC. If no event is found on any server within one day of the specified search time, FDSNevq exits with an error.

Additional arguments can be passed at the command line for finer control; see the :ref:`event keywords <ekw>` list in Appendices.

.. function:: V = FDSNevt(T, C)

Get trace data for the event with origin time nearest ``T`` on channels ``C``. Returns a SeisEvent structure.

****
IRIS
****
Incorporated Research Institutions for Seismology `(IRIS) <http://www.iris.edu/>`_ is a consortium of universities dedicated to the operation of science facilities for the acquisition, management, and distribution of seismological data. IRIS maintains an exhaustive number of data services.


.. function:: S = IRISget(C)

Get near-real-time data from channels in ``C``. ``IRISget`` is a wrapper to the `IRIS timeseries web service <http://service.iris.edu/irisws/timeseries/1/>`_. See :ref:`data keywords list <dkw>` and :ref:`channel id syntax <cid>` for options.


* Trace data are de-meaned and stage zero gains are removed.

* Wildcards in channel IDs aren't allowed.


********
SeedLink
********

`SeedLink <https://www.seiscomp3.org/wiki/doc/applications/seedlink>`_ is a TCP/IP-based data transmission protocol that allows near-real-time access to data from thousands of geophysical monitoring instruments. See :ref:`data keywords list <dkw>` and :ref:`channel id syntax <cid>` for options.

.. function:: SeedLink!(S, C)

Initiate a SeedLink session in DATA mode to feed data from streams ``C`` to SeisData structure ``S``. A handle to the TCP connection is appended to ``S.c``. Data are periodically parsed until the connection is closed. One SeisData object can support multiple connections provided each connection's streams feed different channels.

``close(S.c[i])`` ends a SeedLink connection.

``!deleteat(S.c, i)`` removes a handle to a closed SeedLink connection.

.. function:: S = SeedLink(C)

As above, but a new SeisData object ``S`` is created with a handle to the SeedLink connection in ``S.c[1]``.

.. function:: T = has_sta(C, url)

Check that station identifiers ``C`` exist at ``url``. The syntax of ``C`` can be truncated to network and station ids (NN.SSSSS) or a standard id (NN.SSSSS.LL.CC), but only matches on station and network codes.

``SeedLink!(... f=0x01)`` calls ``has_sta`` before initiating a SeedLink connection.

.. function:: T = has_live_stream(C, url, g=G)

Check that streams with channel identifiers ``C`` have data < ``G`` seconds old at ``url``. Returns a Boolean array with one entry per channel id.

``SeedLink!(... f=0x02)`` calls ``has_live_stream`` before initiating a SeedLink connection.
