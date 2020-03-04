  .. _dkw:

########################
SeisIO Standard Keywords
########################

SeisIO.KW is a memory-resident structure of default values for common keywords
used by package functions. KW has one substructure, SL, with keywords specific
to SeedLink. These defaults can be modified, e.g., SeisIO.KW.nev=2 changes the
default for nev to 2.

+--------+----------------+--------+------------------------------------------+
| KW     | Default        | T [#]_ | Meaning                                  |
+========+================+========+==========================================+
| comp   | 0x00           | U8     |  compress data on write? [#]_            |
+--------+----------------+--------+------------------------------------------+
| fmt    | "miniseed"     | S      | request data format                      |
+--------+----------------+--------+------------------------------------------+
| mag    | [6.0, 9.9]     | A{F,1} | magnitude range for queries              |
+--------+----------------+--------+------------------------------------------+
| n_zip  | 100000         | I      | compress if length(:x) > n_zip           |
+--------+----------------+--------+------------------------------------------+
| nd     | 1              | I      | number of days per subrequest            |
+--------+----------------+--------+------------------------------------------+
| nev    | 1              | I      | number of events returned per query      |
+--------+----------------+--------+------------------------------------------+
| nx_add | 360000         | I      | length increase of undersized data array |
+--------+----------------+--------+------------------------------------------+
| nx_new | 8640000        | I      | number of samples for a new channel      |
+--------+----------------+--------+------------------------------------------+
| opts   | ""             | S      | user-specified options [#]_              |
+--------+----------------+--------+------------------------------------------+
| prune  | true           | B      | call prune! after get_data?              |
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
| w      | false          | B      | write requests to disk? [#]_             |
+--------+----------------+--------+------------------------------------------+
| y      | false          | B      | sync data after web request?             |
+--------+----------------+--------+------------------------------------------+


.. rubric:: Table Footnotes
.. [#] Types: A = Array, B = Boolean, C = Char, DT = DateTime, F = Float, I = Integer, R = Real, S = String, U8 = Unsigned 8-bit integer
.. [#] If KW.comp == 0x00, never compress data; if KW.comp == 0x01, only compress channel *i* if *length(S.x[i]) > KW.n_zip*; if comp == 0x02, always compress data.
.. [#] String is passed as-is, e.g. "szsrecs=true&repo=realtime" for FDSN. String should not begin with an ampersand.
.. [#] Specify region **[center_lat, center_lon, min_radius, max_radius, dep_min, dep_max]**, with lat, lon, and radius in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] Specify region **[lat_min, lat_max, lon_min, lon_max, dep_min, dep_max]**, with lat, lon in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
.. [#] FDSNWS timeseries only.
.. [#] If **w=true**, a file name is automatically generated from the request parameters, in addition to parsing data to a SeisData structure. Files are created from the raw download even if data processing fails, in contrast to get_data(... wsac=true).
