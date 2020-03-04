.. _help:

############
Getting Help
############
Numerous sources of help are available, including web-hosted documentation, command-line help, tutorials, worked examples, and tests.

********
Tutorial
********

To invoke tutorial notebooks in your web browser, execute these commands at a Julia prompt:

::

  p = pathof(SeisIO)
  d = dirname(realpath(p))
  cd(d)
  include("../tutorial/install.jl")

********
Examples
********

Two sets of worked examples for web requests exist: a set of command-prompt examples with a step-by-step command walkthrough, and those in the :ref:`Examples appendix<webex>`.

Invoke the command-prompt examples with the following command sequence:

::

  p = pathof(SeisIO)
  d = dirname(realpath(p))
  cd(d)
  include("../test/examples.jl")

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

*****************
Command-Line Help
*****************

A great deal of additional help functions are available at the Julia command prompt. All exported SeisIO functions have docstrings.

Dedicated Help Functions
========================
These functions take no arguments and dump information to stdout.

Typing SeisIO.ChanSpec at the Julia prompt gives the union of Types that can be inputs to a channel selector keyword.

Typing SeisIO.TimeSpec at the Julia prompt gives the union of Types that can be passed to start (*s=*) and end (*t=*) arguments/keywords.

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

.. function:: ?chanspec

Answers: how do I specify channels in a web request? Outputs :ref:`channel id syntax <cid>` to stdout.

.. function:: ?seis_www

Answers: which servers are available for FDSN queries? Outputs :ref:`the FDSN server list<servers>` to stdout.

.. function:: ?timespec


All About Keywords
==================
Invoke keywords help with **?SeisIO.KW** for complete information on SeisIO shared keywords and meanings.


Structure Docstrings
====================
The docstrings of every custom structure (Type) defined in SeisIO and its submodules provide detailed descriptions of what each field holds. For example:

::

  using SeisIO
  ?SeisData
