************
:mod:`Intro`
************
SeisIO is a framework for working with geophysical time series data. The project is home to an expanding set of web clients, file format readers, and analysis utilities.


How SeisIO Works
================
Data are loaded into minimalist containers called :ref:`SeisChannel and SeisData <seisdata>`, which track record times and other necessary quantities for further processing. SeisChannel objects are for single-channel data, SeisData for multichannel data. Event headers can be stored in ``SeisHdr`` containers.

New data, including data for existing channels from new sources, can be merged into SeisData objects (or placed in new SeisData objects) using commands like ``+``. Unwanted data channels can be removed by matching on a channel's ID using built-in commands like "-".

Data can be saved to a native SeisIO format or written to SAC.

Installation
============
From the Julia prompt:
::

  Pkg.clone("https://github.com/jpjones76/SeisIO.jl")
  using SeisIO

Updating
========
The usual update syntax for the Julia language is

::

  Pkg.update()
  workspace()
  using SeisIO

Please be aware that ``workspace()`` clears the Julia session's memory. Save work before updating.

Dependencies
============
DSP, Requests, LightXML, Blosc
