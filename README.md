# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

# Documentation
http://seisio.readthedocs.org

# Current Status (2017-01-24)
A major update to SeisIO is now live. Improvements include:
* Type stability for nearly all methods and custom types.
* Complete rewrite of mini-SEED resulting in 2 orders of magnitude speedup
* Faster read times for SAC, SEG Y, and UW data formats
* Better XML parsing
* batch_read works again
* Event functionality is no longer a submodule

## Known Issues (2017-01-24)
* Type-stability is impossible when initializing types with keyword arguments; keyword arguments can't be type-stable in the Julia language. This is unlikely to change. For strict type-stability, you can initialize an empty structure (e.g. `C=SeisChannel()`), then set field values manually (e.g. `setfield!(C, :fs, 100)`).
* Documentation is behind and will be updated in the coming days. Event functionality is almost completely undocumented.
* Some functions were renamed for consistency, particularly with respect to web services (e.g. "getevt" is now "FDSNevt"). These are not yet documented.
* readmseed uses exorbitant amounts of memory; I managed to reduce this to order of magnitude less than previous versions, but still e.g. 42 MB for a 1.3 MB file (previously ~450 MB). Suggestions for more efficient memory allocation are welcome. Other file formats don't have this problem.

# Current Functionality
SeisIO presently includes three web clients, readers for several data formats, and writers for SAC and a native SeisIO format. Utility functions allow synchronization, seamless data merging, and padding time gaps.

## Web clients
* SeedLink
* FDSN (continuous data and event queries)
* IRIS timeseries

## Readable File Formats
* SAC <sup>(a)</sup>
* mini-SEED
* SEG Y (PASSCAL/NMT) <sup>(a)</sup>
* SEG Y (Standard)
* Win32
* UW

<sup>(a)</sup> Supported by ``batch_read``.

# Acknowledgements
mini-SEED routines are based on rdmseed.m for Matlab, written by by Francois Beauducel, Institut de Physique du Globe de Paris (France). Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services, and Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format.

# References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
