# SeisIO v1.0.1 patch: 2020-03-05
### 2020-03-05
* `show_writes` now prints filename in addition to write operation
* `merge!` is now logged in a way that `show_processing` catches

### 2020-03-04
* *writesacpz* now has a GphysChannel method
* *write_sxml* is extended to all GphysData subtypes
* The merge tests no longer allow total timespan *δt > typemax(Int64)* when testing *xtmerge!*; this rare case (p ~ 0.003) caused an error.
* The SeedLink test now accurately tracks the time spent for each trial SeedLink session.
* The SeedLink client now accepts keyword *seq="* for starting sequence number, consistent with [SeisComp3 SeedLink protocols](https://www.seiscomp3.org/doc/seattle/2012.279/apps/seedlink.html).

### 2020-03-03
* SEED support functions *seed_support()*, *mseed_support()*, *dataless_support()*, and *resp_wont_read()* now dump all info. to stdout.
* *Manifest.toml* is no longer tracked on GitHub, hopefully preventing dependency conflicts.
* using *get_data(..., w=true)* now logs the raw download write to *:notes*
* The FDSN tests now delete bad request channels before checking if data are written identically in SEED and SAC.
* The *writesac* extension in SeisIO.Quake no longer allows keyword *ts=*; it was not actually used in the function body.

# SeisIO v1.0.0 Release: 2020-03-02
### 2020-03-02
* All file writes should now be logged to *:notes* in appropriate channels and structures.
* `show_writes` tabulates and prints all data writes in `:notes` to stdout.
* renamed `source_log` and `processing_log` to `show_src` and `show_processing`.
* `read_meta`  
  + Now logs all reads to *:notes* in entries that contain *"+meta"* in the second field
  + Now accepts a string array for the file pattern argument.
* `read_sxml` is no longer exported; use `read_meta("sxml", ... )`, instead.
* `wseis` now logs all writes to *:notes* for all objects written.
* `write_hdf5` now logs all writes to *:notes* in all channels written.
* `strict=true` now works with SLIST and Lennartz SLIST files.
* `writesac`
  + Now logs all writes to *:notes* in channels written.
  + Now accepts channel ranges and numeric channel number arrays with KW `chans=`.
  * KW "xy=true" deprecated
  * No longer writes irregular channels
  + No longer allows writing SAC x-y files
`writesacpz`
  + Now accepts a channel list as a keyword argument, specified with *chans=*.
  + For consistency with other write methods, the required arguments have reversed positions; `writesacpz(S, fname)` is now `writesacpz(fname, S)`
* `seedlink`
  + now requires MODE ("TIME", "FETCH", or "DATA") as the first string argument, for consistency with other web clients; it's no longer a keyword.
  + keyword *u=* (base URL) now has a default value in SeisIO.KW.SL, and
  can be changed with `SeisIO.KW.SL.u=URL` for string *URL*.
  + the docstring has been edited to list the correct keywords available.
* `Quake.get_pha!` docstring corrected
* The (potentially very long) tests to download data from the NCEDC and SCEDC servers have been removed, as has the dreaded `servers="all"` test in the Quake submodule. These changes shorten package tests by 3-5 minutes and eliminate most of the timeout errors in Appveyor and Travis-CI.
* `examples.jl` no longer errors on the SeedLink examples when invoked outside the "tests" directory.

### 2020-02-29
* Deprecated `findid(S1, S2)` for two GphysData objects; wasn't useful
* The [Format Reader Guide](../DevGuides/formats.md) was rewritten to include a full API.

### 2020-02-28
* Greatly improved how `read_data!` logs and tracks new data sources.
* The [Time Guide and API](../DevGuides/time.md) was rewritten to include full API and formal definitions of all terms.

### 2020-02-27
* `read_hdf5` no longer errors when start or end time is a DateTime.
* `convert_seis` now correctly errors when `units_out` is invalid.
* `writesacpz` no longer errors when trying to write generic `:resp` or `:loc` objects to SACPZ format.
* `SEG Y` improvements
  + IBM-Float is now supported.
  + Station names are now set in channel IDs from a more appropriate header.
  + `:gain` is once again correctly set.
  + `:units` are now set from the appropriate trace header.
  + Files are now closed when an unsupported data encoding throws an error.

### 2020-02-26
* `get_data`: bad requests and unparseable formats are now logged correctly and
saved to channels with special IDs in the output.
  + Channel IDs that begin with "XX.FAIL" contain bad requests, with the response message stored as a String in `:misc["msg"]`.
  + Channel IDs that begin with "XX.FMT" contain unparseable data. The raw response bytes are stored in `:misc["raw"]` as an Array{UInt8,1}, and can be dumped to file or parsed with external programs as needed.

### 2020-02-24
* `read_meta` now also accepts KW `memmap`.

### 2020-02-22
* Gaps between one-second blocks of data sampled at interval Δ are now only logged if δt > 1.5Δ, rather than δt > Δ. This is now strictly consistent with other file formats.
* `read_data!` now extends existing data channels in all formats.
  + By default, channel data in SeisData structure `S` are extended if the id of the data on file matches a channel id in `S`.
  + Enforce stricter channel matching in most formats with KW `strict=true`.
    - This keyword has no effect on ASCII or SUDS formats.
    - In other formats, `strict=true` always matches on *at least* `:id`, `:fs`
    - Depending on the metadata stored by a given file format, `strict=true` can require a match on `:id`, `:fs`, `:gain`,`:loc`, `:resp`, and `:units` to extend an existing channel.
    - See the official documentation for the fields that must match in each file format when using `strict=true`.

### 2020-02-21
* `readuwevt` now respects the value of `full` passed by the user.

### 2020-02-16
* `read_data!` with an ASCII data format now continues existing channels that match channel ID, rather than starting new ones. Fixes issue #35.
* Found, and fixed, an off-by-one error in start times of GeoCSV tspair time series.
* Internal `buf_to_int()` now always allows ns precision.
* `show_processing` and `show_src` now have docstrings.
* Fixed a longstanding bug where `:src`, `:notes` were not logged by `get_data("IRIS", ..., fmt="sac")`.

### 2020-02-14
#### `read_data` improvements
* A String array can now be passed as the filename argument.
* All file formats can be memory-mapped before reading (KW `memmap=true`), though this only yields significant read speedup if files are very large or in an ASCII data format. **Caution**: Mmap.mmap signal handling in Julia is not documented; this KW should be considered unsafe.

### 2020-02-13
* Fixed a minor bug that could cause some frequency-domain processing routines
to allocate larger arrays than necessary.
* `get_data` calls during automated tests now use a retry script when servers
return no data. This should prevent most web-related errors in ``test SeisIO``.
* Writing station XML now correctly accepts a numeric list of channels `C` with
KW `chans=C`.
* Fixed an off-by-one error that could occur in the last entry of `:t` when
reading two-column (tspair) GeoCSV.

#### File I/O Improvements
* File I/O is being rewritten to avoid Julia thread locking in 1.3. Most
low-level I/O commands use new submodule SeisIO.FastIO. The following internal
changes are now live on master:
  * `eof` ⟹ `fasteof`
  * `position` ⟹ `fastpos`
  * `read` ⟹ `fastread`
  * `readbytes!` ⟹ `fast_readbytes!`
  * `seek` ⟹ `fastseek`
  * `seekend` ⟹ `fastseekend`
  * `skip` ⟹ `fastskip`
* SeisIO.FastIO yields significant speed increases in both Julia v1.3 and
earlier versions.
* ASDF/HDF5 can have unrelated I/O slowdown, noted in [Issues](./ISSUES.md).
For discussion see https://github.com/JuliaIO/HDF5.jl/issues/609.

### 2020-01-24
* Deprecated mini-SEED support for little-endian Steim compression to ensure
compliance with FDSN data standards; resolves issue #33.

### 2019-12-24
* `note!` extended to SeisHdr, SeisSrc objects in SeisIO.Quake

#### The Logging Pass
* Time-stamping now only writes time to a precision of seconds in logs.
* `:tnote` has changed output structure slightly.
* `:src` should now be set consistently with design goals in all functions.
* `:notes` should now always log new data sources so that the commands to
acquire the data can be reproduced.
* The field separator in `:notes` has changed to ` ¦ ` (including spaces); was
  `, `, which led to frequent ambiguities.
* Automated notes now have at least three fields:
  - timestamp, formatted YYYY:MM:DDThh-mm-ss
  -
* New functions for displaying tabulated logging:
  - `show_processing` will tabulate and print all processing steps in `:notes`
  to stdout.
  - `show_src` will tabulate and print all data sources in `:notes` to stdout.
* Data sources logged to `:notes` now have the second field set to `+source`

### 2019-11-20
* Fixed issue #30
* Various internal improvements:
  - Added `merge_ext!` for merging extra fields of future GphysData subtypes.
  - Added `t_arr!` to populate a time array.
* SUDS:
  - Comment structure support status has changed to "display only"; there is no
  feasible way to read them into SeisIO and no evidence anyone ever used them.
  - Fixed a bug where a struct 7 might not set channel fs correctly.
  - `:src` should now be logged correctly for all channels.

### 2019-11-19
* Fixed issue #29
  - `ungap!` should no longer break when encountering subsample negative gaps
  of length `-0.5Δ ≤ δt < -Δ`
  - `merge!` now handles sample times more robustly in overlapping segments

### 2019-11-15
* The tutorial has been updated and expanded to include more practice writing
ASDF volumes and an optional tutorial for the Quake submodule.

#### SeisHDF
* Added `asdf_waux` as a thin wrapper to write to the "AuxiliaryData" group.

#### Bugs/Consistency
* Fixed issue #28
* UW events with no external event ID in the pick file now set the event ID
from the pick file name (if available) or data file name (if no pick file).
* Fixed a bug where PASSCAL SEG Y stored 1.0/gain to `:gain`.
* Fixed a minor bug with PASSCAL SEG Y channel names.
* The docstring for `read_quake` is now correctly accessed with `?read_quake`.

### 2019-11-02
#### SeisHDF
* Added `asdf_wqml` to write QuakeML to a (new or existing) ASDF file.
* Added `read_asdf_evt` to read events from an ASDF archive and return an
array of SeisEvent structures.
* Added a `write_hdf5` method for SeisEvent structures.
* Renamed `asdf_qml` => `asdf_rqml`.

#### Bugs/Consistency
* `read_qml`: SeisSrc structures with uninitialized array fields now return
empty fields, rather than fields filled with program defaults (e.g. zeros);
this is more consistent with `SeisSrc()` and the `isempty` method extension for
this Type.

### 2019-11-01
* Added `write_qml` to write and append QuakeML files.

#### Bugs/Consistency
* Fixed bug where reading QuakeXML wrote standard error in a Location element
to loc.rms rather than loc.se.
* SeisSrc objects created with `randSeisEvent` now have `:pax` and `:planes`
fields whose geometries are consistent with what `read_qml` produces.
* When using `read_qml`, the `:src` fields of .hdr, .hdr.loc, .hdr.mag, and
.source now follow an internally consistent format.

### 2019-10-30
* Added `tag` as a keyword to `write_hdf5` to allow user control over the tag
in the trace name string.
  + If unset, the channel name is used.
  + Previously, the default tag was the channel name with a trailing underscore.

### 2019-10-25
* The string to read Lennartz SLIST (ASCII) in `read_data` has changed from
"lennasc" to "lennartz".
* Empty SAC character strings are written correctly by `writesac` again.
* `writesac` now handles data gaps by writing one segment per file. Previous
behavior of assuming no gaps was poorly documented, albeit intentional.
* For better similarity to other software, the option to write to SAC as
generic x-y data now uses the keyword "xy=true", rather than "ts=true".

### 2019-10-23
* Added `asdf_qml` to read QuakeML from ASDF files.

### 2019-10-19
* `write_hdf5` improvements:
  + added KW `chans` to support writing only some channels from a structure.
  + calling `write_hdf5` on an existing file now appends data to the file,
  rather than recreating it.
  + users can now specify `add=true` to add trace data to a file while preserving
  the structure of existing traces. See `write_hdf5` docstring for details.
  + users can now specify `ovr=true` to overwrite existing trace data in a file.
  See `write_hdf5` docstring for details.
  + irregularly-sampled channels are now skipped.

* Performance
  + Reduced memory overhead of `write_sxml` by ~80% with significant speedup.
  + `ungap!` and `gapfill!` have been optimized for better memory usage.
    - The docstring of `ungap!` now explicitly warns to call `merge` before `ungap`
    if any channel has segments that aren't in chronological order.

* Bugs/Consistency
  * `endtime(t, fs)` once again behaves correctly for irregularly-sampled data.
  * `ungap!` with a negative time gap now partly overwrites output with earlier
  segments (corresponding to the time overlap).
  * `merge!` once again works consistently with `MultiStageResp` responses.
  * `write_hdf5` can now write gapped channels.

# SeisIO v0.4.1 Release: 2019-10-13
