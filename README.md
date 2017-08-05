# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

# Documentation
http://seisio.readthedocs.org

# CHANGELOG
## 2017-08-04
* Fixed a mini-SEED bug where IDs were incorrectly set when streaming data.
* Internal function `tzcorr()` is now part of PlotSeis.
* Added functions:
  + `env, env!`: Convert time-series data to envelopes
  + `del_sta!`: Delete all channels matching a station string (2nd part of ID)

## 2017-07-24
* Several minor bug fixes and performance improvements
* Added functions:
  + `lcfs`: Lowest common fs
  + `t_win`, `w_time`: Convert between SeisIO time representations and time windows
  + `demean!`, `unscale!`: Basic processing operations

## 2017-07-16
* `readmseed` rewritten; performance improvements should be very noticeable.
  + Many bugfixes.
  + SeisIO now uses a small (~500k) memory-resident structure for SEED packets.
  + SEED defaults can be changed with `seeddef`.
* `findid` no longer relies on the ever-redoubtable combination of `findfirst` and String arrays.
* Faster initialization of empty SeisData structs with `SeisData()`.

## 2017-07-04
* Updated for Julia v0.6.0. Compatibility with earlier versions is not guaranteed. Please report any deprecation warnings!

## Known Issues (2017-07-24)
* batch_read is no longer useful. Julia 0.6.0 slowed batch_read execution time by roughly a factor of 4; it currently offers only ~10-20% speedup over standard file read methods.
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
