*******************
:mod:`File Formats`
*******************

SeisIO can read several file formats. In most cases, files can be read directly into SeisData objects or read into dictionaries.



Current Format Support
======================

* :ref:`mini-SEED <mseed>`: `SEED <https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf>`_ has become a worldwide standard for seismic data archival; mini-SEED archives are special SEED volumes that contain only data records.

* :ref:`SAC <sac1>`:sup:`(a)`: `SAC <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_ is a popular seismic data standard, very easy to use, developed at Lawrence Livermore National Laboratory.

* :ref:`SEGY <segy>`:sup:`(a)`: `SEG Y <http://wiki.seg.org/wiki/SEG_Y>`_ is the standard data archival format of the Society for Exploration Geophysicists.

* :ref:`UW <uw>`: The University of Washington seismic data format was used from the 1970s through mid-2000s; legacy support is included with SeisIO.

* :ref:`Win32 <win32>`: `WIN <http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html>`_ is a seismic data format developed and used by the NIED (National Research Institute for Earth Science and Disaster Prevention), Japan.


:sup:`(a)`  Partial support for fast multi-file read with ``batch_read``; see below.

.. _mseed:

mini-SEED
=========
The mini-SEED reader doesn't have a full range of data decoders yet. Currently supported data formats include Int16, Int32, Float, Double, Steim1, and Steim2. Future updates will add Int24, Steim3, and the various GEOSCOPE encodings.

*Endian: big*


Associated functions
--------------------

* ``readmseed``: read mini-SEED file to SeisData




.. _sac1:

SAC
===
SAC stands for Seismic Analysis Code. Among the most portable and intuitive seismic data formats, SAC was developed by Lawrence Livermore National Laboratory for use with the eponymous data processing application.

*Endian: little*


Associated functions
--------------------

* ``chksac``: check for valid SAC header structure

* ``prunesac!``: delete unset headers from a SAC dictionary

* ``r_sac``: read SAC file to dictionary

* ``readsac``: read SAC file to SeisData object

* ``sachdr``: dump headers to STDOUT

* ``sactoseis``: convert SAC dictionary to SeisData

* ``writesac``: write SeisData object or SAC dictionary to SAC file


References
----------
#. `SAC data format intro <https://ds.iris.edu/ds/nodes/dmc/kb/questions/2/sac-file-format/>`_

#. `SAC data file format <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_

#. `SAC homepage <https://seiscode.iris.washington.edu/projects/sac>`_

.. _segy:

SEG Y
=====
The SEG Y (sometimes SEG-Y) file format was developed by the Society of Exploration Geophysicists (SEG). Modified versions of SEG Y are used by PASSCAL, New Mexico Tech, and others.

An added keyword (``nmt=true``) is required to parse PASSCAL SEG Y trace files. The modified file format used by IRIS/PASSCAL/NMT lacks a 3600-byte record header (3200-byte text header + 400-byte file header). In addition, PASSCAL SEG Y assumes little endian byte order.

*Caution*: SEG Y trace header fields are not rigidly defined by any central authority and are notoriously self-incompatibile. There is no guarantee that SEG Y files from unverified sources will parse correctly with ``readsegy`` (or *any* program, for that matter). This is especially problematic with proprietary industry data, as some companies fill the last 60 bytes of the trace header with non-standard field definitions.

*Endian: big for standard SEG Y, little for PASSCAL/NMT SEG Y*


Associated functions
--------------------

* ``readsegy``: read SEGY file to SeisData object

* ``segyhdr``: dump column-aligned headers to STDOUT


References
----------

#. `SEG Y data format <http://wiki.seg.org/wiki/SEG_Y>`_

#. `PASSCAL SEG Y trace files <https://www.passcal.nmt.edu/content/seg-y-what-it-is>`_



.. _uw:

UW
===
The University of Washington data format uses event-oriented records, typically to archive earthquake data; an event is described by a pickfile and the corresponding data file, whose filenames are identical, except for the last character. If a datafile name (ending in `*W`) is passed to ``readuw``, it searches for a pickfile in the datafile directory. Similarity, if a pickfile name (ending in `*[a-z]`) is used, ``readuw`` searches the pickfile directory for the corresponding data file.

*Endian: big*


Associated functions
--------------------


* ``readuw``: read UW pickfile and/or datafile into a SeisEvent object

* ``uwpf``: read UW pickfile into a SeisHdr object

* ``uwpf!``: update SeisEvent header with pickfile info

* ``uwdf``: read UW datafile into a SeisData object


(No online references for this file format are known to exist; its creation predates the world wide web)



.. _win32:

Win32 file format
=================
Win32 is the standard seismic data format of NIED (Japan). It is widely used in Japan, but rare elsewhere.

*Endian: big*

References
----------

#. `How to use the Hi-net data <http://www.hinet.bosai.go.jp/about_data/?LANG=en>`_


Associated functions
--------------------

* ``readwin32``: read win32 files to SeisData

*Warnings*
---------
#. Although the Win32 data format is technically open, accessing documentation requires an NIED login, which is not available to the general public.
#. Redistribution of Win32 files is prohibited.
#. Win32 channel files are not synchronized among different network operators, leaving them prone to human error; non-NIED channel files supplied by NIED data requests may contain inconsistencies, particularly in instrument gains.


Batch Read
==========
The utility ``batch_read`` speeds up file read using parallel file read to shared arrays. The result is an order of magnitude speedup relative to reading files one at a time. Currently, SAC and SEG Y data formats work with ``batch_read``.


Syntax
------
``S = batch_read(FILESTR, ftype=FMT, fs=FS)``

Read files matching FILESTR of format FMT and resample to FS Hz. If FS isn't specified, files are resampled to match the first file read.

``FILESTR`` supports wildcards in filenames, but not directory names. Thus, ``batch_read("/data/PALM_EHZ_CC/2015.16*SAC")`` will read all files in ``/data/PALM_EHZ_CC/`` that begin with "2015.16" and end with "SAC"; ``batch_read("/data2/Hood/*/2015.16*SAC")`` will result in an error.


Supported keywords
------------------

``ftype=FT`` (ASCIIString): File type. Default is :ref:`"SAC" <sac1>`.

``fs=FS`` (Float64): Resample data to ``FS`` Hz.

Supported file formats
----------------------

:ref:`SAC <sac1>`: use keyword ``ftype="SAC"``

:ref:`PASSCAL SEG Y <segy>`: use keyword ``ftype="NMT"`` or ``ftype="PASSCAL"``
