# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

[![Build Status](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=master)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934/branch/master?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl/branch/master)

## Documentation
http://seisio.readthedocs.org

## Functionality
Includes web clients, readers for several data formats, and writers for SAC and a native SeisIO format. Utility functions allow time synchronization, data merging, and padding time gaps.

| **Web clients** | **Readable File Formats** |
|:----------------|:--------------------------|
| SeedLink | mini-SEED |
| FDSN (data, event, station)| SAC |
|  IRIS (timeeseries) | SEG Y (rev 0, rev 1, PASSCAL/NMT) |
|| Win_32 |
|| UW |

### Installation
From the command line, press `]` to enter the Package environment, then type (or copy) these commands:

```
add https://github.com/jpjones76/SeisIO.jl; build; precompile; test SeisIO
```

Dependencies should install automatically.

## Known Issues
* Rarely, `SeedLink!` may cause a Julia session to hang when a connection fails to initialize.

### System-Dependent Issues
* Package dependency Arpack (required by Blosc) sometimes fails to build with ERROR: LoadError: LibraryProduct(nothing, ["libarpack"], :libarpack, "Prefix([path])") is not satisfied, cannot generate deps.jl!
  + Affects: Linux 4.19.16-1-MANJARO (x86_64) with Julia 1.0.3-2
  + Impact: could break file i/o in native format
  + Workaround: upgrade to Julia 1.1.0 Generic Linux Binaries for x86 (64-bit)

## Changelog
### 2019-02-15
* Backend improvements to mSEED reader
  + `readmseed` now attempts to skip SEED blockettes of unknown type, rather than throwing an error
  + Fixes bug #7

### 2019-02-13
* +Julia 1.1, -Julia 0.7.
* Minor bug fix in SAC.jl.

### 2018-08-10
* Updated for Julia 0.7. Testing for 1.0.
* `wseis` has changed:
  + New syntax: `wseis(filename, objects)`
  + Keywords are no longer accepted.
* `SeisHdr` has changed:
  + The field `:mag` (magnitude) is now Tuple(Float32, String) to allow freeform magnitude scale designations. (was: Tuple(Float32, Char, Char))
* `batch_read` has been removed.
* Switched to HTTP.jl due to Requests.jl being abandoned by its creators.
  + In web requests, keyword `to=` (timeout) must now be an Integer. (was: Real)
* SeisIO objects can no longer be saved in single-object files.
* Notable bug fixes:
  + Issues with `wseis` and `SeisHdr` objects should be corrected.
  + Improved partial string matches for channel names and IDs.

## Acknowledgements
miniSEED routines are based on rdmseed.m for Matlab by Francois Beauducel, Institut de Physique du Globe de Paris (France). Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services;  Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format; and Roberto Carniel (Universita di Udine, Italy) for assistance with testing.

## References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
