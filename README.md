# SeisIO
A minimalist, platform-agnostic package for working with univariate geophysical data.

# Documentation
http://seisio.readthedocs.org

# CHANGELOG
## 2017-03-15
* SeisData merge has been rewritten for greater functionality.
  + Merge speed improved by orders of magnitude for multiple SeisData objects
  + `merge!(S,T)` combines two SeisData structures S,T in S.
  + `mseis!(S,...)` merges multiple SeisData structures into S. (This command will handle as many SeisData objects as system memory allows, e.g. `mseis!(S1, S2, S3, S4, S5)`, etc.).
  + `S = merge(A)` merges an array of SeisData objects into a new object S.
* Arithmetic operators for SeisData objects have been standardized:
  + `S + T` appends T to S without merging.
  + `S * T` merges T into S via `merge(S,T)`.
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
* *In progress*: SeisIO data files will soon include searchable indices at the end of each file.
  + This change is backwards-compatible and won't affect the ability to read existing files.
  + The file index will store trace IDs of each SeisIO object written, start times, end times, and byte indices.

## 2017-01-31
* Documentation was completely rewritten.
* All web functions now use the channel naming convention NET.STA.LOC.CHA.
* Renamed several web function keywords for uniformity.
* All web functions that require channel input now accept a config. filename, a String, or a String array.
* Keyword initialization in new SeisData objects has been permanently disabled.
* The native SeisIO file format has changed.
* `prune!(S)` is now `merge!(S)`
* A few unused functions and accidental exports were removed.

## Known Issues (2017-03-17)
* readmseed uses an exorbitant amount of memory (~32x file size). This may be endemic to the data format.

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
