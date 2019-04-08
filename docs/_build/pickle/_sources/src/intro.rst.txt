************
Introduction
************

SeisIO is a framework for working with geophysical time series data. The project is home to an expanding set of web clients, file format readers, and analysis utilities.


Overview
========
SeisIO stores data in minimalist data types that track record times and other necessary quantities for further processing. New data are easily merged into existing structures with basic commands like ``+``. Unwanted channels can be removed just as easily. Data can be saved to a native SeisIO format or written to SAC.


Installation
============
From the Julia prompt: press ``]`` to enter the Pkg environment, then type
::

  add https://github.com/jpjones76/SeisIO.jl; build; precompile


Dependencies should be installed automatically. To run tests that verify functionality works correctly, type
::

  test SeisIO

in the Pkg environment. Allow 10-20 minutes for all tests to complete.

To get started, exit the Pkg environment by pressing Control + C, then type
::

  using SeisIO


Updating
========
From the Julia prompt: press ``]`` to enter the Pkg environment, then type ``update``. You may need to restart the Julia REPL afterward to use the updated version.
