..    include:: <isonum.txt>
..    include:: <isogrk1.txt>
..    include:: <isoamsr.txt>

.. _seisdata:

##########
Data Types
##########

* SeisChannel: single-channel univariate data
* SeisData: multi-channel univariate data
* SeisHdr: seismic event header
* SeisEvent: composite type for events with header and trace data

Data types in SeisIO can be manipulated using standard Julia commands.

**************
Initialization
**************

SeisChannel
===========
.. function:: SeisChannel()

Initialize an empty SeisChannel structure.

.. function:: SeisChannel(; [KWs])

Set fields at creation by specifying fieldnames as keywords, e.g. **SeisChannel(fs=100.0)** creates a new SeisChannel structure with fs = 100.0 Hz.

SeisData
========
.. function:: SeisData()

Initialize an empty SeisData structure. Fields cannot be set at creation.

.. function:: SeisData(n)

Initialize an empty SeisData structure with S.n channel containers.

.. function:: SeisData(S::SeisData, Ev::SeisEvent, C1::SeisChannel, C2::SeisChannel)

Create a SeisData structure by copying S and appending Ev.data, C1, and C2. This syntax can be used to form a new SeisData structure from arbitrary combinations of SeisData and SeisChannel objects.

SeisHdr, SeisEvent
==================
.. function:: SeisHdr()

Create an empty SeisHdr structure.

.. function:: SeisHdr(; KWs)

Set fields at creation by specifying fieldnames as keywords.

.. function:: SeisEvent()

Initialize an empty SeisEvent structure with an empty SeisHdr in .hdr and an empty SeisData in .data.


Example
=======
Create a new SeisData structure with three channels
::

  C1 = SeisChannel(name="BRASIL", id="IU.SAML.00.BHZ")
  C2 = SeisChannel(name="UKRAINE", id="IU.KIEV.00.BHE")
  S = SeisData(C1, C2, SeisChannel(name="CHICAGO"))


SeisData Indexing
=================
Individual channels in a SeisData structure can be accessed by channel index. Indexing a single channel, e.g. **C=S[3]**, outputs a SeisChannel; indexing several outputs a new SeisData structure.

The same syntax can be used to ovewrwrite data by channel (or channel range). For example, **S[2] = T**, where T is a SeisChannel instance, replaces the second channel of S with T.

Multiple channels in a SeisData structure S can be overwritten with another SeisData structure T using **setindex!(S, T, I)**; the last input is the range of indices in S to overwrite (which must satisfy **length(I) == T.n**).

*Julia is a "pass by reference" language*. The precaution here is best illustrated by example: if we assign **T = S[2]**, subsequent changes to **T** modify **S[2]** in place.

********************
Commands by Category
********************
SeisIO extends a number of built-in Julia methods to work with its custom data types. In addition, many custom functions exist to simplify processing.


Append, Merge
=============

.. function:: append!(S::SeisData, U::SeisData)

Append all channels in **U** to **S**. No checks against redundancy are performed; can result in duplicate channels (fix with **merge!(S)**).

.. function:: merge!(S::SeisData, U::SeisData)
.. function:: S += U

Merge **U** into **S**. Also works if **U** is a SeisChannel structure. Merges are based on matching channel IDs; channels in **U** without IDs in **S** are simply assigned to new channels. **merge!** and **+=** work identically for SeisData and SeisChannel instances.

Data can be merged directly from the output of any SeisIO command that outputs a compatible structure; for example, **S += readsac(sacfile.sac)** merges data from **sacfile.sac** into S.

For two channels `i`, `j` with identical ids, pairs of non-NaN data `x`:sub:`i`, `x`:sub:`j` with overlapping time stamps (i.e. \| `t`:sub:`i` - `t`:sub:`j` \| < 0.5/fs) are *averaged*.

.. function:: merge!(S::SeisData)

Applying **merge!** to a single SeisData structure merges pairs of channels with identical IDs.


Delete, Extract
===============
.. function:: delete!(S::SeisData, j)
.. function:: deleteat!(S::SeisData, j)
.. function:: S-=j

Delete channel number(s) **j** from **S**. **j** can be an Int, UnitRange, Array{Int,1}, a String, or a Regex. In the last two cases, any channel with an id that matches **j** will be deleted; for example, **S-="CC.VALT"** deletes all channels whose IDs match **"CC.VALT"**.

.. function:: T = pull(S, i)

If **i** is a string, extract the first channel from **S** with **id=i** and return it as a new SeisData structure **T**. The corresponding channel in **S** is deleted. If **i** is an integer, **pull** operates on the corresponding channel number.

.. function:: purge!(S)

Remove all empty channels from **S**. Empty channels are defined as the set of all channel indices **i** s.t. **isempty(S.x[i]) = true**.


Read, Write
===========
.. function:: A = rseis(fname::String)
   :noindex:

Read SeisIO data from **fname** into an array of SeisIO structures.

.. function:: wsac(S)
  :noindex:

Write SAC data from SeisData structure **S** to SAC files with auto-generated names. SAC data can only be saved to single precision.

Specify **ts=true** to write time stamps. Time stamped SAC files created by SeisIO are treated by the SAC program itself as unevenly spaced, generic **x-y** data (**LEVEN=0, IFTYPE=4**). Third-party readers might interpret timestamped files less predictably: depending on the reader, timestamped data might be loaded as the real part of a complex time series, with time stamps as the imaginary part ... or the other way around ... or they might not load at all.

.. function:: wseis(fname::String, S)
  :noindex:

Write SeisIO data from S to **fname**. Supports splat expansion for writing multiple objects, e.g. **wseis(fname, S, T, U)** writes **S**, **T**, and **U** to **fname**.

To write arrays of SeisIO objects to file, use "splat" notation: for example, for an array **A** of type **Array{SeisEvent,1}**, use syntax **wseis(fname, A...)**.


Search, Sort
=============
.. function:: sort!(S::SeisData, rev=false)

In-place sort by **S.id**. Specify **rev=true** to reverse the sort order.

.. function:: i = findid(S, C)

Return the index of the first channel in S with id matching **C**. If **C** is a string, **findid** is equivalent to **findfirst(S.id.==C)**; if **C** is a SeisChannel, **findid** is equivalent to **findfirst(S.id.==C.id)**.
