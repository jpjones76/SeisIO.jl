# SeisIO.jl
[![Build Status](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=master)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934/branch/master?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl/branch/master) [![codecov](https://codecov.io/gh/jpjones76/SeisIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jpjones76/SeisIO.jl)[![Coverage Status](https://coveralls.io/repos/github/jpjones76/SeisIO.jl/badge.svg?branch=master)](https://coveralls.io/github/jpjones76/SeisIO.jl?branch=master) [![Documentation Status](https://readthedocs.org/projects/seisio/badge/?version=latest)](https://seisio.readthedocs.io/en/latest/?badge=latest)

A minimalist, platform-agnostic package for univariate geophysical data.

## Installation | [Documentation](http://seisio.readthedocs.org)
From the Julia prompt, type: `] add SeisIO`; (Backspace); `using SeisIO`

## Summary | [Collaboration](docs/CONTRIBUTE.md)
Designed for speed, efficiency, and ease of use. Includes web clients, readers for common seismic data formats, and fast file writers. Utility functions allow time synchronization, data merging, padding time gaps, and other basic data processing.

* Web clients: SeedLink, FDSN, IRIS
* File formats: GeoCSV, Lennartz ASCII, mini-SEED, QuakeML, SAC, SEG Y (rev 0, rev 1, PASSCAL/NMT), Win32, UW

## Publications | [Changelog](docs/CHANGELOG.md) | [Issues](docs/ISSUES.md)
Jones, J.P.,  Okubo, K., Clements. T., \& Denolle, M. (2019). SeisIO: a fast, efficient geophysical data architecture for the Julia language, *Submitted to Seimol. Res. Lett.*
