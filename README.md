# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

# Documentation
http://seisio.readthedocs.org

# CHANGELOG
## 2017-01-31
The introduction of today's changes marks the first stable SeisIO release. Please test and report all issues.
* Documentation was completely rewritten.
* All web functions now use the channel naming convention NET.STA.LOC.CHA.
* Renamed several web function keywords for uniformity.
* All web functions that require channel input now accept a config. filename, a String, or a String array.
* Keyword initialization in new SeisData objects has been permanently disabled.
* The native SeisIO file format has changed.
* `prune!(S)` is now `merge!(S)`
* A few unused functions and accidental exports were removed.

## 2017-01-24
* Type stability for nearly all methods
* Complete rewrite of mini-SEED resulting in 2 orders of magnitude speedup
* Faster read times for SAC, SEG Y, and UW data formats
* Improved XML parsing
* batch_read works again
* Event functions are no longer in a submodule
* SeisIO now includes Blosc among its dependencies.

## Known Issues (2017-01-31)
* Type stability is impossible when initializing types with keyword arguments; keyword arguments can't be type-stable in the Julia language. This is unlikely to change unless the language itself changes. For strict type stability, initialize an empty structure, then set field values manually (e.g. `C=SeisChannel(); setfield!(C, :fs, 100)`).
* readmseed uses an exorbitant amount of memory. The 2017-01-24 update reduced its memory consumption by two orders of magnitude, but the requirement to read a file is still ~30x the file size (e.g. 42 MB for a 1.3 MB file). Suggestions for improvement here would be especially welcome.

# Current Functionality
SeisIO presently includes three web clients, readers for several data formats, and writers for SAC and a native SeisIO format. Utility functions allow synchronization, seamless data merging, and padding time gaps.

## Web clients
* SeedLink
* FDSN (data, event, and station queries)
* IRIS timeseries

## Readable File Formats
* SAC
* miniSEED
* SEG Y (industry standard and PASSCAL/NMT)
* Win32
* UW

# Acknowledgements
miniSEED routines were originally based on rdmseed.m for Matlab by Francois Beauducel, Institut de Physique du Globe de Paris (France). Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services, and Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format.

# References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
