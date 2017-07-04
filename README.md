# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

# Documentation
http://seisio.readthedocs.org

# CHANGELOG
## Current (2017-07-04)
* Updated for Julia v0.6.0. Compatibility with earlier versions is not guaranteed. Please report any deprecation warnings!

## 2017-04-19
* Moved pol_sort to the Polarization project.
* SeisIO data files now include searchable indices at the end of each file.
  + This change is backwards-compatible and won't affect the ability to read existing files.
  + A file index contains the following information, written in this order:
    - (length = ∑\_j∑\_i length(S.id[i])\_i) IDs for each trace in each object
    - (length = 3∑\_j S.n\_j) start and end times and byte indices of each trace in each object. (time unit = integer μs from Unix epoch)
    - Byte index to start of IDs.
    - Byte index to start of Ints.

## 2017-03-15
* SeisData merge has been rewritten for greater functionality.
  + Merge speed improved by orders of magnitude for multiple SeisData objects
  + `merge!(S,T)` combines two SeisData structures S,T in S.
  + `mseis!(S,...)` merges multiple SeisData structures into S. (This command will handle as many SeisData objects as system memory allows, e.g. `mseis!(S1, S2, S3, S4, S5)`, etc.).
  + `S = merge(A)` merges an array of SeisData objects into a new object S.
* Arithmetic operators for SeisData objects have been standardized:
  + `S + T` appends T to S without merging.
  + `S * T` merges T into S, equivalent to `merge(S,T)`.
  + `S - T` removes traces whose IDs match T from S.
  + `S ÷ T` is undefined at present but may eventually provide unmerge functionality.
  + Generally, `S+T-T = S`, but `S-T+T != S`.
  + Arithmetic operators no longer operate in place. `S+T` creates a new SeisData object; `S` is not modified.
* Web functions no longer synchronize request outputs by default. Instead, data requests can be synchronized with the keyword argument y=true.
* Minor changes to `sync!`:
  + No longer de-means traces.
  + No longer cosine tapers around gaps.
* SeisIO now includes an internal version of the "ls" command; this is not exported to prevent conflicting with other third-party modules, so access with `SeisIO.ls`.
* Automatic file write with IRISget and FDSNget now generates file names that follow the IRIS-style naming convention `YY.JJJ.HH.MM.SS.sss.(id).ext`.
* Fixed a bug that broke the .t field on channels where length(S[i].x) = 1.
* Single-object files can now be written by specifying `sf=true` when calling wseis. By default, single-object file names use IRIS-style naming conventions.
* Promoted the Polarization submodule to a separate GitHub project.
* Minor bugfixes: randseischannel, randseisdata, randseisevent, autotap!, IRISget, SeisIO.parserec!, SeisIO.ls, SeisIO,autotuk!

## Known Issues (2017-07-04)
* readmseed uses an exorbitant amount of memory (~32x file size).
* Julia 0.6.0 slowed batch_read execution time by roughly a factor of 4; it currently offers only ~10-20% speedup over standard file read methods and is not useful in present form. This is slated for an eventual rewrite.

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
