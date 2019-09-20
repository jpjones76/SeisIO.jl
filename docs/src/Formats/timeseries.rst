.. _readdata:

#############################
Time-Series Data File Formats
#############################
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
| Keyword arguments; see also :ref:`SeisIO standard KWs<dkw>` or type ``?SeisIO.KW``.
| Standard keywords: full, nx_add, nx_new, v
| Other keywords: See below.

**********************
Supported File Formats
**********************
.. csv-table::
  :header: File Format, String
  :delim: |
  :widths: 2, 1

  AH-1                      | ah1
  AH-2                      | ah2
  GeoCSV, time-sample pair  | geocsv
  GeoCSV, sample list       | geocsv.slist
  Lennartz ASCII            | lenartzascii
  Mini-SEED                 | mseed
  PASSCAL SEG Y             | passcal
  SAC                       | sac
  SEG Y (rev 0 or rev 1)    | segy
  SUDS                      | suds
  UW data file              | uw
  Win32                     | win32

Strings are case-sensitive to prevent any performance impact from using matches
and/or lowercase().

******************
Supported Keywords
******************
.. csv-table::
  :header: KW, Used By, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 1, 4

  cf     | win32    | String  | \"\"      | win32 channel info filestr
  full   | ah1, ah2 | Bool    | false     | read full header into **:misc**?
         | sac      |         |           |
         | segy     |         |           |
         | uw       |         |           |
  nx_add | mseed    | Int64   | 360000    | minimum size increase of **:x**
  nx_new | mseed    | Int64   | 86400000  | length of **:x** for new channels
  jst    | win32    | Bool    | true      | are sample times JST (UTC+9)?
  swap   | seed     | Bool    | true      | byte swap?
  units  | resp     | Bool    | false     | fill in units of CoeffResp stages?
  v      | (all)    | Int64   | 0         | verbosity


Performance Tip
===============
With mseed or win32 data, adjust `nx_new` and `nx_add` based on the sizes of
the data vectors that you expect to read. If the largest has `Nmax` samples,
and the smallest has `Nmin`, we recommend `nx_new=Nmin` and `nx_add=Nmax-Nmin`.

Default values can be changed in SeisIO keywords, e.g.,
::

  SeisIO.KW.nx_new = 60000
  SeisIO.KW.nx_add = 360000

The system-wide defaults are `nx_new=86400000` and `nx_add=360000`. Using these
values with very small jobs will greatly decrease performance.

Examples
--------

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


*****************************
Format Descriptions and Notes
*****************************
Additional format information can be accessed from the command line by typing
``SeisIO.formats("FMT")`` where FMT is the format name; ``keys(SeisIO.formats)``
for a list.

**AH** (Ad-Hoc) was developed as a machine-independent seismic data format
based on External Data Representation (XDR).

`GeoCSV\ <http://geows.ds.iris.edu/documents/GeoCSV.pdf>`_: an extension of
"human-readable", tabular file format Comma-Separated Values (CSV).

**Lennartz ASCII**: ASCII output of Lennartz portable digitizers.

`PASSCAL\ <https://www.passcal.nmt.edu/content/seg-y-what-it-is>`_: A single-
channel variant of SEG Y with no file header, developed by PASSCAL/New Mexico
Tech and used with PASSCAL field equipment through the late 2000s.

`SEED\ <https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf>`_: SEED stands for
Standard for the Exchange of Earthquake Data; used by the International
Federation of Digital Seismograph Networks (FDSN) as an omnibus seismic data
standard. mini-SEED is a data-only variant that uses only data blockettes.

`SAC\ <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_: the
Seismic Analysis Code data format, originally developed for the eponymous
command-line interpreter. Widely used, and supported in virtually every
programming language.

`SEG Y\ <http://wiki.seg.org/wiki/SEG_Y>`_: Society of Exploration Geophysicists
data format. Common in the energy industry, developed and maintained by the SEG.
Only SEG Y rev 0 and `rev 1\ <https://seg.org/Portals/0/SEG/News%20and%20Resources/Technical%20Standards/seg_y_rev1.pdf>`_
with standard headers are supported.

**UW**: the University of Washington data format has no online reference and is
no longer in use. Created by the Pacific Northwest Seismic Network for event
archival; used from the 1970s through early 2000s. A UW event is described by a
pickfile and corresponding data file, whose names are identical except for the
last character; for example, files 99062109485o and 99062109485W together
describe event 99062109485. Unlike the win32 data format, the data file is
self-contained; the pick file is not required to use raw trace data. However,
like the win32 data format, instrument locations are stored in an external
human-maintained text file. Only UW-2 data files are supported by SeisIO; we
have never encountered a UW-1 data file outside of Exabyte tapes and have no
reason to suspect that any remain in circulation.

`Win32\ <http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html>`_: data format developed
by the Earthquake Research Institute (ERI), University of Tokyo, Japan. Data
are typically divided into files that contain a minute of continuous
data from several channels. Data within each file are stored by channel in
one-second segments as variable-precision delta-encoded integers. Channel
information is retrieved from an external channel information file. Although
accurate channel files are needed to use win32 data, these files are not
strictly controlled by any central authority. Inconsistencies in channel
parameters, particularly gains, are known to exist.

************************
Other File I/O Functions
************************

.. function:: rseis(fname)

Read SeisIO native format data into an array of SeisIO structures.

.. function:: sachdr(fname)

Print headers from SAC file to stdout.

.. function:: segyhdr(fname[, PASSCAL=true::Bool])

Print headers from SEG Y file to stdout. Specify ``passcal=true`` for PASSCAL SEG Y.

.. function:: uwdf(dfname)

Parse UW event data file ``dfname`` into a new SeisEvent structure.

.. function:: writesac(S[, ts=true])

Write SAC data to SAC files with auto-generated names. Specify ts=true to write
time stamps; this will flag the file as generic x-y data in the SAC interpreter.

.. function:: wseis(fname, S)
.. function:: wseis(fname, S, T, U...)

Write SeisIO data to fname. Multiple objects can be written at once.
