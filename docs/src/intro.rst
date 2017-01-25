************
:mod:`Intro`
************
SeisIO is a framework for working with geophysical time series data. The project is home to an expanding set of web clients, file read formats, and analysis utilities.


How SeisIO Works
================
Data are loaded into minimalist containers called :ref:`SeisChannel and SeisData <seisdata>`, which track record times and other necessary quantities for further processing. SeisChannel is for single-channel data, SeisData for multi-channel data.

New data, including data for existing channels from new sources, can be merged into SeisData objects (or placed in new SeisData objects) using built-in Julia commands like "+"". Unwanted data channels can be removed by matching on a channel's ID, name, or index within a SeisData structure, using built-in commands like "-".

Data can be saved to native SeisIO format or written to SAC.

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

Be aware that ``workspace()`` clears the Julia session's memory, equivalent to ``clear all`` in Matlab/Octave. Save all work before updating.

Dependencies
============
DSP, Requests, LightXML
