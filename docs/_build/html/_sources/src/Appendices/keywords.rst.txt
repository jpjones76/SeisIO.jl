.. _dkw:

************************
SeisIO Standard Keywords
************************

SeisIO.KW is a memory-resident structure of default values for common keywords
used by package functions. KW has one substructure, SL, with keywords specific
to SeedLink. These defaults current cannot be modified, but this may change
as the Julia language matures.

+--------+----------------+--------+------------------------------------------+
| KW     | Default        | T [#]_ | Meaning                                  |
+========+================+========+==========================================+
| evw    | [600.0, 600.0] | A{F,1} | time search window [o-evw[1], o+evw[2]]  |
+--------+----------------+--------+------------------------------------------+
| fmt    | "miniseed"     | S      | request data format                      |
+--------+----------------+--------+------------------------------------------+
| mag    | [6.0, 9.9]     | A{F,1} | magnitude range for queries              |
+--------+----------------+--------+------------------------------------------+
| nd     | 1              | I      | number of days per subrequest            |
+--------+----------------+--------+------------------------------------------+
| nev    | 1              | I      | number of events returned per query      |
+--------+----------------+--------+------------------------------------------+
| opts   | ""             | S      | user-specified options [#]_              |
+--------+----------------+--------+------------------------------------------+
| pha    | "P"            | S      | seismic phase arrival times to retrieve  |
+--------+----------------+--------+------------------------------------------+
| rad    | []             | A{F,1} | radial search region [#]_                |
+--------+----------------+--------+------------------------------------------+
| reg    | []             | A{F,1} | rectangular search region [#]_           |
+--------+----------------+--------+------------------------------------------+
| si     | true           | B      | autofill station info on data req? [#]_  |
+--------+----------------+--------+------------------------------------------+
| to     | 30             | I      | read timeout for web requests (s)        |
+--------+----------------+--------+------------------------------------------+
| v      | 0              | I      | verbosity                                |
+--------+----------------+--------+------------------------------------------+
| w      | false          | B      | write requests to disc? [#]_             |
+--------+----------------+--------+------------------------------------------+
| y      | false          | B      | sync data after web request? [#]_        |
+--------+----------------+--------+------------------------------------------+


.. rubric:: Table Footnotes
.. [#] Types: A = Array, B = Boolean, C = Char, DT = DateTime, F = Float, I = Integer, R = Real, S = String, U8 = Unsigned 8-bit integer
.. [#] String is passed as-is, e.g. "szsrecs=true&repo=realtime" for FDSN. String should not begin with an ampersand.
.. [#] Specify region **[center_lat, center_lon, min_radius, max_radius, dep_min, dep_max]**, with lat, lon, and radius in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] Specify region **[lat_min, lat_max, lon_min, lon_max, dep_min, dep_max]**, with lat, lon in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] Not used with IRISWS.
.. [#] **-v=0** = quiet; 1 = verbose, 2 = debug; 3 = verbose debug
.. [#] If **-w=true**, a file name is automatically generated from the request parameters, in addition to parsing data to a SeisData structure. Files are created from the raw download even if data processing fails, in contrast to get_data(... wsac=true).

SeedLink Keywords
-----------------
.. csv-table::
  :header: kw, def, type, meaning
  :delim: ;
  :widths: 8, 8, 8, 24

  gap; 3600; R; a stream with no data in >gap seconds is considered offline
  kai; 600; R; keepalive interval (s)
  mode; \"DATA\"; I; \"TIME\", \"DATA\", or \"FETCH\"
  port; 18000; I; port number
  refresh; 20; R; base refresh interval (s) [#]_
  x\_on\_err; true; Bool; exit on error?

.. rubric:: Table Footnotes

.. [#] This value is modified slightly by each SeedLink session to minimize the risk of congestion
