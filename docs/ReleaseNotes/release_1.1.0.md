SeisIO v1.1.0
2020-08-27

SeisIO v1.1.0 adds submodule `SeisIO.Nodal` for nodal data, plus initial support for IRISPH5 requests. Other changes include fixes to several rare and/or minor bugs, code consistency improvements, a much-needed *sync!* rewrite, and documentation updates.

# 1. **Public API Changes**
## **SAC**
* SAC data files no longer track the LOC field of `:id`; thus, IDs `NN.SSSSS.LL.CCC` and `NN.SSSSS..CCC` will be written and read identically to/from SAC.
  + This change realigns SeisIO SAC handling with the [official format spec](http://ds.iris.edu/files/sac-manual/manual/file_format.html).
  + *Explanation*: Some data sources store the LOC field of `:id` in KHOLE (byte offset 464). We followed this convention through SeisIO v1.0.0. However, KHOLE is usually an event property.

## **SeedLink**
Functions *seedlink* and *seedlink!* now accept keyword *seq=* for starting sequence number, consistent with [SeisComp3 protocols](https://www.seiscomp3.org/doc/seattle/2012.279/apps/seedlink.html).

## **SEG Y**
A minor change to SEGY file support could break user work flows that depend on `read_data("segy", ..., full=true)`. Two keys have been renamed:
* `:misc["cdp"]` => `:misc["ensemble_no"]`
* `:misc["event_no"]` => `:misc["rec_no"]`

### New: `read_data("segy", ll=...)`
`read_data("segy", ...)` has a new keyword: `ll=` sets the two-character location field in `:id` (NNN.SSS.**LL**.CC), using values in the SEG Y trace header. Specify using UInt8 codes; see official documentation for codes and meanings.

## **IRISWS timeseries**
SeisIO has made some minor changes to `get_data("IRIS", ... )` behavior, due to server-side changes to IRISWS timeseries:
* The Stage 0 (scalar) gain of each channel is logged to `:notes` for fmt="sacbl" ("sac") and fmt="geocsv".
* The output of `get_data("IRIS", ... , w=true)` differs slightly from calling `read_data` on the files created by the same command:
  + This affects the fields `:misc` and `:notes`.
  + `:loc` will be set in objects read from SAC and GeoCSV files, but not mini-SEED.
  + Data in objects read from SAC or GeoCSV files will be scaled by the Stage 0 gain; fix this with `unscale!`.

## **New: .Nodal submodule**
Added SeisIO.Nodal for reading data files from nodal arrays
* New types:
  + NodalData <: GphysData
  + NodalChannel <: GphysChannel
  + NodalLoc <: InstrumentPosition
* Wrapper: `read_nodal(fmt, file, ...)`
  + Current file format support:
    - Silixa TDMS ("silixa")
    - Nodal SEG Y ("segy")
* Utility functions: `info_dump`

# 2. **Bug Fixes**
* Fixed a minor bug with SEG Y endianness when calling `guess`.
* `guess` now tests all six required SEG Y file header values, rather than five.
* SEED submodule support functions (e.g. `mseed_support()`) now correctly info dump to stdout
* *merge!* is now logged in a way that *show_processing* catches
* *read_qml* on an event with no magnitude element now yields an empty `:hdr.mag`
* *show* now reports true number of gaps when `:x` has a gap before the last sample
* Fixed two breaking bugs that were probably never seen in real data:
  + Extending a time matrix by appending a one-sample segment to `:x` can no longer break time handling; see changes to *t_extend* for fix details.
  + *write_hdf5* with *ovr=false* no longer overwrites a trace in an output volume when two sample windows have the same ID, start time string, and end time string; instead, the tag string is incremented.
    - This previously happened when two or more segments from one channel started and ended within the same calendar second.
* The data processing functions *ungap!*, *taper!*, *env!*, *filtfilt!*, and *resample!* now correctly skip irregularly-sampled channels.
* Irregularly-sampled channels are no longer writable to ASDF, which, by design, does not handle irregularly-sampled data.
* ASDF groups and datasets are now always closed after reading with *read_hdf5*.
* In Julia v1.5+, calling `sizeof(R)` on an empty `MultiStageResp` object should no longer error.

## **SeisIO Test Scripts**
Fixed some rare bugs that could break automated tests.
* *test/TestHelpers/check_get_data.jl*: now uses a *try-catch* loop for *FDSNWS station* requests
* *tests/Processing/test_merge.jl*: testing *xtmerge!* no longer allows total timespan *δt >  typemax(Int64)*
* *tests/Quake/test_fdsn.jl*: KW *src="all"* is no longer tested; too long, too much of a timeout risk
* *tests/Web/test_fdsn.jl*: bad request channels are deleted before checking file write accuracy
* Tests now handle time and data comparison of re-read data more robustly

# 3. **Consistency, Performance**
* The field `:x` of GphysData and GphysChannel objects now accepts either `AbstractArray{Float64, 1}` or `AbstractArray{Float32, 1}`.
* *get_data* with *w=true* now logs the raw download write to *:notes*
* *show* now identifies times in irregular data as "vals", not "gaps"
* *show_writes* now prints the filename in addition to the write operation
* *write_qml* now:
  - writes `:hdr.loc.typ` to *Event/Origin/type*
  - writes `:hdr.loc.npol` to *Event/focalMechanism/stationPolarityCount*
  - has a method for direct write of *SeisEvent* structures
* *write_sxml* now works with all GphysData subtypes
* *read_data* now uses verbosity for formats "slist" and "lennartz"
* *get_data("IRIS", ...)* now accepts `fmt="sac"` as an alias to `fmt="sacbl"`
* *sync!* has been rewritten based on @tclements suggestions (Issue #31). Notable changes:
  * Much less memory use
  * Much faster; ~6x speedup on tests with 3 channels of length ~10^7 samples
  * More robust handling of unusual time matrices (e.g., segments out of order)
* *SeisIO.RandSeis* functions have been optimized.
    + *randSeisChannel* has two new keywords: *fs_min*, *fc*
    + *randSeisData* has two new keywords: *fs_min*, *a0*

# 4. **Developer API Changes**
* Internal function `SeisIO.dtr!` now accepts `::AbstractArray{T,1}` in first positional argument.
* Most internal functions have switched from keywords to positional arguments. This includes:
  * SeisIO: `FDSN_sta_xml` , `FDSNget!` , `IRISget!` , `fdsn_chp` , `irisws` , `parse_charr` , `parse_chstr` , `read_station_xml!` , `read_sxml` , `sxml_mergehdr!` , `trid`
  * SeisIO.RandSeis: `populate_arr!`, `populate_chan!`
  * SeisIO.SeisHDF: `write_asdf` (note: doesn't affect `write_hdf5`)
* *t_extend* is now more robust and no longer needs a mini-API
  + previously, some rare cases of time matrix extension could break. They were likely never present in real data -- e.g., a time matrix with a gap before the last sample would break when extended by another sample -- but these "end-member" cases were theoretically possible.
  + the rewrite covers and tests all possible cases of time matrix extension.
* *check_for_gap!* is now a thin wrapper to *t_extend*, ensuring uniform behavior.
* Internal functions in *SeisIO.RandSeis* have changed significantly.

# 5. **Documentation**
* [Official documentation](https://seisio.readthedocs.io/) updated
* Many docstrings have been updated and standardized. Notable examples:
  + *?timespec* is now *?TimeSpec*
  + *?chanspec* is now *?web_chanspec*
  + *?taper* once again exists
  + *?seedlink* keywords table is once again current
  + *SeisIO.Quake*:
    - *?EventChannel* now produces a docstring, rather than an error
    - *?get_pha!* once again describes the correct function
* Updated and expanded the Jupyter tutorial
* Updated and expanded the time API

# **Index**: GitHub Issues Fixed
* #31 : *sync!* rewritten.
* #39 : tutorial updated.
* #42 : mini-SEED calibration blockettes of this type parse correctly again.
* #43 : reading Steim-compressed mini-SEED into an existing channel with an empty Float64 data vector should no longer error. `get_data` should no longer error when the first part of a segmented request includes no data from some channels.
* #44 : documentation updated.
* #45 : documentation updated.
* #48 : mini-SEED Blockette 100 handling should now match the IRIS mini-SEED C library.
* #49 : the read speed slowdown in HDF5.jl was fixed; SeisIO no longer requires HDF5 v0.12.3.
* #50 : `resample!` now consistently allows upsampling.
* #51 : `resample!` now correctly updates `:t` of a gapless SeisChannel.
* #52 :  merged PR #53, adding initial support for IRISPH5 requests
* #54 : `SeisIO.dtr!` now accepts `::AbstractArray{T,1}` in first positional argument
* #55 : added `read_nodal("segy")`
* #56 : implemented as part of initial SeisIO.Nodal release
* #57 : fixed by addition of KW `ll=` to `read_data`

**Note**: v1.1.0 was originally released 2020-07-07. Re-releasing, rather than incrementing to v1.2.0, fixes an issue that prevented Julia from automatically registering v1.1.0.
