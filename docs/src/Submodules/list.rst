##################
List of Submodules
##################

.. csv-table::
  :header: Name, Purpose
  :delim: |
  :widths: 1, 5

  ASCII       | ASCII file formats (includes GeoCSV, SLIST, and variants)
  FastIO      | Replacement low-level I/O functions to avoid thread locking
  Quake       | Earthquake seismology
  RandSeis    | Generate SeisIO structures with quasi-random entries
  SEED        | Standard for the Exchange of Earthquake Data (SEED) file format
  SUDS        | Seismic Unified Data System (SUDS) file format
  SeisHDF     | Dedicated support for seismic HDF5 subformats
  UW          | University of Washington data format


****************
Using Submodules
****************

At the Julia prompt, type *using SeisIO.NNNN* where NNNN is the submodule name; for example, ``using SeisIO.Quake`` loads the Quake submodule.
