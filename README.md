# SeisIO.jl
[![Build Status](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=master)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934/branch/master?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl/branch/master) [![codecov](https://codecov.io/gh/jpjones76/SeisIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jpjones76/SeisIO.jl)[![Coverage Status](https://coveralls.io/repos/github/jpjones76/SeisIO.jl/badge.svg?branch=master)](https://coveralls.io/github/jpjones76/SeisIO.jl?branch=master) [![Documentation Status](https://readthedocs.org/projects/seisio/badge/?version=latest)](https://seisio.readthedocs.io/en/latest/?badge=latest)

A minimalist, platform-agnostic package for univariate geophysical data.

## Installation | [Documentation](http://seisio.readthedocs.org)
From the Julia prompt, type: `] add SeisIO`; (Backspace); `using SeisIO`

## Summary | [Collaboration](docs/CONTRIBUTE.md)
Designed for speed, efficiency, and ease of use. Includes web clients, readers for common seismic data formats, and fast file writers. Utility functions allow time synchronization, data merging, padding time gaps, and basic data processing.

* Web clients: SeedLink, FDSN, IRIS
* File formats: GeoCSV, Lennartz ASCII, mini-SEED, QuakeML, SAC, SEG Y (rev 0, rev 1, PASSCAL/NMT), Win32, UW

## Acknowledgements |  [Changelog](docs/CHANGELOG.md) | [Issues](docs/ISSUES.md)
* miniSEED routines were originally based on rdmseed.m for Matlab by Francois Beauducel, Institut de Physique du Globe de Paris (France)
* SAC routines were originally based on SacIO.jl by Ben Postlethwaite
* Many thanks to Robert Casey (IRIS, USA) and Chad Trabant (IRIS, USA) for discussions of IRIS web services; Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format; and Roberto Carniel (Universita di Udine, Italy) for assistance with early testing

## References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC, https://github.com/iris-edu/libmseed
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
