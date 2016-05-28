*******************
:mod:`File Formats`
*******************

SeisIO can read several file formats. In most cases, files can be read directly into SeisData objects or read into dictionaries.



Current Format Support
======================

* :ref:`mini-SEED <mseed>`: `SEED <https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf>`_ has become a worldwide standard for seismic data archival; mini-SEED archives are special SEED volumes that contain only data records.

* :ref:`SAC <sac1>`: `SAC <https://ds.iris.edu/files/sac-manual/manual/file_format.html>`_ is a popular seismic data standard, very easy to use, developed at Lawrence Livermore National Laboratory.

* :ref:`SEGY <segy>`: `SEG Y <http://wiki.seg.org/wiki/SEG_Y>`_ is the standard data archival format of the Society for Exploration Geophysicists.

* :ref:`UW <uw>`: The University of Washington seismic data format was used from the 1970s through mid-2000s; legacy support is included with SeisIO.

* :ref:`Win32 <win32>`: `WIN <http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html>`_ is a seismic data format developed and used by the NIED (National Research Institute for Earth Science and Disaster Prevention), Japan.


.. _mseed:

mini-SEED
=========
The mini-SEED reader doesn't have a full range of data decoders yet. Currently supported data formats include Int16, Int32, Float, Double, Steim1, and Steim2. Future updates will add Int24, Steim3, and the various GEOSCOPE encodings.

*Expected endianness: big*


Associated functions
--------------------

* ``readmseed``: read mini-SEED file to SeisData




.. _sac1:

SAC
===
*Expected endianness: little*


Associated functions
--------------------

* ``chksac``: check for valid SAC header structure

* ``prunesac!``: delete unset headers from a SAC dictionary

* ``r_sac``: read SAC file to dictionary

* ``readsac``: read SAC file to SeisData object

* ``sachdr``: dump headers to STDOUT

* ``sactoseis``: convert SAC dictionary to SeisData

* ``writesac``: write SeisData object or SAC dictionary to SAC file

* ``sac_bat``: fast batch read of SAC files from the same channel



.. _segy:

SEG Y
=====
SEG Y rev 0 (and rev 1, to a lesser degree) doesn't enforce strict channel header formats. There is no guarantee that SEG Y files from all industry sources will parse correctly with ``readsegy``.

An added keyword (``fmt="nmt"``) is required to parse PASSCAL SEG Y trace files. The modified file format used by IRIS/PASSCAL/NMT lacks the 3600-byte record header (3200-byte textural header + 400-byte file header). In addition, PASSCAL SEG Y assumes little endian byte order.

*Expected endianness: big for standard SEGY, little for PASSCAL/NMT*


Associated functions
--------------------

* ``prunesegy!``: delete junk headers from a SEGY dictionary

* ``r_segy``: read SEGY file to SeisData object

* ``readsegy``: read SEGY file to SeisData object

* ``segyhdr``: dump headers to STDOUT

* ``segytosac``: convert SEGY dictionary to SAC dictionary

* ``segytoseis``: convert SEGY dictionary to SeisData object


References
----------

#. `SEG Y data format <http://wiki.seg.org/wiki/SEG_Y>`_

#. `PASSCAL SEG Y trace files <https://www.passcal.nmt.edu/content/seg-y-what-it-is>`_



.. _uw:

UW
===
UW files are event-oriented, typically used to archive earthquake data; a typical event is described by a pickfile and a corresponding data file. If a datafile name (ending in `*W`) is passed to a read command, it searches for a pickfile in the datafile directory; similarity, if a pickfile name (ending in `*[a-z]`) is used, it searches the pickfile directory for the corresponding data file.

*Expected endianness: big*


Associated functions
--------------------

* ``r_uw``: read UW pickfile and/or datafile to dictionary

* ``readuw``: read UW pickfile and/or datafile to SeisData

* ``readuwpf``: read UW pickfile to dictionary

* ``readuwdf``: read UW datafile to dictionary

* ``uwtoseis``: convert UW dictionary to SeisData

(No online references for this file format are known to exist)



.. _win32:

Win32 file format
=================
Because win32 favors dividing contiguous data into small (typically one-minute) files, readwin32 has basic wildcard functionality for data file names. All data files matching the wildcard are read in lexicographical order and synchronized. However, readwin32 requires a channel information file as a mandatory second argument.

*Expected endianness: big*


Associated functions
--------------------

* ``readwin32``: read win32 files to SeisData

* ``r_win32``: read win32 files to dictionary

* ``win32toseis``: convert win32 dictionary to SeisData
