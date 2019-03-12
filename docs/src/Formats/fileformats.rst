############
File Formats
############

Current format support: (e = endianness; B = big, l = little, * = either)

+----------+---+---------------+---------------------------+
| Format   | e | Command       | Creates/modifies          |
+==========+===+===============+===========================+
| miniSEED | B | readmseed!    | existing SeisData         |
+----------+---+---------------+---------------------------+
|          | B | readmseed     | new SeisData              |
+----------+---+---------------+---------------------------+
| SAC      | \*| readsac       | new SeisData              |
+----------+---+---------------+---------------------------+
|          | \*| sachdr        | dumps header to stdout    |
+----------+---+---------------+---------------------------+
|          | l | writesac      | sac files on disk         |
+----------+---+---------------+---------------------------+
| SEG Y    | B | readsegy (a)  | new SeisData              |
+----------+---+---------------+---------------------------+
|          | B | segyhdr       | dumps header to stdout    |
+----------+---+---------------+---------------------------+
| UW       | B | readuw        | new SeisEvent             |
+----------+---+---------------+---------------------------+
|          | B | uwpf!         | existing SeisEvent        |
+----------+---+---------------+---------------------------+
|          | B | uwpf          | new SeisHdr               |
+----------+---+---------------+---------------------------+
|          | B | uwdf          | new SeisData              |
+----------+---+---------------+---------------------------+
| win32    | B | readwin32!    | existing SeisData         |
+----------+---+---------------+---------------------------+
|          | B | readwin32     | new SeisData              |
+----------+---+---------------+---------------------------+

(a) Use keyword PASSCAL=true for PASSCAL SEG Y.

*******************
Format Descriptions
*******************

**miniSEED**: SEED stands for Standard for the Exchange of Earthquake Data; the data format is used by FDSN as a universal omnibus-type standard for seismic data. miniSEED is a data-only format with a limited number of blockette types. [#]_

**SAC**: widely-used data format developed for the Seismic Analysis Code interpreter, supported in virtually every programming language. [#]_ [#]_ [#]_

**SEG Y**: standard energy industry seismic data format, developed and maintained by the Society for Exploration Geophysicists\ :sup:`(a)` [#]_ A single-channel SEG Y variant format, referred to here as "PASSCAL SEG Y" was developed by PASSCAL/New Mexico Tech and is used with PASSCAL field equipment. [#]_

**UW**: the University of Washington data format was designed for event archival. A UW event is described by a pickfile and a corresponding data file, whose names are identical except for the last character, e.g. 99062109485o, 99062109485W.\ :sup:`(b)`

**Win32** : data format developed by the NIED (National Research Institute for Earth Science and Disaster Prevention), Japan. Data are typically divided into files that contain a minute of continuous data from channels on a single network or subnet. Data within each file are stored by channel in 1s segments as variable-precision integers. Channel information for each stream is retrieved from an external channel information file.\ :sup:`(c)` [#]_ [#]_

Usage Warnings
--------------
:sup:`(a)`  **SEG Y** v :math:`\le` rev 1 is supported. Trace header field
definitions in SEG Y are not ridigly controlled by any central authority, so
some industry SEG Y files may be unreadable. Please address questions about
unreadable SEG Y files to their creators.

:sup:`(b)`  **UW** data format has no online documentation. Please contact the SeisIO creators or the Pacific Northwest Seismic Network (University of Washington, United States) if additional help is needed to read these files.

:sup:`(c)`  **Win32** channel information files are not strictly controlled by a central authority; inconsistencies in channel parameters (e.g. gains) are known to exist. Please remember that redistribution of Win32 files is strictly prohibited by the NIED (our travis-ci tests use an encrypted tarball).


.. rubric:: External References
.. [#] FDSN SEED manual: https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf
.. [#] SAC data format intro: https://ds.iris.edu/ds/nodes/dmc/kb/questions/2/sac-file-format/
.. [#] SAC file format: https://ds.iris.edu/files/sac-manual/manual/file_format.html
.. [#] SAC software homepage: https://seiscode.iris.washington.edu/projects/sac
.. [#] SEG Y Wikipedia page: http://wiki.seg.org/wiki/SEG_Y
.. [#] PASSCAL SEG Y trace files: https://www.passcal.nmt.edu/content/seg-y-what-it-is
.. [#] How to use Hi-net data: http://www.hinet.bosai.go.jp/about_data/?LANG=en
.. [#] WIN data format (in Japanese): http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html


******************
File I/O Functions
******************

.. function:: readmseed(fname)
.. function:: readmseed!(S, fname)

Read miniSEED data file ``fname`` into a new or existing SeisData structure.

.. function:: readsac(fname[, full=false::Bool])
.. function:: rsac(fname[, full=false::Bool])

Read SAC data file ``fname`` into a new SeisData structure. Specify keyword ``full=true`` to save all SAC header values in field ``:misc``.

.. function:: readsegy(fname[, passcal=true::Bool])

Read SEG Y data file ``fname`` into a new SeisData structure. Use keyword ``passcal=true`` for PASSCAL-modified SEG Y.

.. function:: readuw(fname)

Read UW data file into new SeisData structure. ``fname`` can be a pick file (ending in [a-z]), a data file (ending in W), or a file root (numeric UW event ID).

.. function:: readwin32(fstr, cf)

Read win32 data from files matching pattern ``fstr`` into a new SeisData structure using channel information file ``cf``. ``fstr`` can be a path with wild card filenames, but cannot use wild card directories.

..function:: rlennasc(fname)

Read Lennartz-formatted ASCII file into a new SeisData structure.

.. function:: rseis(fname)

Read SeisIO native format data into an array of SeisIO structures.

.. function:: sachdr(fname)

Print headers from SAC file to stdout.

.. function:: segyhdr(fname[, PASSCAL=true::Bool])

Print headers from SEG Y file to stdout. Specify ``passcal=true`` for PASSCAL SEG Y.

.. function:: uwdf(dfname)

Parse UW event data file ``dfname`` into a new SeisEvent structure.

.. function:: uwpf!(evt, pfname)

Parse UW event pick file into SeisEvent structure.

.. function:: uwpf(pfname)

Parse UW event pick file ``pfname`` into a new SeisEvent structure.

.. function:: writesac(S[, ts=true])

Write SAC data to SAC files with auto-generated names. Specify ts=true to write time stamps; this will flag the file as generic x-y data in the SAC interpreter.

.. function:: wseis(fname, S)
.. function:: wseis(fname, S, T, U...)

Write SeisIO data to fname. Multiple objects can be written at once.
