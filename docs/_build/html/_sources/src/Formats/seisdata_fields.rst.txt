..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>
..    module:: sphinx.ext.mathbase

.. _seisdata_fields:

**********************************
:mod:`Appendix A: Structure and Field Descriptions`
**********************************

Types introduced in SeisIO:

* SeisChannel: Container for one channel of univariate data
* SeisData: Container for multiple channels of univariate data
* SeisHdr: Seismic event header
* SeisEvent: Composite type for events with header and trace data

All field names use lowercase letters.

SeisChannel Fields
==================
====    =====               =====
Name    Type\ :sup:`(a)`    Meaning
====    =====               =====
id      s                   unique channel identifier formated ``nn.sssss.ll.ccc`` (net.sta.loc.chan).\ :sup:`(b)`
name    s                   channel name
src     s                   description of data source
units   s                   units of dependent variable (`UCUM specification <http://unitsofmeasure.org/trac>`_ expected)
fs      f64                 sampling frequency in Hz
gain    f64                 scalar to convert **x** to SI units in "flat" part of frequency spectrum\ :sup:`(c)`
loc     Array{f64,1}        sensor location: [lat, lon, ele, azimuth, incidence]\ :sup:`(d)`
resp    Array{cf64,2}       complex instrument response with zeros in ``resp[i][:,1]``, poles in ``resp[i][:,2]``
misc    Dict{s,Any}         miscellaneous information\ :sup:`(e)`
notes   Array{s,1}          timestamped notes; use ``note!`` to annotate
t       Array{i64,2}        time gaps:ref:`(see below) <seisdata_t>`
x       Array{f64,1}        univariate data
====    =====     =====

SeisData Fields
===============
As SeisChannel, plus

====   =====               =====
Name   Type\ :sup:`(a)`    Meaning
====   =====               =====
n      i64                 number of channels
c      Array{TCPSocket,1}  array of TCP connections
====   =====               =====

SeisHdr Fields
===============
====    =====                       =====
Name    Type\ :sup:`(a)`            Meaning
====    =====                       =====
 id     i64                         event ID
 ot     DateTime                    origin time
 loc    Array{f64, 1}               hypocenter
 mag    Tuple{f32, c, c}            magnitude, mag. scale
 int    Tuple{u8, s}                intensity, int. scale
 mt     Array{f64, 1}               moment tensor: (1-6) tensor, (7) scalar moment, (8) \%dc
 np     Array{Tuple{3xf64},1}       nodal planes
 pax    Array{Tuple{3xf64},1}       principal axes
 src    s                           data source (e.g. url/filename)
====    =====                       =====

SeisEvent Fields
================
====    =====                       =====
Name    Type                        Meaning
====    =====                       =====
 hdr    SeisHdr                     event header
 data   SeisData                    trace data
====    =====                       =====

:sup:`(a)` Abbreviations: s = String, c = Char, f = Float, i = Signed Integer, u = Unsigned Integer.

:sup:`(b)` Subfields of ``id`` should contain only alphanumeric characters.

:sup:`(c)` Gain has an identical meaning to the "Stage 0 gain" of FDSN XML.

:sup:`(d)` azimuth is clockwise from North; incidence of 0 = vertical; both use degrees

:sup:`(e)` Always use typed arrays in ``misc`` (e.g. ``Array{Float64,1}``, never ``Array{Any,1}``). Only (subtypes of) Char, Complex, Real, and String can be saved in SeisIO native file format.

Time Convention
---------------

.. _seisdata_t:

The units of ``t`` are *integer microseconds*, measured from Unix epoch time (1970-01-01T00:00:00.000).

For *regularly sampled* data (``fs > 0.0``), each ``t`` is a sparse delta-compressed representation of *time gaps* in the corresponding ``x``. The first column stores indices of gaps; the second, gap lengths.

Within each time field, ``t[1,2]`` stores the time of the first sample of the corresponding ``x``. The last row of each ``t`` should always take the form ``[length(x) 0]``. Other rows take the form ``[(starting index of gap) (length of gap)]``.

For *irregularly sampled data* (``fs = 0``), ``t`` is a dense delta-compressed representation of *time stamps corresponding to each sample*.
