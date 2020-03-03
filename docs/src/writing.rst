.. _write:

###############
Writing to File
###############
The table below sumamrizes the current write options for SeisIO. Each function is described in detail in this chapter.

.. csv-table::
  :header: Structure/Description, Output Format, Function
  :delim: |
  :widths: 2, 2, 1

  GphysChannel                          | ASDF                  | write_hdf5
  GphysChannel                          | SAC timeseries        | writesac
  GphysChannel channel metadata         | StationXML            | write_sxml
  GphysChannel instrument response      | SAC polezero          | writesacpz
  GphysData                             | ASDF                  | write_hdf5
  GphysData                             | SAC timeseries        | writesac
  GphysData channel metadata            | StationXML            | write_sxml
  GphysData instrument response         | SAC polezero          | writesacpz
  SeisEvent                             | ASDF                  | write_hdf5
  SeisEvent header and source info      | ASDF QuakeML          | asdf_wqml
  SeisEvent header and source info      | QuakeML               | write_qml
  SeisEvent trace data only             | SAC timeseries        | writesac
  Array{SeisEvent, 1}                   | ASDF QuakeML          | asdf_wqml
  Array{SeisHdr, 1}                     | QuakeML               | write_qml
  Array{SeisHdr, 1}, Array{SeisSrc, 1}  | ASDF QuakeML          | asdf_wqml
  Array{SeisHdr, 1}, Array{SeisSrc, 1}  | QuakeML               | write_qml
  SeisHdr                               | QuakeML               | write_qml
  SeisHdr, SeisSrc                      | ASDF QuakeML          | asdf_wqml
  SeisHdr, SeisSrc                      | QuakeML               | wqml
  any SeisIO structure                  | SeisIO file           | wseis
  primitive data type or array          | ASDF AuxiliaryData    | asdf_waux

Methods for SeisEvent, SeisHdr, or SeisSrc structures require loading the Quake submodule with *using SeisIO.Quake*.


***************
Write Functions
***************

HDF5/ASDF
=========
.. function:: write_hdf5(fname, S)

Write data from **S** to file **fname** in a seismic HDF5 format. The default
file format is ASDF.

With ASDF files, if typeof(S) == SeisEvent, **S.hdr** and **S.source** are
written (appended) to the "QuakeML " element.

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
  v     | Integer   | 0         | verbosity

Write Method: Add (**add=true**)
--------------------------------
Initializes new traces (filled with NaNs) of length = **len** as needed, and
overwrite with data in appropriate places.

**add=true** follows these steps in this order:
1. Determine times of all data in **S[chans]** and all traces in "Waveforms/".
2. For all data in **S[chans]** that cannot be written to an existing trace, a new trace of length = **len** sampled at **S.fs[i]** is initialized (filled with NaNs).
3. If a segment in **S[chans]** overlaps a trace in "Waveforms/" (including newly- created traces):
+ Merge the header data in **S[chans]** into the relevant station XML.
+ Overwrite the relevant segment(s) of the trace.

Unless **len** exactly matches the time boundaries of each segment in **S**,
new traces will contain more data than **S**, with the extra samples initialized
to NaNs. Presumably these will be replaced with real data in subsequent
overwrites.

Write Method: Overwrite (**ovr = true**)
----------------------------------------
If **ovr=true** is specified, but **add=false**, **write_hdf5** *only* overwrites *existing* data in **hdf_out**.
* No new trace data objects are created in **hdf_out**.
* No new file is created. If **hdf_out** doesn't exist, nothing happens.
* If no traces in **hdf_out** overlap segments in **S**, **hdf_out** isn't modified.
* Station XML is merged in channels that are partly overwritten.

.. function:: asdf_wqml(fname, H, R[, keywords])
.. function:: asdf_wqml(fname, EV[, KWs])

Write to ASDF "QuakeML " group in file *fname*. In the above function calls, **H** can be a SeisHdr or Array{SeisHdr, 1}; **R** can be a SeisSource or Array{SeisSource, 1}; **EV** can be a SeisEvent or Array{SeisEvent, 1}.

Supported Keywords
******************
.. csv-table::
  :header: KW, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 4

  ovr   | Bool      | false     | Overwrite data in existing traces?
  v     | Integer   | 0         | verbosity


.. function:: asdf_waux(fname, path, X)

Write *X* to AuxiliaryData/path in file *fname*. If an object already exists at
AuxiliaryData/path, it will be deleted and overwritten with *X*.

XML Metadata
============

.. function:: write_sxml(fname, S[, chans=CC])

Write station XML from the fields of **S** to file **fname**. Specify channel numbers to write in a GphysData object with *chans=CC*.

Use keyword **chans=Cha** to restrict station XML write to **Cha**. This
keyword can accept an Integer, UnitRange, or Array{Int64,1} argument.

.. function:: write_qml(fname, H, R[, v=V])
.. function:: write_qml(fname, H, R[, v=V])
    :noindex:

.. function:: write_qml(fname, H[, v=V])
.. function:: write_qml(fname, H[, v=V])
    :noindex:

Write QML to **fname** from SeisHdr (or Array{SeisHdr, 1})**H**, and (optionally) SeisSrc (or Array{SeisSrc, 1})**R**

If **fname** exists, and is QuakeML, SeisIO appends the existing XML. If the
file is NOT QuakeML, an error is thrown; the file isn't overwritten.


Other Formats
=============

.. function:: writesac(S[, chans=CC, fname=FF, v=V])

Write SAC data to SAC files with auto-generated names. With any GphysChannel subtype, specifying *fname=FF* sets the filename to FF. Specify channel numbers to write in a GphysData object with *chans=CC*.

.. function:: writesacpz(pzf, S[, chans=CC])

Write fields from SeisIO structure *S* to SACPZ file *pzf*. Specify which channels to write in a GphysDaya structure with *chans=CC*.

.. function:: wseis(fname, S)
.. function:: wseis(fname, S, T, U...)

Write SeisIO data to file *fname*. Multiple objects can be written at once.
