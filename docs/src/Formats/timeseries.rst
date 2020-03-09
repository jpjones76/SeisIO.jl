.. _readdata:

#################
Time-Series Files
#################
.. function:: read_data!(S, fmt::String, filepat [, KWs])
.. function:: S = read_data(fmt::String, filepat [, KWs])

| Read data from a supported file format into memory.
|
| **fmt**
| Case-sensitive string describing the file format. See below.
|
| **filepat**
| Read files with names matching pattern ``filepat``. Supports wildcards.
|
| **KWs**
| Keyword arguments; see also :ref:`SeisIO standard KWs<dkw>` or type ``?SeisIO.KW``. See table below for the list.

**********************
Supported File Formats
**********************
.. csv-table::
  :header: File Format, String, Strict Match
  :delim: |
  :widths: 2, 1, 2

  AH-1                      | ah1           | id, fs, gain, loc, resp, units
  AH-2                      | ah2           | id, fs, gain, loc, resp
  Bottle (UNAVCO)           | bottle        | id, fs, gain
  GeoCSV, time-sample pair  | geocsv        | id
  GeoCSV, sample list       | geocsv.slist  | id
  Lennartz ASCII            | lenartz       | id, fs
  Mini-SEED                 | mseed         | id, fs
  PASSCAL SEG Y             | passcal       | id, fs, gain, loc
  SAC                       | sac           | id, fs, gain
  SEG Y (rev 0 or rev 1)    | segy          | id, fs, gain, loc
  SEISIO                    | seisio        | id, fs, gain, loc, resp, units
  SLIST (ASCII sample list) | slist         | id, fs
  SUDS                      | suds          | id
  UW data file              | uw            | id, fs, gain, units
  Win32                     | win32         | id, fs, gain, loc, resp, units

Strings are case-sensitive to prevent any performance impact from using matches
and/or lowercase().

Note that read_data with file format "seisio" largely exists as a convenience
wrapper; it reads only the first SeisIO object from each file that can be
converted to a SeisData structure. For more complicated read operations,
``rseis`` should be used.

******************
Supported Keywords
******************

+---------+---------+---------+-----------+----------------------------------+
| Keyword | Used By | Type    | Default   | Meaning                          |
+=========+=========+=========+===========+==================================+
| cf      | win32   | String  | \"\"      | win32 channel info filestr       |
+---------+---------+---------+-----------+----------------------------------+
| full    | [#]_    | Bool    | false     | read full header into :misc?     |
+---------+---------+---------+-----------+----------------------------------+
| memmap  | \*      | Bool    | false     | use Mmap.mmap to buffer file?    |
+---------+---------+---------+-----------+----------------------------------+
| nx_add  | [#]_    | Int64   | 360000    | minimum size increase of x       |
+---------+---------+---------+-----------+----------------------------------+
| nx_new  | [#]_    | Int64   | 86400000  | length(x) for new channels       |
+---------+---------+---------+-----------+----------------------------------+
| jst     | win32   | Bool    | true      | are sample times JST (UTC+9)?    |
+---------+---------+---------+-----------+----------------------------------+
| swap    | [#]_    | Bool    | true      | byte swap?                       |
+---------+---------+---------+-----------+----------------------------------+
| strict  | \*      | Bool    | true      | use strict match?                |
+---------+---------+---------+-----------+----------------------------------+
| v       | \*      | Integer | 0         | verbosity                        |
+---------+---------+---------+-----------+----------------------------------+
| vl      | \*      | Bool    | 0         | verbose source logging? [#]_     |
+---------+---------+---------+-----------+----------------------------------+

.. rubric:: Table Footnotes
.. [#] used by ah1, ah2, sac, segy, suds, uw; information read into ``:misc`` varies by file format.
.. [#] used by bottle, mseed, suds, win32
.. [#] used by bottle, mseed, suds, win32
.. [#] used by mseed, passcal, segy; swap is automatic for sac.
.. [#] adds one line to ``:notes`` per file read. It is not guaranteed that files listed in ``S.notes[i]`` contain data for channel **i**; rather, all files listed are from the read operation(s) that populated **i**.

Performance Tips
================
1. `mmap=true` improves read speed for some formats, particularly ASCII readers, but requires caution. In our benchmarks, the following significant (>3%) speed changes are observed:

* *Significant speedup*: ASCII formats, including metadata formats
* *Slight speedup*: mini-SEED
* *Significant slowdown*: SAC

2. With mseed or win32 data, adjust `nx_new` and `nx_add` based on the sizes of
the data vectors that you expect to read. If the largest has `Nmax` samples,
and the smallest has `Nmin`, we recommend `nx_new=Nmin` and `nx_add=Nmax-Nmin`.

Default values can be changed in SeisIO keywords, e.g.,
::

  SeisIO.KW.nx_new = 60000
  SeisIO.KW.nx_add = 360000

The system-wide defaults are `nx_new=86400000` and `nx_add=360000`. Using these
values with very small jobs will greatly decrease performance.

3. `strict=true` may slow `read_data` based on the fields matched as part of
the file format. In general, any file format that can match on more than id
and fs will read slightly slower with this option.

Channel Matching
================
By default, `read_data` continues a channel if data read from file matches the
channel id (field **:id**). In some cases this is not enough to guarantee a good match. With ``strict=true``, `read_data` matches against fields **:id**, **:fs**, **:gain**, **:loc**, **:resp**, and **:units**. However, not all of these fields are stored natively in all file formats. Column "Strict Match" in the first table lists which fields are stored (and can be logically matched) in each format with `strict=true`.

********
Examples
********

1. ``S = read_data("uw", "99011116541W", full=true)``
    + Read UW-format data file ``99011116541W``
    + Store full header information in ``:misc``
2. ``read_data!(S, "sac", "MSH80*.SAC")``
    + Read SAC-format files matching string pattern `MSH80*.SAC`
    + Read into existing SeisData object ``S``
3. ``S = read_data("win32", "20140927*.cnt", cf="20140927*ch", nx_new=360000)``
    + Read win32-format data files with names matching pattern ``2014092709*.cnt``
    + Use ASCII channel information filenames that match pattern ``20140927*ch``
    + Assign new channels an initial size of ``nx_new`` samples

Memory Mapping
==============
`memmap=true` is considered unsafe because Julia language handling of SIGBUS/SIGSEGV and associated risks is undocumented as of SeisIO v1.0.0. Thus, for example, we don't know what a connection failure during memory-mapped file I/O does. In some languages, this situation without additional signal handling was notorious for corrupting files.

**Under no circumstances** should `mmap=true` be used to read files directly from a drive whose host device power management is independent of the destination computer's. This includes all work flows that involve reading files directly into memory from a connected data logger. It is *not* a sufficient workaround to set a data logger to "always on".

*****************************
Format Descriptions and Notes
*****************************
Additional format information can be accessed from the command line by typing
``SeisIO.formats("FMT")`` where FMT is the format name; ``keys(SeisIO.formats)``
for a list.

* **AH** (Ad-Hoc) was developed as a machine-independent seismic data format based on External Data Representation (XDR).
* **Bottle** is a single-channel format maintained by UNAVCO (USA).
* `GeoCSV\ <http://geows.ds.iris.edu/documents/GeoCSV.pdf>`_: an extension of "human-readable", tabular file format Comma-Separated Values (CSV).
* **Lennartz**: a variant of sample list (SLIST) used by Lennartz portable digitizers.
* `PASSCAL\ <https://www.passcal.nmt.edu/content/seg-y-what-it-is>`_: A single- channel variant of SEG Y with no file header, developed by PASSCAL/New Mexico Tech and used with PASSCAL field equipment through the late 2000s.
* `SAC\ <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_: the Seismic Analysis Code data format, originally developed by LLNL for the eponymous command-line interpreter.
* `SEED\ <https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf>`_: adopted by the International Federation of Digital Seismograph Networks (FDSN) as an omnibus seismic data standard. mini-SEED is a data-only variant that uses only data blockettes.
* `SEG Y\ <http://wiki.seg.org/wiki/SEG_Y>`_: Society of Exploration Geophysicists data format. Common in the energy industry, developed and maintained by the SEG. Only SEG Y rev 0 and `rev 1\ <https://seg.org/Portals/0/SEG/News%20and%20Resources/Technical%20Standards/seg_y_rev1.pdf>`_ with standard headers are supported.
* **SLIST**: An ASCII file with a one-line header and data written to file in ASCII string format.
* **SUDS**: A competitor to SEED developed by the US Geological Survey (USGS), USA in the late 1980s.
* **UW**: created in the 1970s by the Pacific Northwest Seismic Network (PNSN), USA, for event archival; used until the early 2000s.
* `Win32\ <http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html>`_: maintained by the National Research Institute for Earth Science and Disaster Prevention (NIED), Japan. Continuous data are divided into files that contain a minute of data from multiple channels stored in one-second segments. Channel information is in an external text file, which was previously not controlled by any central authority; inconsistencies between different versions of the same channel file (maintained by different institutions) may exist.

************************
Other File I/O Functions
************************

.. function:: rseis(fname)

Read SeisIO native format data into an array of SeisIO structures.
:raw-html:`<br /><br />`

.. function:: sachdr(fname)

Print headers from SAC file to stdout.
:raw-html:`<br /><br />`

.. function:: segyhdr(fname[, PASSCAL=true::Bool])

Print headers from SEG Y file to stdout. Specify ``passcal=true`` for PASSCAL SEG Y.
