#################
HDF5 File Formats
#################
Of the increasingly popular HDF5-based formats for geophysical data, only ASDF
is supported at present. Support for other (sub)formats is planned.

.. function:: S = read_hdf5(fname::String, s::TimeSpec, t::TimeSpec, [, KWs])
.. function:: read_hdf5!(S::GphysData, fname::String, s::TimeSpec, t::TimeSpec, [, KWs])

| Read data in seismic HDF5 file format from file **fname** into S.
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
  msr   | Bool      | true      | read full (MultiStageResp) instrument resp?
  v     | Int64     | 0         | verbosity

:sup:`(a)`  A question mark ('?') is a wildcard for a single character (exactly
one); an asterisk ('*') is a wildcard for zero or more characters.

.. function:: write_hdf5(fname, S::Union{GphysData, SeisEvent})

Write data from **S** to file **fname** in a seismic HDF5 format. The default
file format is ASDF.

With ASDF files, if typeof(S) == SeisEvent, **S.hdr** and **S.source** are
written (appended) to the "QuakeML/" element.

******************
Supported Keywords
******************
.. csv-table::
  :header: KW, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 4

  add   | Bool      | false     | Add new traces to file as needed?
  chans | ChanSpec  | 1:S.n     | Channels to write to file
  len   | Period    | Day(1)    | Length of new traces added to file
  ovr   | Bool      | false     | Overwrite data in existing traces?
  v     | Int64     | 0         | verbosity

Write Method: Add (**add=true**)
================================
Initialize new traces (filled with NaNs) of length = **len** as needed, and
overwrite with data in appropriate places.

ASDF behavior
-------------
For the ASDF file format, **add=true** follows these steps in this order:
1. Determine times of all data in **S[chans]** and all traces in "Waveforms/".
2. For all data in **S[chans]** that cannot be written to an existing trace, a new
trace of length = **len** sampled at **S.fs[i]** is initialized (filled with NaNs).
3. If a segment in **S[chans]** overlaps a trace in "Waveforms/" (including newly-
created traces):
+ Merge the header data in **S[chans]** into the relevant station XML.
+ Overwrite the relevant segment(s) of the trace.


Unless **len** exactly matches the time boundaries of each segment in **S**,
new traces will contain more data than **S**, with the extra samples initialized
to NaNs. Presumably these will be replaced with real data in subsequent
overwrites.


Write Method: Overwrite (**ovr = true**)
========================================
If **ovr=true** is specified, but **add=false**, **write_hdf5** *only* overwrites
*existing* data in **hdf_out**.
* No new trace data objects are created in **hdf_out**.
* No new file is created. If **hdf_out** doesn't exist, nothing happens.
* If no traces in **hdf_out** overlap segments in **S**, **hdf_out** isn't modified.
* In ASDF format, station XML is merged in channels that are partly overwritten.


.. function:: scan_hdf5(fname::String)
.. function:: scan_hdf5(fname::String, level="trace")

Scans supported seismic HDF5 formats and returns a list of strings describing
the waveform contents. If level="trace", output is more verbose.
