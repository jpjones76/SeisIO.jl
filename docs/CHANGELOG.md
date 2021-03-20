# 2021-03-19
* `writesac` now allows the user to specify SAC file header version (SAC variable NVHDR) using keyword `nvhdr=`. The default is 6. Versions 6 and 7 are supported.
  + Reason for change: SAC won't read a file if NVHDR is greater than expected.
    - Example: SAC v101.x (NVHDR = 6) *will not* read a SAC file created in/for SAC v102.x (NVHDR = 7), even though the two file header versions are effectively interchangeable.
* `filtfilt!`: breaking combinations of data and filter parameters should now be identical in `DSP.filtfilt` and `SeisIO.filtfilt!`, even on Float32 data.
  + Implicit feature request from issue #82.
  + This should never force data conversion to Float64. (We already test this.)
  + It's always possible to choose a filter that outputs NaNs, but the two filtering functions should now behave identically in this regard.

# SeisIO v1.2.0 Release: 2021-02-02

# 2021-01-31
* Calling `writesac` on a SeisEvent object now always writes event header values to the correct byte indices for SAC v101 and above.
* `SeisData(S::T) where T<:GphysData` should now be aliased to `convert(SeisData, S)` for all GphysData subtypes.

# 2021-01-29
* New developer (internal) function `cmatch_p!`:
  + Matches a pair of GphysChannel objects on (:fs, :id, :loc, :resp, :units)
  * Declares a match even if some fields are unset in one object
  * On a match, unset fields in each object are copied from the other object
* SAC read/write support extended to SAC v7 (files produced by/for SAC v102.0).

# 2021-01-27
* `merge!` has been extended to pairs of GphysChannel objects. Non-default values must be identical in :fs, :id, :loc, :resp, :units.
* `convert` expansion:
  + `convert(NodalData, S)` and `convert(EventTraceData, S)` should now work for all GphysData subtypes.
  + `convert(NodalChannel, C)` and `convert(EventChannel, C)` should now work for all GphysChannel subtypes.
  + `EventTraceData(S::T) where T<:GphysData` is now aliased to `convert(EventTraceData, C)`.
  + `EventChannel(C::T) where T<:GphysChannel` is now defined as an alias to `convert(EventChannel, C)`.
* Calling `writesac` on a SeisEvent object now writes event IDs that can be parsed to Int32.
* New function `fill_sac_evh!` in submodule Quake fills SeisEvent header info from a SAC file.

# 2020-12-03
* `ChanSpec` now includes `StepRange{Int, Int}` in its Type union
* Added processing function `rescale!` for fast conversion and matching of scalar gains

# 2020-12-02
* `writesac` should now write begin time (word 6) in a way that never shifts sample times, even by subsample values. (Fixes issue #60)

# 2020-11-23
* `ungap!` should now work correctly on a channel whose only time gap occurs before the last sample. (Fixes issue #74)

# 2020-10-31
* `scan_seed` now always parses Blockette [1000]. (Fixes issue #73)

# 2020-10-30
* Fixed a performance issue when reading a large file whose data contain many negative time gaps. (#72)

# 2020-10-29
* Added utility `scan_seed` to submodule `SeisIO.SEED` for SEED volumes. (#62)
  + `scan_seed` can report changes within a SEED file, including:
    - Samples per channel (KW `npts`)
    - Gaps (KW `ngaps`), or exact gap times (`seg_times=true`)
    - Changes in sampling frequency (KW `nfs`), or exact times of fs changes (`fs_times=true`)
  + Reports to stdout (suppress with `quiet=true`)
  + Returns a String array of comma-delineated outputs, one entry per channel.
  + Please open feature request Issues if you need to scan for additional changes within SEED volumes.
  + This won't interact directly with online SEED requests. To use `scan_seed` with an online request for a seed volume, use `w=true` to dump the raw request to disk, and scan the file(s) created by the download.

# 2020-10-27
* NodalData no longer errors on `resample!`; fixes issue #65. (Merged PR #68 from tclements/Resample)

# 2020-10-26
* NodalLoc (:loc field of NodalData) now has x, y, z subfields. (Merged PR #64 from tclements/NodalLoc)
* NodalData now uses AbstractArray{Float32, 2} for the :data field, rather than Array{Float32, 2}. (Merged PR #66 from tclements/Nodal)

# SeisIO v1.1.0 Release: 2020-08-26
# 2020-08-26
* HDF5 compatibility has changed to "0.12, 0.13" as HDF5.jl v0.13.5 fixes the read slowdown issue. Versions of HDF5 in range 0.12.3 < VERSION < 0.13.5 might still have slow HDF5 read times. Resolves issue #49.

# 2020-08-22
* `read_nodal` has switched channel syntax to use `chans=` for numeric channel
values, lists, or ranges, as the data processing functions. The keywords `ch_s`
and `ch_e` have been removed.
* Channel names and IDs in `read_nodal` now use the channel number from the file.
* Changed the initialization method for NodalData to avoid using any keywords:
`NodalData(data, info, ts; ch_s, ch_e` is now `NodalData(data, info, chans, ts)`

# 2020-08-18
* `read_nodal` now requires a format string as the first argument
  + This change makes syntax identical to `read_data(fmt, file, ...)`
* Implemented `read_nodal` SEG Y format in SeisIO.Nodal; requested in Issue #55
  + Note that `read_nodal("segy", ... )` produces different `:id` values
* Fixed a bug where `read_data("segy", ..., full=true)` could copy some SEGY file header values to `:misc` keys in the wrong byte order.

## Dev/Backend:
* `do_trace` no longer uses `fname` as a positional, but needs a UInt8 for `ll`

# 2020-08-17
* Fixed Issue #56
* When calling `read_data("segy", ..., full=true)`, two key names have changed:
  + `:misc["cdp"]` => `:misc["ensemble_no"]`
  + `:misc["event_no"]` => `:misc["rec_no"]`
* Fixed Issue #57 : `read_data("segy", ...)` has a new keyword: `ll=` sets the
two-character location field in `:id` (NNN.SSS.**LL**.CC), using values in the
SEG Y trace header:
  * 0x00 None (don't set location subfield) -- default
  * 0x01 Trace sequence number within line
  * 0x02 Trace sequence number within SEG Y file
  * 0x03 Original field record number
  * 0x04 Trace number within the original field record
  * 0x05 Energy source point number
  * 0x06 Ensemble number
  * 0x07 Trace number within the ensemble

# 2020-08-11
* Automated testing for Julia v.1.4 has ended. Tested versions of the language include v1.0 (LTS) and v1.5 (stable).
* Changed internal function `SeisIO.dtr!` to accept `::AbstractArray{T,1}` in first positional argument; fixes Issue #54
* Added tests for processing functions on a NodalData object; tests Issue #54
* Added explicit warning that `translate_resp!` can be acausal; from discussion of Issue #47

# 2020-07-15
Added SeisIO.Nodal for reading data files from nodal arrays
* New types:
  + NodalData <: GphysData
  + NodalChannel <: GphysChannel
  + NodalLoc <: InstrumentPosition
* Wrapper: `read_nodal`
  + Current file format support: Silixa TDMS (default, or use `fmt="silixa"`)
* Utility functions: `info_dump`

### 2020-07-09
* The data field `:x` of GphysData and GphysChannel objects can now be
  an AbstractArray{Float32, 1} or AbstractArray{Float64, 1}.
* Merged pull request #53 from @tclements: `get_data` now supports IRISPH5
for mseed and geocsv. (Implements request in issue #52)
  + Both `get_data("PH5")` and `get_data("FDSN", ..., src="IRISPH5")` work.
  + SAC and SEGY support is NYI.
  + PH5 GeoCSV doesn't parse correctly at present, and will error if a
  decimation key is passed to `opts=`. At issue is the precision of GeoCSV
  floats was documented only by oral tradition. This will be fixed in a future
  patch.

### 2020-07-02
* minor bug fix: in Julia v1.5+, calling `sizeof(R)` on an empty `MultiStageResp`
  object should no longer throw an error
* `resample!` has been rewritten, fixing issues #50 and #51. syntax and keywords
are unchanged.
  + The current version consumes slightly more memory than the previous one.
  + There may be one further rewrite in coming weeks, to switch to FFT-based filtering.

### 2020-06-18
* `get_data` should no longer error when a multiday request begins on a day when one channel has no data. (Issue #43)
* Fixed behavior of reading a SEED Blockette 100 to match the mini-SEED C library. (Issue #48)
* Parsing SEED Blockette 100 now logs `:fs` changes to `:notes`.

### 2020-05-30
* Automated testing for Julia v.1.3 has ended. Tested versions of the language include v1.0 (LTS), v1.4 (stable), and v1.5 (upcoming release).

### 2020-05-28
* `get_data("IRIS", ...)` now accepts `fmt="sac"` as an alias to `fmt="sacbl"`.

#### IRISWS changes
A server-side issue with IRISWS timeseries, affecting `get_data("IRIS", ... )`, has caused minor behavior changes:
* While `:gain` still appear to be 1.0 in SeisIO, the channel gain is now set (and hence, unscaled, but logged to `:notes`) in SAC and GeoCSV requests. Other data formats still don't do this.
* SAC and GeoCSV currently set lat, lon, and el in requests, but mini-SEED doesn't. Until requests return format-agnostic locations, `get_data("IRIS", ... )` will return an empty GeoLoc() object for the `:loc` field.

##### Potential Inconsistencies
However, as a result of the above changes:
1. With `get_data("IRIS", ... , w=true)`, `:misc` is now always format-dependent.
2. For formats "geocsv" and "sac", `S = get_data("IRIS", ... , w=true)` now differs slightly from calling `read_data` on the files created by the `get_data` command.
  + `:loc` will be set in objects read from SAC and GeoCSV files, but not mini-SEED.
  + Data in objects read from SAC or GeoCSV files will be scaled by the Stage 0 gain; fix this with `unscale!`.

### 2020-05-16
* Documentation improvements for issue #44 and #45.
* Fixed issue #43; reading Steim-compressed mini-SEED into an existing channel with a Float64 data vector.

### 2020-04-07
* Improved reading unencoded mini-SEED data with byte swap (part of issue #40)  
* Bug fix for issue #42.

### 2020-03-14
* mini-SEED can now parse unencoded data to structures of any GphysData subtype

### 2020-03-13
* *sync!* has been rewritten based on @tclements suggestions (Issue #31). Notable changes:
  * Much less memory use
  * Much faster; ~6x speedup on tests with 3 channels of length ~10^7 samples
  * More robust handling of unusual time matrices (e.g., segments out of order)
* The [tutorial page](https://seisio.readthedocs.io/en/latest/src/Help/tutorial.html) has been updated. Fixes issue #39.

### 2020-03-10
* Automated testing for Julia v.1.1-1.2 has ended. Tested versions of the language include v1.0 (LTS), v1.3 (stable), and v1.4 (upcoming release).
* The docstring `?chanspec` was renamed `?web_chanspec` to avoid confusion with SeisIO internals.
* The docstring `?timespec` was renamed to `?TimeSpec`.
* Quake Type *SeisEvent* now has a real docstring.
* Quake Type *EventChannel* has a docstring again.

### 2020-03-09
* Rewrote SeisIO.RandSeis for faster structure generation
  + randSeisChannel has two new keywords: fs_min and fc
  + randSeisData has two new keywords: fs_min and a0
* More documentation and docstring updates
* The data processing functions *ungap!*, *taper!*, *env!*, *filtfilt!*, and *resample!* can no longer be forced to work on irregularly-sampled data by doing clever things with keywords.
* *taper* now has a docstring
* ASDF file reads now close all groups and datasets after reading

### 2020-03-07
* Increased the robustness of *t_extend*; it no longer needs a mini-API.
* Tests now handle time and data comparison of re-read data more robustly.
* *show*
  - now reports correct number of gaps with a gap before the last sample in *:x*
  - now identifies times in irregular data as "vals", not "gaps".
* *write_asdf*
    + When *ovr=false*, a sample window with the same ID, start time, end time as a trace in the output volume now never overwrites the trace in the output volume.
* Fixed a very rare case in which two rows of a time matrix could correspond to the same sample index
* *read_data*: formats "slist" and "lennartz" now use verbosity

#### QuakeML
+ Reading QuakeML with no magnitude now returns an empty hdr.mag structure
+ *write_qml*
  - now writes hdr.loc.typ to Origin/type
  - now writes hdr.loc.npol to focalMechanism/stationPolarityCount
  - added method for SeisEvent

#### SAC
Data files no longer track the LOC field of `:id` on read or write.
+ We learned only recently that LOC has no standard SAC header variable: some data sources store this as KHOLE, which we used in the past, but this is correctly an event property in the [format spec](http://ds.iris.edu/files/sac-manual/manual/file_format.html).

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
