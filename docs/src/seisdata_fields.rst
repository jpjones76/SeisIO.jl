..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>
..    module:: sphinx.ext.mathbase

.. _seisdata_fields:

**********************************
:mod:`Appendix A: SeisData Fields`
**********************************
All field names use lowercase letters. SeisData and SeisChannel types have identical field types; SeisData objects have the additional field ``n``.


Field Names and Meanings
========================
* ``n``: (SeisData only) number of channels

* ``id``: unique channel identifier, formated using the subfields ``nn.sssss.ll.ccc``. Contains no whitespace.

  * ``nn``: two-letter network code

  * ``sssss``: station code, up to five characters

  * ``ll``: location code, typically numeric

  * ``ccc``: channel code; follow the `SEED format appendices  <http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf>`_

* ``name``: unique freeform string for channel name\ :sup:`(a)`

* ``src``: freeform string describing data source\ :sup:`(a)`

*  ``fs``: sampling frequency in Hz

* ``gain``: scalar value by which data are divided to obtain measurements in SI units in the "flat" part of the frequency spectrum

* ``units``: units of the dependent variable (MKS is recommended, with "m/s" for velocity and "m/s/s" for acceleration)\ :sup:`(a)`

* ``loc``: sensor location, a 5-entry vector of the form [lat, lon, ele, |thgr|, |phgr|]

  * lat: latitude in decimal degrees (+ = North)

  * lon: longitude in decimal degrees (+ = East)

  * ele: elevation in meters above sea level

  * |thgr|: channel azimuth in degrees clockwise from North

  * |phgr|: channel incidence in degrees from vertical

* ``resp``: complex instrument response (poles and zeros), with zeros in ``resp[:,1]`` and poles in ``resp[:,2]``

* ``misc``: dictionary of miscellaneous information

* ``notes``: array of notes

* ``t``: pseudo-sparse two-column array of times :ref:`(see below) <seisdata_t>`

* ``x``: vector of sample data


:sup:`(a)` Only the first 26 characters of each channel's ``name``, ``units``, and ``src`` strings are written to file. Longer strings are truncated.


Notes on Specific Fields
========================

``id``
------
Subfields of ``id`` should contain alphanumeric characters.  An ``id`` value shouldn't contain whitespace. Never set a ``name`` field to an ``id`` field of a different channel.

``gain``
--------
The ``gain`` field has an identical meaning to the "Stage 0" gain of FDSN/SeedLink station/channel XML files.

``misc``
--------
Always use static types to declare arrays in ``misc`` (e.g. ``Array{Float64,N}``; never ``Array{Any,N}``). Although values in ``misc`` can be of any type, there are strict limitations on what value types can be saved to disk:

Scalars and single-type arrays of the follwoing types are OK: ``Char, Complex64, Complex128, DirectIndexString, Float32, Float64, Integer, Unsigned``. Other types will be ignored during file write and warning messages will be given when non-writable values are encountered. Subtypes of the listed types are OK; for example, ``ASCIIString`` and ``Array{ASCIIString,N}`` are both supported.

``notes``
---------
The ``notes`` array grows automatically as data are modified. Any ``merge`` or ``sync`` operation is automatically noted. Additional notes can be written manually using the ``note`` command.

.. _seisdata_t:

``t``
-----
For *time series data* ``x``, ``t`` is a sparse delta-compressed representation of *time gaps in microseconds* in ``x``. The first column stores *indices*; the second column stores *gap lengths*.

* The second column of the first row, i.e. ``t[1,2]``, always stores the *time of the first sample* in ``x`` relative to the Unix epoch (e.g. ``t[1,2] = 10`` means the time series begins at 1970-01-01T00:00:00.000010 UTC).

* The last row of ``t`` should always take the form ``[length(x) 0.0]``.

* Other rows should take the form ``[(starting index of gap in x) (length of gap)]``.

For *irregularly sampled data* (``fs = 0``), ``t`` is a dense delta-compressed representation of *time stamps in microseconds for each sample*. ``t`` for irregularly sampled data has a single column, but is treated by Julia as a two-dimensiona array (not a one-dimensional vector).


*********************************
:mod:`Appendix B: SeisHdr Fields`
*********************************
All field names use lowercase letters.


Field Names and Meanings
========================
* ``id``: event ID

* ``time``: origin time

* ``lat``: source latitude; + = North

* ``lon``: source longitude; + = East

*  ``dep``: source depth in km; + = down

* ``mag``: magnitude

* ``mag_typ``: magnitude type (scale)

* ``mag_auth``: magnitude author

* ``auth``: event author

* ``cat``: source catalog

* ``contrib``: solution contributor

* ``contrib_id``: contributor numeric ID

* ``loc_name``: freeform location name
