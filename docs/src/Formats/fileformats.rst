############
File Formats
############

Current format support: (e = endianness)

+----------+---+-------------------------------------------------------------+
| Format   | e | Functions                                                   |
+==========+===+=============================================================+
| miniSEED | b | readmseed                                                   |
+----------+---+-------------------------------------------------------------+
| SAC      | l |   readsac, sachdr, writesac                                 |
+----------+---+-------------------------------------------------------------+
| SEG Y    | b |   readsegy, segyhdr                                         |
+----------+---+-------------------------------------------------------------+
| P-SEG Y  | l |   readsegy, segyhdr                                         |
+----------+---+-------------------------------------------------------------+
| UW       | b |   readuw, uwpf!, uwpf, uwdf                                 |
+----------+---+-------------------------------------------------------------+
| win32    | b |   readwin32                                                 |
+----------+---+-------------------------------------------------------------+


Format Descriptions and Notes
=============================

**miniSEED**: SEED stands for Standard for the Exchange of Earthquake Data. miniSEED is a SEED variant format that contains only data packets. [#]_

**SAC**: a fast, straightforward format developed for the Seismic Analysis Code application, supported by virtually every programming language. [#]_ [#]_ [#]_

**SEG Y**: data format used by the Society for Exploration Geophysicists\ :sup:`(a)` [#]_

**P-SEG Y**: A modified SEG Y format developed by PASSCAL/New Mexico Tech. [#]_

**UW**: the University of Washington data format was designed for event archival. A UW event is described by a pickfile and a corresponding data file, whose names are identical except for the last character, e.g. 99062109485o, 99062109485W.\ :sup:`(b)`

**Win32** : data format developed by the NIED (National Research Institute for Earth Science and Disaster Prevention), Japan. Data are typically divided into files that contain a minute of continuous data from channels on a single network or subnet; data within each file are stored by channel as variable-precision integers in 1s segments. Channel information for each stream is retrieved from a channel information file.\ :sup:`(c)` [#]_ [#]_

Usage Warnings
--------------
:sup:`(a)`  SEG Y is supported up to and including rev 1. Trace header fields in SEG Y are not rigidly defined by any central authority, only "recommended". As such, industry SEG Y files may be unreadable. This issue is widely known, not correctable, and by no means endemic to SeisIO.

:sup:`(b)`  No online documentation for the UW data format is known to exist. Please contact the SeisIO creators if additional help is needed to read these files.

:sup:`(c)`  Win32 channel information files are not synchronized by any central authority, date stamped, or automatically maintained; thus, inconsistencies in channel parameters (e.g. gains) are possible. Please remember that redistribution of Win32 files is strictly prohibited by the NIED.


.. rubric:: External References
.. [#] FDSN SEED manual: https://www.fdsn.org/seed_manual/SEEDManual_V2.4.pdf
.. [#] SAC data format intro: https://ds.iris.edu/ds/nodes/dmc/kb/questions/2/sac-file-format/
.. [#] SAC file format: https://ds.iris.edu/files/sac-manual/manual/file_format.html
.. [#] SAC software homepage: https://seiscode.iris.washington.edu/projects/sac
.. [#] SEG Y Wikipedia page: http://wiki.seg.org/wiki/SEG_Y
.. [#] PASSCAL SEG Y trace files: https://www.passcal.nmt.edu/content/seg-y-what-it-is
.. [#] How to use Hi-net data: http://www.hinet.bosai.go.jp/about_data/?LANG=en
.. [#] WIN data format (in Japanese): http://eoc.eri.u-tokyo.ac.jp/WIN/Eindex.html
