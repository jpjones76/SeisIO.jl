# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

[![Build Status](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=master)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934/branch/master?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl/branch/master) [![codecov](https://codecov.io/gh/jpjones76/SeisIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jpjones76/SeisIO.jl)[![Coverage Status](https://coveralls.io/repos/github/jpjones76/SeisIO.jl/badge.svg?branch=master)](https://coveralls.io/github/jpjones76/SeisIO.jl?branch=master)

## [Documentation](http://seisio.readthedocs.org) [![Documentation Status](https://readthedocs.org/projects/seisio/badge/?version=latest)](https://seisio.readthedocs.io/en/latest/?badge=latest)

## Installation
From the Julia command prompt:
1. Press `]` to enter `pkg`.
2. Type or copy: `add SeisIO`
3. Press backspace to exit `pkg`.
4. Type or copy: `using SeisIO`

If installation fails, and the problem isn't documented, please [open a new issue](https://github.com/jpjones76/SeisIO.jl/issues/). If possible, please include a text dump with the error message.

#### [Contribute](docs/CONTRIBUTE.md)

#### [Changelog](docs/CHANGELOG.md)

#### [Known and Historic Issues](docs/ISSUES.md)

## Functionality
Designed for speed, efficiency, and ease of use. Includes web clients, readers for many seismic data formats, and writers for SAC and native (SeisIO) format. Utility functions allow time synchronization, data merging, padding time gaps, and basic data processing.

* Web clients: SeedLink, FDSN (dataselect, event, station), IRIS (distaz, timeseries, traveltimes)
* File formats: miniSEED, SAC, SEG Y (rev 0, rev 1, PASSCAL/NMT), Win_32, UW

## Acknowledgements
* miniSEED routines are based on rdmseed.m for Matlab by Francois Beauducel, Institut de Physique du Globe de Paris (France).
* Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services; Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format; and Roberto Carniel (Universita di Udine, Italy) for assistance with early testing.

## References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC, https://github.com/iris-edu/libmseed
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
