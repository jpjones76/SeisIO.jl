#####
Nodal
#####

The Nodal submodule is intended to handle data from nodal arrays. Nodal arrays
differ from standard seismic data in that the start and end times of data
segments are usually synchronized.

************************
Reading Nodal Data Files
************************
.. function:: S = read_nodal(fmt, fname [, KWs])

Read data in file format *fmt* from file *fname* into memory. Returns a NodalData object.

Supported Keywords
==================

.. csv-table::
  :header: KW, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 2, 2

  chans   | ChanSpec  | Int64[]               | channels to read
  nn      | String    | N0                    | network subfield in `:id`
  s       | TimeSpec  | 0001-01-01T00:00:00   | start time
  t       | TimeSpec  | 9999-12-31T12:59:59   | end time
  v       | Integer   | 0                     | verbosity

Non-Standard Behavior
---------------------
Real values supplied to keywords ``s=`` and ``t=`` are treated as seconds *relative to file begin time*. Most SeisIO functions that accept TimeSpec arguments treat Real values as seconds relative to ``now()``.

Supported File Formats
======================
.. csv-table::
  :header: File Format, String, Notes
  :delim: |
  :widths: 1, 1, 3

  Silixa TDMS | silixa    | Limited support; see below
  SEG Y       | segy      | Field values are different from *read_data* output


Silixa TDMS Support Status
--------------------------
* Currently only reads file header and samples from first block

* Not yet supported (test files needed):

  * first block additional samples

  * second block

  * second block additional samples

* Awaiting manufacturer clarification:

  * parameters in *:info*

  * position along cable; currently loc.(x,y,z) = 0.0 for all channels

  * frequency response; currently ``:resp`` is an all-pass placeholder


Nodal SEG Y Support Status
--------------------------
See :ref:`SEG Y Support<segy-support>`.


******************************
Working with NodalData objects
******************************

NodalData objects have one major structural difference from SeisData objects:
the usual data field *:x* is a set of views to an Array{Float32, 2} (equivalent
to a Matrix{Float32}) stored in field *:data*. This allows the user to apply
two-dimensional data processing operations directly to the data matrix.

NodalData Assumptions
=====================

* ``S.t[i]`` is the same for all *i*.

* ``S.fs[i]`` is constant for all *i*.

* ``length(S.x[i])`` is constant for all *i*.


Other Differences from SeisData objects
=======================================

* Operations like *push!* and *append!* must regenerate ``:data`` using ``hcat()``, and therefore consume a lot of memory.

* Attempting to *push!* or *append!* channels of unequal length throws an error.

* Attempting to *push!* or *append!* same-length channels with different ``:t`` or ``:fs`` won't synchronize them! You will instead have columns in ``:data`` that aren't time-aligned.

* Irregularly-sampled data (``:fs = 0.0``) are not supported.


*****
Types
*****
See docstrings for field names and descriptions.

.. function:: NodalLoc

Nodal location. Currently only stores position along optical cable.
:raw-html:`<br /><br />`

.. function:: NodalData

Structure to hold nodal array data. Similar to a SeisData object.
:raw-html:`<br /><br />`

.. function:: NodalChannel

A single channel of data from a nodal array. Similar to a SeisChannel object.
