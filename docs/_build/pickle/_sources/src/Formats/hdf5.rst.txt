#################
HDF5 File Formats
#################
Of the emerging HDF5 geophysical data formats, only the ASDF format is
supported at present. Support for other geophysical HDF5 (sub)formats is planned.

.. function:: S = read_hdf5(fname::String, [, KWs])
.. function:: S = read_meta(fname::String, [, KWs])

| Read metadata in seismic HDF5 file format from file **fname** into S.
|
| **KWs**
| Keyword arguments; see also :ref:`SeisIO standard KWs<dkw>` or type ``?SeisIO.KW``.

This has one fundamental design difference from :ref:`read_data<readdata>`:
HDF5 archives are assumed to be large files with data from multiple channels;
they are scanned selectively for data of interest to read, rather than read
into memory in their entirety.

******************
Supported Keywords
******************
.. csv-table::
  :header: KW, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 4

  id    | String    | \"*.*..*\"| id pattern, formated nn.sss.ll.ccc
        |           |           |  (net.sta.loc.cha); FDSN-style wildcards \ :sup:`(a)`
  s     | TimeSpec  |           | start time \ :sup:`(b)`
  t     | TimeSpec  |           | termination (end) time \ :sup:`(b)`
  msr   | Bool      | true      | read full (MultiStageResp) instrument resp?
  v     | Int64     | 0         | verbosity

:sup:`(a)`  A question mark ('?') is a wildcard for a single character (exactly
one); an asterisk ('*') is a wildcard for zero or more characters.
:sup:`(b)`  If unset, (s,t) ~ (21 September 1677, 11 April 2262), the limits of
timekeeping (relative to the Unix epoch) with Int64 nanoseconds.

The use of ``s``, ``t`` are *very strongly* recommended.

.. function:: scan_hdf5(fname::String)
.. function:: scan_hdf5(fname::String, level=channel)

Scans supported seismic HDF5 formats and returns a list of strings describing
the waveform contents. If level=channel, output is more verbose.
