************
Introduction
************

SeisIO is a framework for working with univariate geophysical data on 64-bit systems.
SeisIO is designed around three basic principles:

* Ease of use: one shouldn't need a PhD to understand command syntax.
* Fluidity: working with data shouldn't feel *clumsy*.
* Performance: speed and efficient memory usage *matter*.

The project is home to an expanding set of web clients, file format readers,
and analysis utilities.


Overview
========
SeisIO stores data in minimalist containers that track the bare necessities for
analysis. New data are easily added with basic operators like *+*. Unwanted
channels can be removed just as easily. Data can be written to a number of
file formats.


Installation
============
From the Julia prompt: press ``]`` to enter the Pkg environment, then type
::

  add SeisIO; build; precompile


Dependencies should install automatically. To verify that everything works
correctly, type
::

  test SeisIO

and allow 10-20 minutes for tests to complete. Exit the Pkg environment by pressing Backspace or Control + C.


Getting Started
===============
At the Julia prompt, type
::

  using SeisIO

You'll need to repeat this step whenever you restart Julia, as with any
command-line interpreter (CLI) language.


Learning SeisIO
===============
An interactive tutorial using Jupyter notebooks in a web browser can be accessed
from the Julia prompt with these commands:
::

  p = pathof(SeisIO)
  d = dirname(realpath(p))
  cd(d)
  include("../tutorial/install.jl")

SeisIO also has an :ref:`online tutorial guide<tutorial>`, intended as a gentle
introduction for people less familiar with the Julia language. The two are
intentionally redundant; Jupyter isn't compatible with all systems and browsers.

For a faster start, skip to any of these topics:

* :ref:`Working with Data<wwd>`: learn how to manage data using SeisIO
* :ref:`Reading Data<readdata>`: learn how to read data from file
* :ref:`Web Requests<getdata>`: learn how to download data


Updating
========
From the Julia prompt: press ``]`` to enter the Pkg environment, then type
``update``. Once package updates finish, restart Julia to use them.
