***********
:mod:`FDSN`
***********
`FDSN <http://www.fdsn.org/>`_ is a global organization that supports seismology research. The FDSN web protocol offers near-real-time access to data from thousands of instruments across the world.


FDSN clients
============
``FDSNevq`` queries FDSN for events, and, if successful, returns the event headers.

``FDSNevt`` retrieves event headers and data in a user-specified phase window.

``FDSNget`` is a highly customizable wrapper to FDSN data access. All arguments are keywords.

``FDSNsta`` retrieves and parses station information.


Public FDSN servers
--------------------
* IRIS, WA, USA: http://service.iris.edu/fdsnws/

* Réseau Sismologique et Géodesique Français, FR: http://ws.resif.fr/fdsnws/ (data only)

* Northern California Earthquake Data Center, CA, USA: http://service.ncedc.org/fdsnws/

* GFZ Potsdam, DE: http://geofon.gfz-potsdam.de/fdsnws/


Examples
--------
1. ``S = FDSNget(chan_ids, s=TS, t=TE, y=true)``

Retrieve data from ``chan_ids`` from ``TS`` to ``TE`` and synchronize the start and end times of each channel.

2. ``S = FDSNsta(CF)``

Return station/channel info for parameter file (or string) ``CF`` in an empty SeisData structure. `Keywords <dkw>` are identical to ``FDSNget``.

3. ``H = FDSNevq(t)``

Multi-server query for event(s) with origin time(s) closest to ``t``. Format time ``YYYY-MM-DDThh:mm:ss`` in UTC, e.g. ``2001-02-08T18:54:32``. Returns a SeisHdr array. Highly customizable; see `event keywords list <ekw>` for options.

4. ``Evt = FDSNevt(ot, cc)``

Get trace data for the event with the origin time closest to ``ot`` on channels ``cc``.

5.
::
  S = FDSNget("CC.VALT, UW.SEP, UW.SHW, UW.HSR", t=600)
  S -= "SHW.ELZ..UW"
  S -= "HSR.ELZ..UW"
  writesac(S)

Download 10 minutes of data from four stations at Mt. St. Helens (WA, USA), delete the low-gain channels, and save as SAC files in the current directory.


6.
::

  S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
  wseis("201103110547_evt.seis", S)

Get seismic and strainmeter records for the P-wave of the Tohoku-Oki great earthquake on two borehole stations and write to native SeisData format.


Associated Functions
====================
``FDSNevq, FDSNevt, FDSNget, FDSNsta, parsetimewin, minreq!``
