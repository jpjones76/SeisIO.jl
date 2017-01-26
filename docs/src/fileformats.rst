*******************
:mod:`File Formats`
*******************

SeisIO can read several file formats. In most cases, files can be read directly into SeisData objects or read into dictionaries.



Current Format Support
======================

* :ref:`mini-SEED <mseed>`: `SEED <https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf>`_ has become a worldwide standard for seismic data archival; mini-SEED archives are special SEED volumes that contain only data records.

* :ref:`SAC <sac1>`:sup:`(a)`: `SAC <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_ is a popular seismic data standard developed at Lawrence Livermore National Laboratory, noted for ease of use.

* :ref:`SEGY <segy>`:sup:`(a)`: `SEG Y <http://wiki.seg.org/wiki/SEG_Y>`_ is the standard data archival format of the Society for Exploration Geophysicists.

* :ref:`UW <uw>`: The University of Washington seismic data format was used from the 1970s through the 2000s; legacy support is included with SeisIO.

* :ref:`Win32 <win32>`: `WIN <http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html>`_ is a seismic data format developed and used by the NIED (National Research Institute for Earth Science and Disaster Prevention), Japan.


:sup:`(a)`  Partial support for fast multi-file read with ``batch_read``; see below.

.. _mseed:

mini-SEED
=========
SEED is an archival format maintained by the International Federation of Digital Seismograph Networks. The data format is widely used and highly versatile, but often criticized as monolithic; the most complete example of SEED documentation is a 224-page .PDF with multiple appendices.

The mini-SEED reader currently doesn't have a full range of packet decoders; currently supported formats include Int16, Int32, Float, Double, Steim1, and Steim2.

*Endian: big*


Associated functions
--------------------
 ``parsemseed!, parsemseed, readmseed, parserec!``

References
----------
#. `SEED format manual, v2.4 <http://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf>`_

#. `SEED format channel naming <http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf>`_


.. _sac1:

SAC
===
Among the most portable and intuitive seismic data formats, Seismic Analysis Code (SAC) was developed by Lawrence Livermore National Laboratory (USA) for use with the eponymous data processing application.

*Endian: little*


Associated functions
--------------------

``batch_read, readsac, sachdr, wsac``


References
----------
#. `SAC data format intro <https://ds.iris.edu/ds/nodes/dmc/kb/questions/2/sac-file-format/>`_

#. `SAC data file format <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_

#. `SAC homepage <https://seiscode.iris.washington.edu/projects/sac>`_

.. _segy:

SEG Y
=====
The SEG Y (sometimes SEG-Y or SEGY) file format was developed by the Society of Exploration Geophysicists (USA). Modified versions of SEG Y are used by PASSCAL, New Mexico Tech, and others.

An added keyword (``nmt=true``) is required to parse PASSCAL SEG Y trace files. The modified file format used by IRIS, PASSCAL, and NMT lacks the 3600-byte record header (3200-byte text header + 400-byte file header). In addition, unlike standard SEG Y, PASSCAL SEG Y assumes little endian byte order.

*Caution*: SEG Y trace header fields are not rigidly defined by any central authority. As such, there is no guarantee that industry SEG Y files will be readable; this issue is widely known and by no means endemic to SeisIO. Proprietary industry files are often problematic because many companies fill the last 60 bytes of the trace header with non-standard fields.

*Endian: big for standard SEG Y, little for PASSCAL/NMT SEG Y*


Associated functions
--------------------

``batch_read, readsegy, segyhdr``


References
----------

#. `SEG Y data format <http://wiki.seg.org/wiki/SEG_Y>`_

#. `PASSCAL SEG Y trace files <https://www.passcal.nmt.edu/content/seg-y-what-it-is>`_



.. _uw:

UW
===
The University of Washington data format uses event-oriented records, typically to archive earthquake data; an event is described by a pickfile and the corresponding data file, whose filenames are identical except for the last character. If a datafile (name ending in `*W`) is passed to ``readuw``, it searches for a corresponding pickfile (ending in `*[a-z]`) in the same directory. Similarity, if a pickfile name is passed to ``readuw``, it searches the pickfile directory for the corresponding data file.

*Endian: big*


Associated functions
--------------------

``readuw, uwdf, uwpf, uwpf!``


Notes
-----
#. No online references for this file format are known to exist; its creation predates the world wide web.


.. _win32:

Win32 file format
=================
Win32 is the standard seismic data format of NIED (Japan). It is widely used in Japan but rare elsewhere. Data are typically divided into files that each contain a one-minute segment of data from a selection of channels on a network. Data within each file are stored in 1 s segments by channel as variable-precision integers.

*Endian: big*

References
----------

#. `How to use the Hi-net data <http://www.hinet.bosai.go.jp/about_data/?LANG=en>`_


Associated functions
--------------------

``readwin32``


Notes
-----
#. Although the Win32 data format is technically open, accessing documentation requires an NIED login. NIED access is not available to the general public.
#. Redistribution of Win32 files is strictly prohibited.
#. Win32 channel files are not synchronized by a central authority. Non-NIED channel files supplied by NIED data requests may contain inconsistencies.


Batch Read
==========
``batch_read`` uses parallel file reading to shared arrays. The result memory-intensive but very fast, typically an order of magnitude speedup relative to reading files one at a time. Currently, SAC and SEG Y data formats work with ``batch_read``.


Usage
-----
::

  @everywhere using SeisIO
  S = batch_read(FILESTR, ftype=FMT, fs=FS)


``FILESTR`` supports wildcards in filenames, but not directory names.


Supported keywords
------------------

``ftype=FT`` (ASCIIString): File type. Default is :ref:`"SAC" <sac1>`.

``fs=FS`` (Float64): Resample data to ``FS`` Hz. The default is to use the sampling frequency of the first file read.

Supported file formats
----------------------

:ref:`SAC <sac1>`: use keyword ``ftype="SAC"``

:ref:`PASSCAL SEG Y <segy>`: use keyword ``ftype="NMT"`` or ``ftype="PASSCAL"``

Example
-------
``batch_read("/data/PALM_EHZ_CC/2015.16*SAC")``
