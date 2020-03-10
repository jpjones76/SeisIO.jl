.. _help:

############
Getting Help
############
In addition to the Juypter notebooks and :ref:`online tutorial guide<tutorial>`,
other sources of help are available:

* :ref:`Examples<examples>`
* :ref:`Automated Tests<tests>`
* :ref:`Command-Line Help<cli_help>`

.. _examples:

********
Examples
********

Several worked examples exist throughout these documents, in addition to *examples.jl* and the interactive tutorial.

Invoke the command-prompt examples with the following command sequence:

::

  p = pathof(SeisIO)
  d = dirname(realpath(p))
  cd(d)
  include("../test/examples.jl")

.. _tests:

*****
Tests
*****

The commands in *tests/* can be used as templates; to install test data and run all tests, execute these commands:

::

  using Pkg
  Pkg.test("SeisIO")      # lunch break recommended. Tests can take 20 minutes.
                          # 99.5% code coverage wasn't an accident...
  p = pathof(SeisIO)
  cd(realpath(dirname(p) * "/../test/"))

.. _cli_help:

*****************
Command-Line Help
*****************

A great deal of additional help functions are available at the Julia command prompt. All SeisIO functions and structures have their own docstrings. For example, typing *?SeisData* at the Julia prompt produces the following:

::

  SeisData

  A custom structure designed to contain the minimum necessary information
  for processing univariate geophysical data.

  SeisChannel

  A single channel designed to contain the minimum necessary information
  for processing univariate geophysical data.

  Fields
  ========

  Field  Description
  –––––– ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  :n     Number of channels [^1]
  :c     TCP connections feeding data to this object [^1]
  :id    Channel id. Uses NET.STA.LOC.CHAN format when possible
  :name  Freeform channel name
  :loc   Location (position) vector; any subtype of InstrumentPosition
  :fs    Sampling frequency in Hz; fs=0.0 for irregularly-sampled data.
  :gain  Scalar gain
  :resp  Instrument response; any subtype of InstrumentResponse
  :units String describing data units. UCUM standards are assumed.
  :src   Freeform string describing data source.
  :misc  Dictionary for non-critical information.
  :notes Timestamped notes; includes automatically-logged info.
  :t     Matrix of time gaps in integer μs, formatted [Sample# Length]
  :x     Time-series data


Dedicated Help Functions
========================
These functions take no arguments and dump information to stdout.

Submodule SEED
**************
.. function:: dataless_support()

Output lists of supported blockettes in dataless SEED to stdout.

.. function:: mseed_support()

Output lists of supported blockettes in mini-SEED to stdout.


.. function:: resp_wont_read()

Output "hall of shame" of known examples of broken RESP to stdout.

.. function:: seed_support()

Output full information on SEED support to stdout.

Submodule SUDS
**************
.. function:: suds_support()

Dump info to STDOUT on SUDS support for each numbered SUDS structure.

* **Green** structures are fully supported and read into memory.
* **Yellow** structures can be dumped to stdout with *read_data("suds", ..., v=2)*.
* **Red** structures are skipped and don't exist in our test data.


Formats Guide
=============
**formats** is a constant static dictionary with descriptive entries of each data format. Access the list of formats with `sort(keys(formats))`. Then try a command like `formats["slist"]` for detailed info. on the slist format.


Help-Only Functions
===================
These functions contain help docstrings but execute nothing. They exist to answer common questions.

.. function:: ?web_chanspec

Answers: how do I specify channels in a web request? Outputs :ref:`channel id syntax <cid>` to stdout.

.. function:: ?seis_www

Answers: which servers are available for FDSN queries? Outputs :ref:`the FDSN server list<servers>` to stdout.

.. function:: ?TimeSpec


All About Keywords
==================
Invoke keywords help with **?SeisIO.KW** for complete information on SeisIO shared keywords and meanings.
