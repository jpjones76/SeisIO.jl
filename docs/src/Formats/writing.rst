.. _write:

##############
Write Suppport
##############
The table below sumamrizes the current write options for SeisIO. Each function is described in detail in this chapter.

.. csv-table::
  :header: Structure/Description, Output Format, Function, Submodule
  :delim: |
  :widths: 2, 2, 1, 1

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

Methods for SeisEvent, SeisHdr, or SeisSrc are part of submodule SeisIO.Quake. *asdf_waux* and *asdf_wqml* are part of :ref:`SeisIO.SeisHDF.<seishdf>`.

.....

***************
Write Functions
***************
Functions are organized by file format.

HDF5/ASDF
=========
.. function:: write_hdf5(fname, S)

Write data from **S** to file **fname** in a seismic HDF5 format. The default file format is ASDF.

With ASDF files, if typeof(S) == SeisEvent, **S.hdr** and **S.source** are written (appended) to the "QuakeML " element.

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
Initializes new traces (filled with NaNs) of length = **len** as needed, and overwrite with data in appropriate places.

**add=true** follows these steps in this order:
1. Determine times of all data in **S[chans]** and all traces in "Waveforms/".
2. For all data in **S[chans]** that cannot be written to an existing trace, a new trace of length = **len** sampled at **S.fs[i]** is initialized (filled with NaNs).
3. If a segment in **S[chans]** overlaps a trace in "Waveforms/" (including newly- created traces):
+ Merge the header data in **S[chans]** into the relevant station XML.
+ Overwrite the relevant segment(s) of the trace.

Unless **len** exactly matches the time boundaries of each segment in **S**, new traces will contain more data than **S**, with the extra samples initialized to NaNs. Presumably these will be replaced with real data in subsequent overwrites.

Write Method: Overwrite (**ovr = true**)
----------------------------------------
If **ovr=true** is specified, but **add=false**, **write_hdf5** *only* overwrites *existing* data in **hdf_out**.
* No new trace data objects are created in **hdf_out**.
* No new file is created. If **hdf_out** doesn't exist, nothing happens.
* If no traces in **hdf_out** overlap segments in **S**, **hdf_out** isn't modified.
* Station XML is merged in channels that are partly overwritten.

.....

QuakeML
=======

.. function:: write_qml(fname, Ev::SeisEvent; v::Integer=0)

Write event metadata from SeisEvent `Ev` to file `fname`.
:raw-html:`<br /><br />`

.. function:: write_qml(fname, SHDR::SeisHdr; v::Integer=0)
.. function:: write_qml(fname, SHDR::Array{SeisHdr,1}; v::Integer=0)

Write QML to file `fname` from `SHDR`.

If `fname` exists, and is QuakeML, SeisIO appends the existing XML. If the
file exists, but is NOT QuakeML, an error is thrown; the file isn't overwritten.
:raw-html:`<br /><br />`

write_qml(fname, SHDR::SeisHdr, SSRC::SeisSrc; v::Integer=0)
write_qml(fname, SHDR::Array{SeisHdr,1}, SSRC::Array{SeisSrc,1}; v::Integer=0)

Write QML to file `fname` from `SHDR` and `SSRC`.

**Warning**: To write data from SeisSrc structure *R* in array *SSRC*, it must
be true that R.eid == H.id for some *H* in array *SHDR*.

.....

SAC
===

.. function:: writesac(S::GphysData, chans=CC, v=V)
.. function:: writesac(C::GphysChannel; chans=CC, fname=FF, v=V)

Write SAC data to SAC files with auto-generated names. With any GphysChannel subtype, specifying *fname=FF* sets the filename to FF.
:raw-html:`<br /><br />`

.. function:: writesacpz(pzf, S[, chans=CC])

Write fields from SeisIO structure *S* to SACPZ file *pzf*. Specify which channels to write in a GphysDaya structure with *chans=CC*.

SeisIO Native
=============

.. function:: wseis(fname, S)
.. function:: wseis(fname, S, T, U...)

Write SeisIO data to file *fname*. Multiple objects can be written at once.

Station XML
===========

.. function:: write_sxml(fname, S[, chans=CC])

Write station XML from the fields of **S** to file **fname**. Specify channel numbers to write in a GphysData object with *chans=CC*.

Use keyword **chans=Cha** to restrict station XML write to **Cha**. This keyword can accept an Integer, UnitRange, or Array{Int64,1} argument.
