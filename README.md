# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

[![Build Status](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=master)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934/branch/master?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl/branch/master)

### Installation
From the command line, press `]` to enter the Package environment, then type or copy `add https://github.com/jpjones76/SeisIO.jl; build; precompile; test SeisIO`.

### Documentation
http://seisio.readthedocs.org

#### [Changelog](CHANGELOG.md)
#### [Known and Historic Issues](ISSUES.md)

## Functionality
Designed for speed, efficiency, and ease of use. Includes web clients, readers for many seismic data formats, and writers for SAC and native (SeisIO) format. Utility functions allow time synchronization, data merging, padding time gaps, and basic processing.

| **Web clients** | **Readable File Formats** |
|:----------------|:--------------------------|
| SeedLink | mini-SEED |
| FDSN (data, event, station)| SAC |
|  IRIS (timeeseries) | SEG Y (rev 0, rev 1, PASSCAL/NMT) |
|| Win_32 |
|| UW |

## Acknowledgements
* miniSEED routines are based on rdmseed.m for Matlab by Francois Beauducel, Institut de Physique du Globe de Paris (France).
* Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services; Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format; and Roberto Carniel (Universita di Udine, Italy) for assistance with early testing.

## References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
