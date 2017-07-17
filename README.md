# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

# Documentation
http://seisio.readthedocs.org

# CHANGELOG
## Current (2017-07-16)
* `readmseed` rewritten; performance improvements should be very noticeable.
  + Many bugfixes.
  + SeisIO now uses a small (~500k) memory-resident structure for SEED packets.
  + SEED defaults can be changed with `seeddef`.
* `findid` no longer relies on the ever-redoubtable combination of `findfirst` and String arrays.
* Faster initialization of empty SeisData structs with `SeisData()`.

## 2017-07-04
* Updated for Julia v0.6.0. Compatibility with earlier versions is not guaranteed. Please report any deprecation warnings!

## 2017-04-19
* Moved pol_sort to the Polarization project.
* SeisIO data files now include searchable indices at the end of each file.
  + This change is backwards-compatible and won't affect the ability to read existing files.
  + A file index contains the following information, written in this order:
    - (length = ∑\_j∑\_i length(S.id[i])\_i) IDs for each trace in each object
    - (length = 3∑\_j S.n\_j) start and end times and byte indices of each trace in each object. (time unit = integer μs from Unix epoch)
    - Byte index to start of IDs.
    - Byte index to start of Ints.

## Known Issues (2017-07-16)
* Julia 0.6.0 slowed batch_read execution time by roughly a factor of 4; it currently offers only ~10-20% speedup over standard file read methods and is not useful in present form. This is slated for an eventual rewrite.
* Rarely, SeedLink! can cause a Julia session to hang by failing to initialize a connection.

# Current Functionality
SeisIO presently includes three web clients, readers for several data formats, and writers for SAC and a native SeisIO format. Utility functions allow synchronization, seamless data merging, and padding time gaps.

## Web clients
* SeedLink
* FDSN (data, event, and station queries)
* IRIS timeseries

## Readable File Formats
* SAC
* miniSEED
* SEG Y
  + rev 0
  + rev 1
  + PASSCAL/NMT single-channel files
* Win32
* UW

# Acknowledgements
miniSEED routines are based on rdmseed.m for Matlab by Francois Beauducel, Institut de Physique du Globe de Paris (France). Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services, and Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format.

# References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
