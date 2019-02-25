#################
Working with Data
#################
SeisIO is designed around the principle of easy, fluid, and fast data access.
At the most basic level, SeisIO uses an array-like custom structure called a
**SeisChannel** for single-channel data; **SeisData** structures store
multichannel data and can be created by combining **SeisChannel** objects.

***********
First Steps
***********
Create a new, empty **SeisChannel** object with

.. function:: Ch = SeisChannel()
    :noindex:

The meanings of the field names are explained `here<dkw>`. You can edit
field values manually, e.g.,
::

  Ch.loc = [-90.0, 0.0, 9300.0, 0.0, 0.0]
  Ch.name = "South pole"

or you can set them with keywords at creation:
::

  Ch = SeisChannel(name="MANOWAR JAJAJA")


SeisData structures are collections of channel data. They can be created with
the SeisData() command, which can optionally create any number of empty channels
at a time, e.g.,

.. function:: S = SeisData(1)
    :noindex:

They can be explored similarly:
::

  S.name[1] = "South pole"
  S.loc[1] = [-90.0, 0.0, 9300.0, 0.0, 0.0]

A collection of channels becomes a SeisData structure:

.. function:: S = SeisData(SeisChannel(), SeisChannel())
    :noindex:

You can push channels onto existing SeisData structures, like adding one key
to a dictionary:

.. function:: push!(S, Ch)
    :noindex:

Note that this copies Ch to a new channel in S -- S[3] is not a view into C.
This is deliberate, as otherwise the workspace quickly becomes a mess of
redundant channels. Clean up with ``Ch = []`` to free memory before moving on.

*********************************
Operations on SeisData structures
*********************************

We're now ready for a short tutorial of what we can do with data structures.
In the commands below, as in most of this documentation, **Ch** is a
SeisChannel object and **S** is a SeisData object.


Adding channels to a SeisData structure
=======================================
You've already seen one way to add a channel to SeisData: push!(S, SeisChannel())
adds an empty channel. Here are others:

.. function:: append!(S, SeisData(n))

Adds n channels to the end of S by creating a new n-channel SeisData and
appending it, similar to adding two dictionaries together.

These methods are aliased to the addition operator:

::

  S += SeisChannel()      # equivalent to push!(S, SeisChannel())
  S += randseisdata(3)    # adds a random 3-element SeisData structure to S in place
  S = SeisData(randseisdata(5), SeisChannel(),
        SeisChannel(id="UW.SEP..EHZ", name="Darth Exploded",
        loc=[46.1967, -122.1875, 1440, 0.0, 0.0]))

Most web request functions can append to an existing SeisData object by placing
an exclamation mark after the function call. You can see how this works by
running the `examples<webex>`.

Search, Sort, and Prune
=======================
The easiest way to find channels of interest in a data structure is to
use findid, but you can obtain an array of partial matches with findchan:

::

  S = SeisData(randseisdata(5), SeisChannel(),
        SeisChannel(id="UW.SEP..EHZ", name="Darth Exploded",
        loc=[46.1967, -122.1875, 1440, 0.0, 0.0], x=rand(1024)))
  findid(S, "UW.SEP..EHZ")    # 7
  findchan(S, "EHZ")          # [7], maybe others depending on randseisdata


You can sort by channel ID with the `sort` command.

Several functions exist to prune empty and unwanted channels from SeisData
structures.

::

  delete!(S, 1:2)  # Delete first two channels of S
  S -= 3           # Delete third channel of S

  # Extract S[1] as a SeisChannel, removing it from S
  C = pull(S, 1)

  # Delete all channels whose S.x is empty
  prune!(S)

  # Delete channels containing ".SEP."
  delete!(S, ".SEP.", exact=false)

In the last example, specifying exact=false means that any channel whose ID
partly matches the string ".SEP." gets deleted; by default, passing
a string to delete!(S, str) only matches channels where str is the exact ID.
This is an efficient way to remove unresponsive subnets and unwanted channel
types, but beware of clumsy over-matching.

Merge
=====
SeisData structures can be merged using the function **merge!**, but this is
much more complicated than addition.

.. function:: merge!(S)
    :noindex:

* Does nothing to channels with unique IDs.
* For sets of channels in S that share an ID...
  + Adjusts all matching channels to the :gain, :fs, :loc, and :resp fields of the channel the latest data
  + Time-sorts data from all matching channels by `S.t`
  + Averages data points that occur simultaneously in multiple members of the set
* throws an error if joining data that have the same ID and different units.


*************
Keeping Track
*************
Because tracking arbitrary operations can be difficult, several functions have
been written to keep track of data and operations in a semi-automated way.

Taking Notes
============
Most functions that add or process data note this in the appropriate channel's :notes field.
However, you can also make your own notes with the note! command:

.. function:: note!(S, i, str)
    :noindex:

Append **str** with a timestamp to the :notes field of channel number **i** of **S**.

.. function:: note!(S, id, str)
    :noindex:

As above for the first channel in **S** whose id is an exact match to **id**.

.. function:: note!(S, str)
    :noindex:

if **str* mentions a channel name or ID, only the corresponding channel(s) in **S** is annotated; otherwise, all channels are annotated.

.. clear_notes!(S::SeisData, i::Int64, s::String)

Clear all notes from channel ``i`` of ``S``.

``clear_notes!(S, id)``

Clear all notes from the first channel in ``S`` whose id field exactly matches ``id``.

``clear_notes!(S)``

Clear all notes from every channel in ``S``.

Keeping Track
=============
A number of auxiliary functions exist to keep track of channels:

.. function:: findchan(id::String, S::SeisData)
.. function:: findchan(S::SeisData, id::String)

Get all channel indices i in S with id :math:`\in` S.id[i]. Can do partial id matches, e.g. findchan(S, "UW.") returns indices to all channels whose IDs begin with "UW.".

.. function:: findid(S::SeisData, id)

Return the index of the first channel in **S** where id = **id**.

.. function:: findid(S::SeisData, Ch::SeisChannel)

Equivalent to findfirst(S.id.==Ch.id).

.. function:: namestrip!(S[, convention])

Remove bad characters from the :name fields of **S**. Specify convention as a string (default is "File"):

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

:sup:`(a)` ``DEL`` is \\x7f (ASCII/Unicode U+007f).


.. function:: timestamp()

Return current UTC time formatted yyyy-mm-ddTHH:MM:SS.μμμ.

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
SeisIO functions record the *last* source used to populate each channel in the
:src field. Typically this is a string.

When a data source is added to a channel, including the first time data are
added, this is recorded in :notes with the syntax (timestamp) +src: (function) (src).
