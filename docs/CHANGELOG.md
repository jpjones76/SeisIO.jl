# 2020-08-11
* Automated testing for Julia v.1.4 has ended. Tested versions of the language include v1.0 (LTS) and v1.5 (stable).
* Changed internal function dtr! to accept `::AbstractArray{T,1}` in first
positional argument; fixes Issue #54
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

# SeisIO v1.1.0 Release: 2020-07-07
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
