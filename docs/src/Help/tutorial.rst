.. _tutorial:

###########
First Steps
###########
SeisIO is designed around easy, fluid, and fast data access.
At the most basic level, SeisIO uses an array-like structure called a
**SeisChannel** for single-channel data, and a multichannel structure
named **SeisData**.

**********
Start Here
**********
Create a new, empty **SeisChannel** object with

::

  Ch = SeisChannel()

The meanings of the field names are explained :ref:`here<dkw>`; you can also type
``?SeisChannel`` at the Julia prompt. You can edit field values manually, e.g.,
returning to the code block above,

::

  Ch = SeisChannel()
  Ch.loc = GeoLoc(lat=-90.0, lon=0.0, el=2835.0, az=0.0, inc=0.0)
  Ch.name = "South pole"

or you can set them with keywords at creation:
::

  Ch = SeisChannel(name="Templo de San José de La Floresta, Ajijic", fs=40.0)


Note that Strings in field names support full Unicode, so even graffiti
can be saved and read back in. This is useful for data containing non-English
characters.

SeisData structures are collections of channel data. They can be created with
the SeisData() command, which can optionally create any number of empty
channels at a time, e.g.,

::

  S = SeisData()      # empty structure, no channels
  S1 = SeisData(12)   # empty 12-channel structure

They can be explored similarly:
::

  S = SeisData(1)
  S.name[1] = "South pole"
  S.loc[1] = GeoLoc(lat=-90.0, lon=0.0, el=2835.0, az=0.0, inc=0.0)

A collection of channels becomes a SeisData structure; for example,

::

  L = GeoLoc(lat=46.1967, lon=-122.1875, el=1440.0, az=0.0, inc=0.0)
  S = SeisData(SeisChannel(), SeisChannel())
  S = SeisData(randSeisData(5), SeisChannel(),
        SeisChannel(id="UW.SEP..EHZ", name="Darth Exploded", loc=L))

You can push channels onto existing SeisData structures, like adding one key
to a dictionary. For example,

::

  push!(S, Ch)

copies Ch to a new channel in S. Note that the new S[3] is not a view into Ch.
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

::

  S = randSeisData(4)
  n = 3
  append!(S, SeisData(n))

This initializes an empty n-channel SeisData structure and appends it to the
end of S, similar to appending one array to another. S will have 7 channels,
but the last three are empty.

The addition operator, `+`, calls *push!* and *add!*, with one key difference:
to ensure reflexivity (i.e., `S1 + S2 == S2 + S1`), the `+` operator sorts the
output (command *sort!*) and prunes empty channels (command *prune!*). Thus,

::

  S = SeisData(2)
  S1 = randSeisData(3)
  S += S1

outputs only the three channels of random data initialized in the second line of
the code block; in addition, they're sorted by ID, so it's likely that S != S1.

Search, Sort, and Prune
=======================
The easiest way to find channels of interest in a data structure is to use
*findid* or *findchan*. ``findid(id, S)`` returns the numeric index *i* of the first channel in *S* where ``S.id[i] == id``. ``findchan(cha, S)`` returns an array of numeric indices in *S* to all channels whose IDs satisfy ``occursin(cha, S.id[i])``.

For example:

::

  L = GeoLoc(lat=46.1967, lon=-122.1875, el=1440.0, az=0.0, inc=0.0)
  S = SeisData(randSeisData(5), SeisChannel(id="YY.STA1..EHZ"),
        SeisChannel(id="UW.SEP..EHZ", name="Darth Exploded", loc=L))
  findid("UW.SEP..EHZ", S)    # 7
  findchan("EHZ", S)          # [6, 7], maybe others (depending on randSeisData)


You can sort channels in a structure by channel ID with the `sort!` command.

Several functions exist to prune empty and unwanted channels from SeisData
structures. Revisiting the previous code block, for example, try these:

::

  deleteat!(S, 1:2)   # Delete first two channels of S
  S -= 3              # Delete third channel of S

  # Extract S[1] as a SeisChannel, removing it from S
  C = pull(S, 1)

  # Delete channels containing ".SEP."
  delete!(S, ".SEP.", exact=false)

  # Delete all channels whose S.x is empty
  prune!(S)
  S

S should have one channel left.

In the *delete!* command, specifying `exact=false` means that any channel whose
ID partly matches the string ".SEP." gets deleted; by default,
``delete!(S, str)`` only matches channels where *str* is the exact ID. This is
an efficient way to remove unresponsive subnets and unwanted channel types, but
beware of accidental over-matching.

**********
Next Steps
**********
Because tracking arbitrary operations can be difficult, several functions have
been written to keep track of data and operations in a semi-automated way. See
the next section, :ref:`working with data<wwd>`, for detailed discussion of
managing data from the Julia command prompt.
