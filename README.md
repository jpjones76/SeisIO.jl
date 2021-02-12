# SeisIO.jl
[![Build Status](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=main)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934/branch/master?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl/branch/master) [![codecov](https://codecov.io/gh/jpjones76/SeisIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jpjones76/SeisIO.jl)[![Coverage Status](https://coveralls.io/repos/github/jpjones76/SeisIO.jl/badge.svg?branch=master)](https://coveralls.io/github/jpjones76/SeisIO.jl?branch=master) [![Documentation Status](https://readthedocs.org/projects/seisio/badge/?version=latest)](https://seisio.readthedocs.io/en/latest/?badge=latest)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

A minimalist, platform-agnostic package for univariate geophysical data.

## Installation | [Documentation](http://seisio.readthedocs.org)
From the Julia prompt, type: `] add SeisIO`; (Backspace); `using SeisIO`

## Summary | [Collaboration](docs/CONTRIBUTE.md)
Designed for speed, efficiency, and ease of use. Includes web clients, readers for common seismic data formats, and fast file writers. Utility functions allow time synchronization, data merging, padding time gaps, and other basic data processing.

* Web clients: SeedLink, FDSN (dataselect, event, station), IRIS (TauP, timeseries)
* File formats: ASDF (r/w), Bottles, GeoCSV (slist, tspair), QuakeML (r/w), SAC (r/w), SEED (dataless, mini-SEED, resp), SEG Y (rev 0, rev 1, PASSCAL), SLIST, SUDS, StationXML (r/w), Win32, UW

## Getting Started | [Formats](docs/FORMATS.md) | [Web Clients](docs/WEB.md)
Start the tutorials in your browser from the Julia prompt with

```julia
using SeisIO
cd(dirname(pathof(SeisIO)))
include("../tutorial/install.jl")
```

To run SeisIO package tests and download sample data, execute

```julia
using Pkg, SeisIO; Pkg.test("SeisIO")
```

Sample data downloaded for the tests can be found thereafter at

```julia
cd(dirname(pathof(SeisIO))) 
sfdir = realpath("../test/SampleFiles/")
```

## Publications | [Changelog](docs/CHANGELOG.md) | [Issues](docs/ISSUES.md)
Jones, J.P.,  Okubo, K., Clements. T., \& Denolle, M. (2020). SeisIO: a fast, efficient geophysical data architecture for the Julia language. *Seismological Research Letters* doi: https://doi.org/10.1785/0220190295

This work has been partially supported by a grant from the Packard Foundation.
