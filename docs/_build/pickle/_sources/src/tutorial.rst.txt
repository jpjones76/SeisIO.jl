.. _tutorial:

###########
First Steps
###########
SeisIO is designed around easy, fluid, and fast data access.
At the most basic level, SeisIO uses an array-like custom object called a
**SeisChannel** for single-channel data; **SeisData** objects store
multichannel data and can be created by combining SeisChannels.

**********
Start Here
**********
Create a new, empty **SeisChannel** object with

.. function:: Ch = SeisChannel()
    :noindex:

The meanings of the field names are explained :ref:`here<dkw>`; you can also type
``?SeisChannel`` at the Julia prompt. You can edit field values manually, e.g.,
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
running the :ref:`examples<webex>`.

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

*************
Next Steps
*************
Because tracking arbitrary operations can be difficult, several functions have
been written to keep track of data and operations in a semi-automated way. See
the next section, :ref:`working with data<wwd>`, for detailed discussion of
managing data from the Julia command prompt.
