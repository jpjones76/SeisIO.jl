.. _utils:

***********************
:mod:`Utility Programs`
***********************

Event Utilities
===============
The following utilities are for acquisition and storage of discrete event data.

FDSNevq
---
Event query. A fast command-line utility to do a multi-server query for one or more events near an origin time ``t``.  Incomplete string queries are read to the nearest fully specified time constraint, e.g., FDSNevq("2001-02-08") returns the nearest event to 2001-02-08T00:00:00 UTC. If no event is found on any server queried within one day of ``t``, FDSNevq exits with an error.

User-specified parameters (always passed as param=value) can include:

* ``dep``: Depth, specified ``[min_depth max_depth]``, + = down. Default: ``dep=[-30.0 700.0]``

* ``lat``: Latitude, specified ``[min_lat max_lat]``. + = North. Default: ``lat=[-90.0 90.0]``

* ``lon``: Longitude, specified ``[min_lon max_lon]``. + = East. Default: ``lon=[-180.0 180.0]``

* ``mag``: Magnitude, specified ``[min_mag max_mag]``. Default: ``mag=[6.0 9.9]``

* ``n``: Maximum number of events to return. Default: ``n=1``

* ``w``: Maximum time length (in seconds) to search around ``t``. Default: ``w=86400``.

* ``x``: Boolean. Treat ``t`` as exact (within one second). Overrides ``w``. Default: ``x=false``.

* ``to``: Query timeout (in seconds) for each FDSN query. Default: ``to=10``.

* ``src``: Data sources. Specify a comma-delineated list of strings or ``"All"`` to query all (Default: ``src="All"``). Valid sources currently include IRIS (Incorporated Research Institutions for Seismology, WA, USA), RESIF (Réseau sismologique & géodésique français, France), NCEDC (Northern California Earthquake Data Center, CA, USA), and GFZ (GeoForschungsZentrum, Potsdam, Germany).

gcdist
------
Compute great-circle distance between source and receiver(s) by the Haversine formula.

getpha
------
Get phase onset times relative to the origin time of an event.

distaz!
-------
Update SeisEvent object S with distances(in degrees), azimuth, and backazimuth for each channel. Values are saved in S.data.misc["dist"], S.data.misc["az"], and S.data.misc["baz"], respectively.

Miscellaneous
=============
``getbandcode(fs, fc=FC)``: Generate a valid FDSN-compliant one-character band code for data sampled at ``fs``; corner frequency ``FC`` is optional.

``tx = t_expand(t)``: Expand sparse delta-encoded time representation ``t`` to generate time stamps for for each value in the corresponding data ``x``.

``t = t_collapse(tx)``: Collapse time stamp array ``tx`` to sparse delta-encoded time representation ``t``.

``j = md2j(y,m,d)``: Convert month ``m``, day ``d`` of year ``y`` to Julian day (day of year) ``j``. Not included in the Julia DateTime library.

``m,d = j2md(y,j)``: Convert Julian day (day of year) ``j`` of year ``y`` to month ``m``, day ``d``. Not included in the Julia DateTime library.
