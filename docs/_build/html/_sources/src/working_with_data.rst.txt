.. _wwd:

#################
Working with Data
#################
This section describes how to track and manage SeisIO data.

************************
Creating Data Containers
************************
Create a new, empty object using any of the following commands:

.. csv-table::
  :header: Object, Purpose
  :delim: |
  :widths: 1, 6

  SeisChannel() | A single channel of univariate (usually time-series) data
  SeisData()    | Multichannel univariate (usually time-series) data
  SeisHdr()     | Header structure for discrete seismic events
  SeisEvent()   | Discrete seismic events; includes SeisHdr and SeisData objects


*******************
Acquiring Data
*******************
* Read files with :ref:`read_data<readdata>`
* Make web requets with :ref:`get_data<getdata>`
* Initiate real-time streaming sessions to SeisData objects with :ref:`SeedLink!<seedlink-section>`

*******************
Keeping Track
*******************
A number of auxiliary functions exist to keep track of channels:

.. function:: findchan(id::String, S::SeisData)
.. function:: findchan(S::SeisData, id::String)

Get all channel indices i in S with id :math:`\in` S.id[i]. Can do partial id
matches, e.g. findchan(S, "UW.") returns indices to all channels whose IDs begin
with "UW.".

.. function:: findid(S::SeisData, id)

Return the index of the first channel in **S** where id = **id**. Requires an
exact string match; intended as a low-memory equivalent to findfirst for
ids.

.. function:: findid(S::SeisData, Ch::SeisChannel)

Equivalent to findfirst(S.id.==Ch.id).

.. function:: namestrip!(S[, convention])

Remove bad characters from the :name fields of **S**. Specify convention as a
string (default is "File"):

+------------+---------------------------------------+
| Convention | Characters Removed:sup:`(a)`          |
+============+=======================================+
| "File"     | ``"$*/:<>?@\^|~DEL``                  |
+------------+---------------------------------------+
| "HTML"     | ``"&';<>©DEL``                        |
+------------+---------------------------------------+
| "Julia"    | ``$\DEL``                             |
+------------+---------------------------------------+
| "Markdown" | ``!#()*+-.[\]_`{}``                   |
+------------+---------------------------------------+
| "SEED"     | ``.DEL``                              |
+------------+---------------------------------------+
| "Strict"   | ``!"#$%&'()*+,-./:;<=>?@[\]^`{|}~DEL``|
+------------+---------------------------------------+

:sup:`(a)` ``DEL`` here is \\x7f (ASCII/Unicode U+007f).


.. function:: timestamp()

Return current UTC time formatted yyyy-mm-ddTHH:MM:SS.uuu.

.. function:: track_off!(S)

Turn off tracking in S and return a boolean vector of which channels were added
or altered significantly.

.. function:: track_on!(S)

Begin tracking changes in S. Tracks changes to :id, channel additions, and
changes to data vector sizes in S.x.

Does not track data processing operations on any channel i unless
length(S.x[i]) changes for channel i (e.g. filtering is not tracked).

**Warning**: If you have or suspect gapped data in any channel, calling
ungap! while tracking is active will flag a channel as changed.


Source Logging
==============
The :src field records the *last* source used to populate each channel (usually
a file name and path or a web request URL).

When a data source is added to a channel, including the first time data are
added, this is recorded in :notes with the syntax (timestamp) +src: (function) (src).


*******************
Channel Maintenance
*******************
A few functions exist specifically to simplify data maintenance:

.. function:: prune!(S::SeisData)

Delete all channels from S that have no data (i.e. S.x is empty or non-existent).

.. function:: C = pull(S::SeisData, id::String)

Extract the first channel with id=id from S and return it as a new SeisChannel
structure. The corresponding channel in S is deleted.

.. function:: C = pull(S::SeisData, i::integer)
   :noindex:

Extract channel **i** from **S** as a new SeisChannel object **C**, and delete
the corresponding channel from **S**.


*******************
Taking Notes
*******************
Functions that add and process data note these operations in the :notes field
of each object affected. One can also add custom notes with the note! command:

.. function:: note!(S, i, str)

Append **str** with a timestamp to the :notes field of channel number **i** of **S**.

.. function:: note!(S, id, str)

As above for the first channel in **S** whose id is an exact match to **id**.

.. function:: note!(S, str)

if **str* mentions a channel name or ID, only the corresponding channel(s) in **S** is annotated; otherwise, all channels are annotated.

.. clear_notes!(S::SeisData, i::Int64, s::String)

Clear all notes from channel ``i`` of ``S``.

``clear_notes!(S, id)``

Clear all notes from the first channel in ``S`` whose id field exactly matches ``id``.

``clear_notes!(S)``

Clear all notes from every channel in ``S``.
