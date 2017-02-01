############
Introduction
############

SeisIO is a framework for working with geophysical time series data. The project is home to an expanding set of web clients, file format readers, and analysis utilities.


Overview
========
SeisIO stores data in minimalist data types that track record times and other necessary quantities for further processing. New data are easily merged into existing structures with basic commands like ``+``. Unwanted channels can be removed just as easily. Data can be saved to a native SeisIO format or written to SAC.


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
Blosc, DSP, LightXML, Requests; these should be installed automatically when SeisIO is added with Pkg.clone.
