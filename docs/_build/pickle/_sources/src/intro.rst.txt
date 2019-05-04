************
Introduction
************

SeisIO is a framework for working with univariate geophysical data.
SeisIO is designed around three basic principles:

* Ease of use: you shouldn't *need* a PhD to study geophysical data.
* Fluidity: working with data shouldn't feel *clumsy*.
* Performance: speed and efficient memory usage *matter*.

The project is home to an expanding set of web clients, file format readers,
and analysis utilities.


Overview
========
SeisIO stores data in minimalist containers that track the bare necessities for
analysis. New data are easily added with basic commands like ``+``. Unwanted
channels can be removed just as easily. Data can be saved to a native SeisIO
format or written to other supported file formats.


Installation
============
From the Julia prompt: press ``]`` to enter the Pkg environment, then type
::

  add SeisIO; build; precompile


Dependencies should install automatically. To verify that everything works
correctly, type
::

  test SeisIO

and allow 10-20 minutes for tests to complete. To get started, exit the Pkg
environment by pressing Backspace or Control + C, then type
::

  using SeisIO

at the Julia prompt. You'll need to repeat that last step whenever you restart
Julia, as with any command-line interpreter (CLI) language.


Getting Started
===============
The :ref:`tutorial<tutorial>` is designed as a gentle introduction for people
less familiar with the Julia language. If you already have some familiarity
with Julia, you probably want to start with one of the following topics:

* :ref:`Working with Data<wwd>`: learn how to manage data using SeisIO
* :ref:`Reading Data<readdata>`: learn how to read data from file
* :ref:`Requesting Data<getdata>`: learn how to make web requests


Updating
========
From the Julia prompt: press ``]`` to enter the Pkg environment, then type
``update``. Once updates finish, restart Julia to use them.


Getting Help
============
In addition to these documents, a number of help documents can be called at the
Julia prompt. These commands are a useful starting point:

::

  ?chanspec           # how to specify channels in web requests
  ?get_data           # how to download data
  ?read_data          # how to read data from file
  ?timespec           # how to specify times in web requests and data processing
  ?seed_support       # how much of the SEED data standard is supported?
  ?seis_www           # list strings for data sources in web requests
  ?SeisData           # information about SeisIO data types
  ?SeisIO.KW          # SeisIO shared keywords and their meanings
