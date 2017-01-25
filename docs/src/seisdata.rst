..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>
..    module:: sphinx.ext.mathbase

.. _seisdata:

***************
:mod:`SeisData`
***************
SeisData is a minimalist container type designed for discretely sampled sequential signals, including (but not limited to) time-series data. It can hold both regularly sampled (time series) data and irregularly sampled measurements.

SeisData and SeisChannel containers can be manipulated using standard Julia commands. The rest of this section explains this functionality in detail.


Creating Data Containers
========================
SeisData and SeisChannel containers can be created in three ways:

#. ``S = SeisData()`` initializes an empty SeisData container

#. ``S = SeisChannel()`` initializes a new SeisChannel container

#. ``S = SeisData(s1, s2, s3)`` creates a SeisData container by merging s1, s2, s3. If a variable passed to SeisData in this way isn't of type SeisData or SeisChannel, it's ignored with a warning.

Fields can be initialized by name when a new SeisChannel container is created; for example,``S = SeisChannel(name="DEAD CHANNEL", fs=50)`` initialize a SeisChannel with name "DEAD CHANNEL", fs = 50.


Example
--------
```S = SeisData(SeisChannel(name="BRASIL", id="IU.SAML.00.BHZ"), SeisChannel(name="UKRAINE", id="IU.KIEV.00.BHE"), SeisChannel())`` creates* a new SeisData structure with three channels; the first is named "BRASIL", the second "UKRAINE", the third is blank. This syntax requires unique IDs for each new channel created.


Adding Data
===========
``+`` (the addition operator) is the standard way to add data channels. Addition attempts to merge data with matching channel IDs. Channels with unique IDs are simply assigned to new channels. ``merge!`` and ``+`` are identical commands for SeisData and SeisChannel instances.

Data can be merged directly from the output of any SeisIO command that outputs a compatible structure. For example:

``S += r_sac(sacfile.sac)`` merges data from sacfile.sac into S in place.

``T = S + SeedLink("myconfig", t=300)`` merges 300 seconds of SeedLink data into S, where the data are acquired using config file "myconfig".

In a merge operation, pairs of non-NaN data `x`:sub:`i`, `x`:sub:`j` with overlapping time stamps (i.e. `t`:sub:`i` - `t`:sub:`j` < 1/fs) are *averaged*.



Appending without merging
-------------------------
``push!`` adds a SeisChannel instance to a SeisData instance without attempting to merge the channel with existing data. ``append!`` adds a SeisData instance to another SeisData instance without attempting to merge identical channels.

``push!(S,T)`` assigns each channel in T to a new channel in S, even if it creates redundant channel IDs.

``push!(S,S)`` appends a duplicate of each channel in S to S.



Deleting Data
=============
``-`` (the subtraction operator) is the standard way to delete unwanted data channels. It's generally safest to use e.g. ``T = S - i``, but in-place deletion (e.g. ``S -= i``) is valid. The exact behavior for a general operation ``S - K`` depends on the data type of the addend:

Methods
-------
``S - i``, where ``i`` is an integer, deletes the ``i``\ th channel of S.

``S - str``, where ``str`` is a string, deletes all channels whose names and ids match ``str``.

``S - U``, where ``U`` is a SeisChannel instance, deletes all channels from ``S`` with the same id value as ``U.id``.

``deleteat!(S,i)`` is identical to ``S-=K`` for integer K.


Safe deletion with ``pull``
===========================
The ``pull`` command extracts a channel from a SeisData instance and returns it as a SeisChannel.

Methods
-------
``T = pull(S, name)``, where ``name`` is a string, creates a SeisChannel ``T`` from the first channel with name=``name``, then removes the matching channel from ``S``.

``T = pull(S, i)``, where ``i`` is an integer, creates a SeisChannel ``T`` from channel ``i``, then removes channel ``i`` from ``S``.


Index, Search, Sort
===================
Individual channels in a SeisData container can be accessed by channel index; for example, ``S[3]`` returns channel 3. Indexing a single channel outputs a SeisChannel instance; indexing a range of channels outputs a new SeisData object.

The same syntax can be used to ovewrwrite data by channel (or channel range). For example, ``S[2] = T``, where T is a SeisChannel instance, replaces the second channel of S with T.

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
SeisData and SeisChannel are intended to be annotated as data are analyzed; the command ``note`` exists for this purpose. Calling ``note`` appends a timestamped note to the ``notes`` field of the target container.

* ``note(S, i, NOTE)`` adds string ``NOTE`` to channel ``i`` of ```S``.

* ``S += "NAME: NOTE"``, adds a note with a short form date. NAME should be the intended channel name; NOTE should be the intended note content.

* The command ``S += NOTE`` adds the text of string ``NOTE`` to all channels.


Utility Functions
=================
* ``autotap!``: Apply a cosine taper to non-gap subsequences of all time series data.  Removes the mean of all time series channels. Calls ``ungap!``.

* ``prune!, prune``: Merge channels with redundant header fields.

* ``purge!, purge``: Delete all channels with no data (defined for any channel ``i`` by ``isempty(S.x[i]) == true``).

* ``randseisdata()``: Generate a SeisData structure with pseudo-random headers and data. Specify ``c=false`` to allow campaign-style channels with ``fs=0``. Specify an integer argument to set the number of channels; otherwise, ``S.n`` varies from 12 to 24.

* ``randseisobj()``: Generate a Seisobj structure with pseudo-random headers and data.

* ``sync!, sync``: Synchronize time windows for all channels and fill time gaps. Calls ``autotap!``, which in turn de-means and calls ``ungap!``.

* ``ungap!, ungap``: Fill all time gaps in each channel of regularly sampled data. By default, invoking ``ungap!`` alone cosine tapers non-gap subsequences of time series data (keyword ``w=true``), and fills time gaps with the mean of non-NaN data points (keyword ``m=true``).


Native File I/O
===============
Use ``rseis`` and ``wseis`` to read and save in native format. Use ``writesac(S)`` to save trace data in ``S`` to single-channel :ref:`SAC <sac1>` files.

The SAC file format is widely used and well-supported, but writes in single-precision format. Rudimentary time stamping is enabled by default. Time stamped SAC files from SeisIO are treated by the SAC program as unevenly spaced, generic ``x-y`` data (``LEVEN=0, IFTYPE=4``). However, third-party readers might interpret timestamped files less predictably: timestamped data *might* be loaded as the real part of a complex time series, with the time values stored as the imaginary part...or they might load the other way around...or they might not load at all.
