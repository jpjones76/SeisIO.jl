***********
:mod:`IRIS`
***********
Incorporated Research Institutions for Seismology `(IRIS) <http://www.iris.edu/>`_ is a consortium of universities dedicated to the operation of science facilities for the acquisition, management, and distribution of seismological data. IRIS maintains an exhaustive number of data services. SeisIO has CLI functions for a few.

``S = IRISget(chanlist)``

Get (up to) the last hour of IRIS near-real-time data from every channel in chanlist.

``S = IRISget(chanlist, s=TS, t=TE)``

Get synchronized trace data from the IRIS http server from ``TS`` to ``TE``.

``S = IRISget(chanlist, s=TS, t=TE, y=false, vto=5, w=true)``

Get desynchronized trace data from IRIS http server with a 5-second timeout on HTTP requests, written directly to disk.

IRIS Client
===========
``IRISget`` is a wrapper for the `IRIS timeseries web service <http://service.iris.edu/irisws/timeseries/1/>`_. IRISget requires a list of channels (array of ASCII strings) as the first argument; all other arguments are :ref:`keywords <web_client_keywords>`

The channel list should be an array of channel identification strings, formated either "net.sta.chan" or "net_sta_chan" (e.g. ``["UW.HOOD.BHZ", "CC.TIMB.EHZ"]``).

Notes
-----
* Trace data are de-meaned and stage zero gains are removed.

* Station coordinates aren't returned.

* Wildcards in channel IDs aren't allowed.


Example
-------
Request 10 minutes of continuous vertical-component data from a small May 2016 earthquake swarm at Mt. Hood, OR, USA:

::

  STA = "UW.HOOD.--.BHZ,CC.TIMB.--.EHZ"
  TS = "2016-05-16T14:50:00"; TE = 600
  S = IRISget(STA, s=TS, t=TE)

Associated Functions
====================
``IRISget, irisws, parsetimewin``

.. _web_client_keywords:
