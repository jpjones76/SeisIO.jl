..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>
..    module:: sphinx.ext.mathbase

***************
:mod:`SeisData`
***************
SeisData is a minimalist memory-resident working format for discretely sampled, time-dependent data. It can hold both regularly sampled (time series) data and irregularly sampled measurements.

SeisData and SeisObj instances can be manipulated using standard Julia commands. The rest of this section explains this functionality in detail.


Creating Data Containers
========================
* ``S = SeisData()``

  initialize an empty SeisData container

* ``S = SeisObj()``

  initialize a new SeisObj container

* ``S = SeisData(s1, s2, s3)``

  create a SeisData container by merging s1, s2, s3.

When using the third syntax, if a merge variable isn't of class SeisData or SeisObj, it's ignored with a warning.

Fields can be initialized by name when a new SeisObj container is created.

* ``S = SeisObj(name="DEAD CHANNEL", fs=50)``

  initialize a SeisObj with name "DEAD CHANNEL", fs = 50.



Adding Data
===========
``+`` (the addition operator) is the standard way to add data channels. Addition attempts to merge data with matching channel IDs. Channels with unique IDs are simply assigned as new channels. ``merge!`` and ``+`` work identically on SeisData and SeisObj containers.

Data can be merged from any file read or data acquisition command that outputs a SeisData or SeisObj structure.

* ``S += r_sac(sacfile.sac)``

  merge data from sacfile.sac into S in place.

* ``T = S + SeedLink("myconfig", t=300)``

  merge 300 seconds of SeedLink data into S using config file "myconfig".

* In a merge operation, pairs of data `x`:sub:`i`, `x`:sub:`j` with overlapping time stamps (i.e. `t`:sub:`i` - `t`:sub:`j` |le| 1/fs) are *averaged*.


Appending without merging
-------------------------
``push!`` adds channels without attempting to merge.

* ``push!(S,T)``

  assign each channel in T to a new channel in S, even if it creates redundant channel IDs.

* ``push!(S,S)``

  append a duplicate of each channel in S to S.



Deleting Data
=============
``-`` (the subtraction operator) is the standard way to delete unwanted data channels. It's generally safest to use e.g. ``T = S - i``, but in-place deletion (e.g. ``S -= i``) is valid.

* ``S - k``

  * If k is an integer, channel k is deleted from S.

  * If k is a string, all channels whose names and ids match k are deleted.

  * If k is a SeisObj instance, all channels from S with the same id as k are deleted.

* ``deleteat!(S,i)``

  identical to ``S-=i`` for an integer i.



Index, Search, Sort
===================
Individual channels in a SeisData container can be accessed by channel index; for example, ``S[3]`` returns channel 3. Indexing a single channel outputs a SeisObj instance; indexing a range of channels outputs a new SeisData object.

The same syntax can be used to ovewrwrite data by channel (or channel range). For example, ``S[2] = T``, where T is a SeisObj instance, replaces the second channel of S with T.

Multiple channels in a SeisData container S can be overwritten with another SeisData container T using ``setindex!(S, T, I)``; the last input is a range of indices.

*Julia is a "pass by reference" language*. The precaution here is best illustrated by example. If one uses index assignment, e.g. ``S[2] = T``, subsequent changes to T also modify S[2].


Search, Sort, Equality
----------------------
The ``sort!`` command sorts channels by id in lexicographical order.

The following commands offer search functionality:

* ``findid(S,id)``: search for channels with S.id == id.

* ``findid(S,T)``: find all channels with S.id == T.id.

* ``hasid(S,id)``: true if S has a channel id that matches id.

* ``hasname(S,name)``: true if S has a channel name that matches name.

* ``findname(S,name)``: search for channels with S.name == name.

The following commands offer tests for equality:

* ``samehdr(S,T)``: true if S, T contain identical header information (``id, fs, gain, loc, resp``).

* ``==`` and ``isequal`` test for equality.



Utility Functions
=================
* ``note``: Add a timestamped note.

* ``plotseis``: Plot time-aligned data. Time series data are represented by straight lines; irregularly sampled data (``fs=0``) use normalized stem plots.

* ``prune!, prune``: Merges channels with redundant header fields.

* ``purge!, purge``: Deletes all channels with no data (defined for any channel i as isempty(S.x[i]) == true).

* ``sync!, sync``: Synchronize time windows for all channels and fill time gaps.  Calls ungap at invocation.

* ``ungap!, ungap``: Fill all time gaps in each channel of regularly sampled data.



Native File I/O
===============
Use ``rseis`` and ``wseis`` to read and save in native format. ``wsac(S)`` saves
trace data in ``S`` to single-channel SAC files.

Advantages/Disadvantages of SAC

+ Very widely used.

- Only uses single-precision format.

- Rudimentary time stamping.

The last point merits brief discussion. Time stamps aren't written to SAC with ``wsac`` by default (change by setting keyword ``ts=true``). If you write time stamps to SAC files, the data are treated by SAC itself as unevenly spaced, generic `x-y` data (`LEVEN=0, IFTYPE=4`). This causes issues with SAC readers in some other languages; timestamped data might be loaded as the real part of a complex time series, with the time values themselves as the imaginary part...or the other way around, depending on the reader.



SeisData and SeisObj Fields
===========================
All field names use lowercase letters.

* ``id``: Unique channel identifier, formated ``nn.sssss.ll.ccc``. Valid ID subfields contain no whitespace and cannot contain any of the characters ,\!@#$%^&*()+/~\~.:| within a subfield.

  * ``nn``: two-letter network code

  * ``sssss``: station code, up to five characters.

  * ``ll``: location code, typically numeric.

  * ``ccc``: channel code, e.g. EHZ. See `SEED v2.4, Appendix A  <http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf>`_ for a full list of channel codes.

* ``name``: Unique freeform string for the channel name. :sup:`(a)`

* ``src``: Short, freeform string describing the data source.  Usually auto-set by the reader. :sup:`(a)`

*  ``fs``: Sampling frequency in Hz.

   * For non-time series data (e.g. campaign GPS, gas flux, etc.), set ``fs = 0``. This affects the behavior of several commands, including synchronization with ``sync``; it also affects the behavior and expected structure of field ``t``.

* ``gain``: Scalar value to divide from data to obtain measurements in SI units in the "flat" part of the frequency spectrum. Identical meaning to the "Stage 0" gain of FDSN/SeedLink XML files.

* ``units``: Units of the dependent variable. MKS units are strongly recommended, with "/s" for velocity and "/s/s" for acceleration (e.g. "m/s/s" for seismic accelerometer data). :sup:`a`

* ``loc``: Ssnsor location, a 5-entry vector: ``[lat, lon, ele, |thgr|, |phgr|]``

  * ``lat``: latitude in decimal degrees; N is positive.

  * ``lon``: longitude in decimal degrees; E is positive.

  * ``ele``: elevation in meters above sea level (asl).

  * ``|thgr|``: channel azimuth in degrees, measured clockwise from North.

  * ``|phgr|``: channel incidence in degrees, measured from vertical.

* ``resp``: instrument frequency response (poles and zeros). Stored for each channel as a two-column matrix ``r``, with zeros in ``r[:,1]`` and poles in ``r[:,2]``.

* ``misc``: dictionary of miscellaneous information. Although key values can be of any type, there are strict conventions for what can be saved to disk:

  * Scalars and single-type arrays of these types: Char, Unsigned, Integer, Float, Complex, DirectIndexString. Other types will be ignored on file, write and produce warning messages.

  * Subtypes of the above types are OK.

  * *Do not store mixed type arrays in ``misc``*. Not only will they not be written correctly to disk, they'll break file write.

* ``notes``: array of notes describing modifications to the data. Notes can be logged with time stamps using the ``note`` command.

* ``t``: pseudo-sparse two-column array of times.

  * For time series data, ``t`` is a sparse delta-encoded representation of time gaps. Indices are stored in the first column, values in the second column.

      * The second column of the first row stores the time series begin time relative to the Unix epoch (0.0 = 1970-01-01T00:00:00).

      * The last row always takes the form ``[length(x) 0.0]``, where ``x`` is the corresponding data.

      * Other rows take the form ``[(start of gap in x) (length of gap)]``, where ``x`` is the corresponding data.

      * The ``ungap`` command fills all gaps with the mean of non-null values in ``x``. The ``sync`` command calls ``ungap`` automatically at invocation.

  * For irregularly sampled data, ``t`` is a sparse delta-encoded representation of sample times. Only the second column of ``t`` is used.

* ``x``: vector of sample data.

* ``n``: (SeisData only) number of channels in a SeisData object.


:sup:`(a)` Only the first 26 characters of each channel's name, units, and src values are saved to file.


Common Sense Precautions
------------------------
Or, "how not to break things".

* Never set a channel ``name`` to the ``id`` of a different channel.

* Use static typing to declare arrays in ``misc``.
