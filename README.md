# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

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

### Julia v0.7.0
| **Build Status: Julia v0.7.0** |
|:-------------------------------------------------------------------------------:|
| [![](https://travis-ci.org/jpjones76/SeisIO.jl.svg?branch=master)](https://travis-ci.org/jpjones76/SeisIO.jl) [![Build status](https://ci.appveyor.com/api/projects/status/ocilv0u1sy41m934?svg=true)](https://ci.appveyor.com/project/jpjones76/seisio-jl) |

### Julia v1.0.0
* SeisIO runs after minor manual fixes to some dependencies. See below.

## Known Issues (2018-08-12)
* Rarely, `SeedLink!` may cause a Julia session to hang when a connection fails to initialize.
* In Julia v0.7, LightXML and Blosc generate "deprecated syntax" warnings.
* SeisIO has broken dependencies in Julia v1.0.

### Building for Julia 1.0.0
Four dependencies must be modified for SeisIO to work in Julia 1.0: DSP, Blosc, and CMake/CMakeWrapper. If you'd rather do this yourself than wait for the official fixes, it takes very little time:

* Add CMake.jl and CMakeWrapper.jl directly from their GitHub sites:
  ```
  ]
  (v1.0) pkg> add https://github.com/JuliaPackaging/CMake.jl
  (v1.0) pkg> add https://github.com/JuliaPackaging/CMakeWrapper.jl
  (v1.0) pkg> build CMake
  (v1.0) pkg> build CMakeWrapper
  ```
* In (src)/packages/Blosc/src/Blosc.jl, replace both calls to 'isbits' with 'isbitstype'
  + After modification, rebuild Blosc:
  ```
  ]
  (v1.0) pkg> build Blosc
  ```
* In (src)/packages/DSP/src/periodograms.jl and util.jl, update the DSP iterator syntax:
  + Refer to the pull request at  https://github.com/JuliaDSP/DSP.jl/pull/220/commits/de6157495772588b434bb24b2e7f6612bd0d6161
  + In each of the above two .jl files, replace the text in *red* in the pull request with the text in *green*
  + After saving your modifications, rebuild DSP:
  ```
  ]
  (v1.0) pkg> build DSP
  ```
* Compile and test SeisIO:
  ```
  ]
  add SeisIO; precompile; test SeisIO
  ```

## Changelog
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
