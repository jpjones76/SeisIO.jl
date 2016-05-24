..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>
..    module:: sphinx.ext.mathbase

.. _seisdata:

***************
:mod:`SeisData`
***************
SeisData is a minimalist container type designed for discretely sampled sequential signals, including (but not limited to) time-series data. It can hold both regularly sampled (time series) data and irregularly sampled measurements.

SeisData and SeisObj containers can be manipulated using standard Julia commands. The rest of this section explains this functionality in detail.


Creating Data Containers
========================
SeisData and SeisObj containers can be created in three ways:

#. ``S = SeisData()`` initializes an empty SeisData container

#. ``S = SeisObj()`` initializes a new SeisObj container

#. ``S = SeisData(s1, s2, s3)`` creates a SeisData container by merging s1, s2, s3. If a variable passed to SeisData in this way isn't of type SeisData or SeisObj, it's ignored with a warning.

Fields can be initialized by name when a new SeisObj container is created; for example,``S = SeisObj(name="DEAD CHANNEL", fs=50)`` initialize a SeisObj with name "DEAD CHANNEL", fs = 50.


Example
--------
```S = SeisData(SeisObj(name="BRASIL", id="IU.SAML.00.BHZ"), SeisObj(name="UKRAINE", id="IU.KIEV.00.BHE"), SeisObj())`` creates* a new SeisData structure with three channels; the first is named "BRASIL", the second "UKRAINE", the third is blank. This syntax requires unique IDs for each new channel created.


Adding Data
===========
``+`` (the addition operator) is the standard way to add data channels. Addition attempts to merge data with matching channel IDs. Channels with unique IDs are simply assigned to new channels. ``merge!`` and ``+`` are identical commands for SeisData and SeisObj instances.

Data can be merged directly from the output of any SeisIO command that outputs a compatible structure. For example:

``S += r_sac(sacfile.sac)`` merges data from sacfile.sac into S in place.

``T = S + SeedLink("myconfig", t=300)`` merges 300 seconds of SeedLink data into S, where the data are acquired using config file "myconfig".

In a merge operation, pairs of non-NaN data `x`:sub:`i`, `x`:sub:`j` with overlapping time stamps (i.e. `t`:sub:`i` - `t`:sub:`j` < 1/fs) are *averaged*.



Appending without merging
-------------------------
``push!`` adds a SeisObj instance to a SeisData instance without attempting to merge the channel with existing data. ``append!`` adds a SeisData instance to another SeisData instance without attempting to merge identical channels.

``push!(S,T)`` assigns each channel in T to a new channel in S, even if it creates redundant channel IDs.

``push!(S,S)`` appends a duplicate of each channel in S to S.



Deleting Data
=============
``-`` (the subtraction operator) is the standard way to delete unwanted data channels. It's generally safest to use e.g. ``T = S - i``, but in-place deletion (e.g. ``S -= i``) is valid. The exact behavior for a general operation ``S - K`` depends on the type of the addend:

  * If K is an integer, channel k is deleted from S.

  * If K is a string, all channels whose names and ids match k are deleted.

  * If K is a SeisObj instance, all channels from S with the same id as k are deleted.

``deleteat!(S,i)`` is identical to ``S-=K`` for an integer K.


Safe deletion with ``pull``
---------------------------
The ``pull`` command extracts a channel from a SeisData instance and returns it as a SeisObj.
```T = pull(S, name)``, where ``name`` is a string, creates a SeisObj ``T`` from the first channel with name=``name``. The channel is removed from `S`.
+ `T = pull(S, i)`, where `i` is an integer, creates a SeisObj `T` from
channel `i` and removes channel `i` from `S`.


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


Annotation
==========
SeisData and SeisObj are intended to be annotated as data are analyzed; the command ``note`` exists for this purpose. Calling ``note`` appends a timestamped note to the ``notes`` field of the target container.

* ``note(S, i, NOTE)`` adds string ``NOTE`` to channel ``i`` of ```S``.

* ``S += "NAME: NOTE"``, adds a note with a short form date. NAME should be the intended channel name; NOTE should be the intended note content.

* The command ``S += NOTE`` adds the text of string ``NOTE`` to all channels.


Utility Functions
=================
* ``plotseis``: Plot time-aligned data from a SeisData object. Time series data are represented by straight lines; irregularly sampled data (``fs=0``) use normalized stem plots.

* ``prune!, prune``: Merge channels with redundant header fields.

* ``purge!, purge``: Delete all channels with no data (defined for any channel ``i`` by ``isempty(S.x[i]) == true``).

* ``sync!, sync``: Synchronize time windows for all channels and fill time gaps. Calls ``ungap!`` at invocation.

* ``ungap!, ungap``: Fill all time gaps in each channel of regularly sampled data.

* ``autotap!``: Cosine taper time series data around time gaps.



Native File I/O
===============
Use ``rseis`` and ``wseis`` to read and save in native format. ``writesac(S)`` saves trace data in ``S`` to single-channel :ref:`SAC <sac1>` files. SAC is widely used and well-supported, but writes data in single-precision format with rudimentary time stamping. The last point merits brief discussion. Time stamps are written to SAC by default (change this with kw ``ts=false``). Tme stamped SAC data are treated by SAC itself as unevenly spaced, generic ``x-y`` data (``LEVEN=0, IFTYPE=4``). However, third-party SAC readers interpret such files less predictably: timestamped data *might* be loaded as the real part of a complex time series, with the time values themselves as the imaginary part...or the other way around...or not at all.
