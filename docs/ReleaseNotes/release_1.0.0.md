SeisIO v1.0.0: Publication release
2020-03-02

This release coincides with the first SeisIO publication: Jones, J.P., Okubo, K., Clements. T., & Denolle, M. (2020). SeisIO: a fast, efficient geophysical data architecture for the Julia language. The paper was accepted by Seismological Research Letters in January 2020.

Major feature expansions and code changes include:
* Standardization of automated logging
* Workaround for Julia thread locking
* Significant improvements to *read_data*
* Full support for ASDF (Advanced Seismic Data Format)
* Write support for StationXML and QuakeML

This release is designated SeisIO v1.0.0 because it's the first release that I feel meets all basic goals established when I created SeisIO.

# **File I/O and Thread Locking**
File I/O now avoids the thread-locking disease introduced in Julia v1.3.0. Most low-level I/O commands have been changed in the following ways:
```
   eof          ⟹ fasteof
   position     ⟹ fastpos
   read         ⟹ fastread
   readbytes!   ⟹ fast_readbytes!
   seek         ⟹ fastseek
   seekend      ⟹ fastseekend
   skip         ⟹ fastskip
```
In some cases these changes yield significant speed increases. Popular data formats may read slightly slower or faster (±3%), but any observed slowdown is likely due to better logging.

# **Logging Improvements**
Logging to *:notes* and *:src* has been broadened and standardized.

## *:src* field in SeisIO structures
* Reading metadata no longer overwrites *:src*.
* *:src* should now be set consistently with design goals by all functions.

## *:notes* field in SeisIO structures
* The field separator for a single note has changed to ` ¦ ` (including spaces); the old separator (`,`) was problematic.
* New data sources should always be logged accurately, allowing user to easily reproduce the acquisition commands.
* Automated notes now have at least three fields, including the timestamp.
* Time stamp format for notes is now `YYYY:MM:DDThh-mm-ss`.
* Time stamps now have a precision of seconds. Millisecond timestamps were unnecessary.
* Notes that log data sources now set the second field of the note to *+source*
* `tnote` output changed slightly.
* `note!` now extends to SeisHdr and SeisSrc objects in SeisIO.Quake

## *get_data* logging
Bad requests and unparseable formats are now logged to special output channels; see below.

## Other logging
* `read_meta` logs all reads to *:notes* in entries that contain "+meta" in the second field
* All writes are now logged to *:notes*:
  * `writesac` now logs all writes to channels written.
  * `wseis` now logs all writes to (all channels of) objects written.
  * `write_hdf5` now logs all writes to all channels written.

## New functions for checking logs
* `show_processing` tabulates and prints processing steps in *:notes*
* `show_src` tabulates and prints data sources in *:notes*
* `show_writes` tabulates and prints all data writes in *:notes*

# **Improvements to** *read_data*
* A String array can now be passed as the file string pattern argument with method `read_data(fmt, filestr [, keywords])`. This functionality will eventually be expanded to `read_data(filestr [, keywords])`.
* All file formats can now be memory-mapped before reading by passing KW *memmap=true*. SeisIO benchmarks suggest that this affects some read speeds:
  + *Significant speedup*: ASCII formats, including metadata formats
  + *Slight speedup*: mini-SEED
  + *Significant slowdown*: SAC
  + Other data formats show trivial changes in read speed (at most ±3%).
  + Mmap.mmap signal handling is undocumented. Use with caution.
* When reading into an existing structure, stricter channel matching can now be enforced with KW *strict=true*. See below.
* ASCII data formats now always continue existing channels that match channel ID, rather than starting new ones. Fixes issue #35.
* Verbose source logging can be enabled with new KW *vl=true*. There are cases where this can log sources to *:notes* that are irrelevant to a channel; verbosity isn't always efficient.
* The format string to read Lennartz SLIST (ASCII) with *read_data* has changed from "lennasc" to "lennartz".

## Channel Extension
Existing data channels should now be extended on a successful channel ID match in all file formats. This is the intended behavior of SeisIO.

Previously, all formats except mini-SEED and ASDF created a new channel for every new file read, which required flattening with *merge!*. That was a clumsy work flow.

The new behavior standardizes the output because multiple files read with many *read_data!* calls should yield the same number of channels as passing all filenames to *read_data!* in an Array{String, 1} or String wildcard.

### Behavior with *strict=true*
* Does not work with GeoCSV or SUDS formats.
* Matches on *at least* both of *:id* & *:fs* in all other formats.
* In the best-case scenario, *read_data* matches on *:id*, *:fs*, *:gain*,*:loc*, *:resp*, & *:units*.
* See official documentation for fields matched in each file format.

# **ASDF/HDF5**
ASDF (Adaptable Seismic Data Format) is now fully supported. Specific changes from SeisIO v0.4.1 are below.

## *write_hdf5* Changes
+ KW *chans* supports writing only some channels from a structure.
+ calling *write_hdf5* on an existing file now appends data to the file, rather than recreating it.
+ users can now specify *add=true* to add trace data to a file while preserving existing traces in it. See documentation for details.
+ users can now specify *ovr=true* to overwrite existing trace data in a file.
See documentation for details.
+ irregularly-sampled channels are now skipped.
+ gapped channels are now written to file by segment.
+ KW *tag* allows user control over the tag in the trace name string.
  - If unset, the channel name is used.
  - Previously, the default tag was the channel name with a trailing underscore.
+ Includes a method for SeisEvent structures in submodule Quake.

## New/Changed ASDF Functions
* `asdf_qml` was renamed to `asdf_rqml` as it reads QuakeML from ASDF files.
+ `asdf_wqml` writes QuakeML to a new or existing ASDF file.
+ `read_asdf_evt` reads events from an ASDF archive and returns an array of SeisEvent structures.
+ `asdf_waux` is a thin wrapper to write to the AuxiliaryData group.

# **Other Changes**
## Documentation Improvements
* The tutorial has been updated and expanded to include more practice working with ASDF volumes and an optional tutorial for the Quake submodule.
* Several docstrings were greatly truncated to reduce scrolling.
* The Time developer guide now includes a full API and formal definitions.
* The File Formats developer guide now includes a full API.

## `examples.jl`
* Everything in *examples.jl* is now also part of the Data Acquisition tutorial.
* `using Pkg; Pkg.test("SeisIO")` now tells users where to find *examples.jl* at the end of a successful test set.
* no longer errors on the second SeedLink example when invoked outside the "tests" directory.

## Consistency, Performance, Bug Fixes
* `seedlink`, `seedlink!`
  + now requires MODE ("TIME", "FETCH", or "DATA") as the first string argument, for consistency with other web clients; it's no longer a keyword.
  + SeedLink keyword *u=* (base URL) now has a default value in SeisIO.KW.SL and
  can be changed with `SeisIO.KW.SL.u=URL` for string *URL*.
* `Quake.get_pha!` docstring corrected.
* `read_meta` now accepts an *Array{String, 1}* for the file pattern argument.
* `read_sxml` is no longer exported; use *read_meta("sxml", ... )* instead.
* Functions that accept a verbosity level *v* now accept any Integer subtype, not just Int64.
* Fixed a minor bug that could cause some frequency-domain processing routines to allocate larger arrays than necessary.
* Fixed issue #30
* Fixed issue #28
* `endtime(t, fs)` once again behaves correctly for irregularly-sampled data.
* The docstring for *read_quake* is now correctly accessed with `?read_quake`.
* SeisSrc objects created with *randSeisEvent* now have *:pax* and *:planes* fields whose geometries are consistent with what *read_qml* produces.
* `rseis` now supports memory mapping with KW *mmap=true*.
* `convert_seis` now correctly errors when *units_out* is invalid.

### *get_data*
Bad requests are now saved to channels with special IDs.
* Channel IDs that begin with "XX.FAIL" contain bad requests, with the response message stored as a String in *:misc["msg"]*.
* Channel IDs that begin with "XX.FMT" contain unparseable data. The raw response bytes are stored in *:misc["raw"]* as an Array{UInt8,1}, and can be dumped to file or parsed with external programs as needed.
* Information about bad requests is logged to *:notes* in these special channels.
* *get_data* calls during automated tests now use a retry script when servers return no data. This should prevent most test errors due to server-side data availability.

### *merge!*
* Should work more consistently with *MultiStageResp* instrument responses.
* Now handles sample times more robustly in overlapping segments.

### *ungap!* and *gapfill!*
These low-level processing functions have been optimized for better memory usage. Additional specific changes:
* *ungap!* no longer breaks on negative subsample gaps of length -0.5 *Δ* ≤ *δt* < -1.0 *Δ* at sampling interval *Δ*. Fixes issue #29.
* The docstring of *ungap!* now explicitly warns to call *merge!* before *ungap!* if any channel has segments that aren't in chronological order.
* *ungap!* with a negative time gap now partly overwrites output with earlier
segments (corresponding to the time overlap).

### GeoCSV
+ Fixed a possible off-by-one error in two-column (tspair) GeoCSV channel start times
+ Fixed a possible off-by-one error in the last entry of *:t* when reading two-column (tspair) GeoCSV

### PASSCAL SEG Y
* Fixed a bug where PASSCAL SEG Y could store 1.0/gain as *:gain*.
* Fixed a minor bug with PASSCAL SEG Y channel names created from incomplete trace header fields.

### QuakeML
* `write_qml` writes and appends QuakeML.
* `read_qml`
  + The *:src* fields of *.hdr*, *.hdr.loc*, *.hdr.mag*, and *.source* now follow an internally consistent format.
  + Fixed a bug where standard error wasn't being parsed to *:loc.se*.
  * Uninitialized array fields in SeisSrc structures created by this function now have empty fields, rather than fields filled with zeros, consistent with the method extension of `isempty()` to *SeisSrc* objects.

### SAC
* `writesac`
  + Now accepts a range of channels with keyword *chans=*.
  + Fixed a bug where some empty SAC character strings were written incorrectly
  + Now handles data gaps by writing one segment per file. The old behavior of assuming no gaps was undocumented and undesirable, albeit intended when the function was written.
  + KW *"xy=true"* deprecated
  + No longer writes irregular channels
  + No longer allows writing SAC x-y files
* `writesacpz`
  + Now accepts a channel list as a keyword argument, specified with *chans=*.
  + For consistency with other write methods, the required arguments have reversed positions; `writesacpz(S, fname)` is now `writesacpz(fname, S)`

#### Explanation of Changes
The intent of writing SAC x-y was to allow a convenient way to write irregular channels to file, with sample values in *y* and sample times in *x* measured relative to SAC header start time.

However, at time precision *δt*, representational problems begin at (t_max - t_min) > maxintfloat(Float32, Int64) [δt]. Yet maxintfloat(Float32, Int64) = 16,777,216.

This means that writing irregular data to SAC x-y either requires user-specified sampling accuracy (like ".01 s"), or uses native (μs) time differences; the former is a terrible workflow, and the latter loses faithful Float32 representation 16 s after data collection begins.

### SEG Y
Please note that these changes do not affect the PASSCAL SEG Y variant.
+ IBM-Float is now supported.
+ Station names are now set in channel IDs from more appropriate headers.
+ *:gain* is once again correctly set.
+ *:units* are now set from the appropriate trace header.
+ File streams should now always close before an unsupported data encoding throws an error.

### SUDS
* Comment structures are now only displayed to stdout at high verbosity. There is no good way to read them into SeisIO and no evidence anyone used them.
* Fixed a bug where reading a Struct 7 could sometimes set *:fs* incorrectly.

### StationXML
* Writing station XML now accepts a numeric channels specifier *C* with KW *chans=C*.
* Reduced memory overhead of *write_sxml* by ~80% with significant speedup.

### UW
* *readuwevt* and *read_quake("UW", ...)* now respect the value of *full* passed by the user.
* UW events with no external event ID in the pick file now set the event ID from the pick file name (if available) or data file name (if no pick file).

### Win32
Gaps between one-second blocks of data sampled at interval *Δ* are now only logged if *δt* > *1.5Δ*, rather than *δt* > *Δ*, consistent with other file formats.

### mini-SEED
Deprecated mini-SEED support for little-endian Steim compression for consistency with FDSN standards; resolves issue #33.
