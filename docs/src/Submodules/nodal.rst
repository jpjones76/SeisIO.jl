#####
Nodal
#####

The Nodal submodule is intended to handle data from nodal arrays. Nodal arrays
differ from standard seismic data in that the start and end times of data
segments are usually synchronized.

*****
Types
*****
See Type help text for field descriptions and SeisIO behavior.

.. function:: NodalLoc

Nodal location. Currently only stores position along optical cable.
:raw-html:`<br /><br />`

.. function:: NodalData

Structure to hold nodal array data.
:raw-html:`<br /><br />`

.. function:: NodalChannel

A single channel of data from a nodal array.

************************
Reading Nodal Data Files
************************
.. function:: S = read_nodal(filename [, KWs])

| Read data from file *filename* into memory.
|
| **KWs**
| Keyword arguments: see below.
| Standard keywords: v

Supported File Formats
======================
.. csv-table::
  :header: File Format, String, Notes
  :delim: |
  :widths: 1, 1, 3

  Silixa TDMS | silixa    |

******************
Supported Keywords
******************

.. csv-table::
  :header: KW, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 2

  ch_s    | Int64     | 1                     | first channel index
  ch_e    | Int64     | (last channel)        | last channel index
  fmt     | String    | "silixa"              | nodal data format
  nn      | String    | ""                    | network name in `:id`
  s       | TimeSpec  | "0001-01-01T00:00:00" | start time
  t       | TimeSpec  | "9999-12-31T12:59:59" | end time
  v       | Integer   | 0                     | verbosity

Special Behavior
================
Real values supplied to keywords *s=* and *t=* are treated as seconds *relative to file begin time*. Most SeisIO functions that accept *TimeSpec* arguments treat Real values as seconds from *now()*.
