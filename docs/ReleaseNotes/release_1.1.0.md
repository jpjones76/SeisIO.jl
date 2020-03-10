This is largely a patch for 1.0.0, focused on documentation updates, a few consistency changes, and fixes for several rare or minor bugs. The minor version has been incremented for strict compliance with semantic versioning, because the SAC change breaks user work flows that match `:id` against SAC data files.

# 1. **Public API Changes**
## **SAC**
* SAC data files no longer track the LOC field of `:id`; thus, IDs `NN.SSSSS.LL.CCC` and `NN.SSSSS..CCC` will be written and read identically to/from SAC.
  + This change realigns SeisIO SAC handling with the format spec.
  + *Explanation*: Some data sources store the LOC field of `:id` in KHOLE (byte offset 464). We followed this convention through SeisIO v1.0.0. However, KHOLE is an event property -- not a station property -- in the [format spec](http://ds.iris.edu/files/sac-manual/manual/file_format.html).

# 2. **Bug Fixes**
* SEED submodule support functions (e.g. `mseed_support()`) now correctly info dump to stdout
* Fixed a very rare bug in which two rows of a time matrix could have the same sample index
* *merge!* is now logged in a way that *show_processing* catches
* *read_qml* on an event with no magnitude element now yields an empty `:hdr.mag`
* *show* now reports true number of gaps when `:x` has a gap before the last sample
* *write_hdf5* with *ovr=false* no longer overwrites a trace in an output volume when two sample windows have the same ID, start time string, and end time string; instead, the tag string is incremented
  + This was previously possible only with two segments from one channel that started and ended on the same second; it's very unlikely that this bug was seen in real data
* The data processing functions *ungap!*, *taper!*, *env!*, *filtfilt!*, and *resample!* can no longer be forced to work on irregularly-sampled data by doing clever things with keywords.
* Irregularly-sampled data channels are no longer writable to ASDF, which, by design, cannot handle irregularly-sampled data.
* HDF groups and datasets are now all closed after reading.

# 3. **Consistency Changes**
* *get_data* with *w=true* now logs the raw download write to *:notes*
* *seedlink, seedlink!* now accept keyword *seq="* for starting sequence number, consistent with [SeisComp3 protocols](https://www.seiscomp3.org/doc/seattle/2012.279/apps/seedlink.html)
* *show* now identifies times in irregular data as "vals", not "gaps"
* *show_writes* now prints the filename in addition to the write operation
* *write_qml* now:
  - writes `:hdr.loc.typ` to *Event/Origin/type*
  - writes `:hdr.loc.npol` to *Event/focalMechanism/stationPolarityCount*
  - has a method for direct write of *SeisEvent* structures
* *write_sxml* now works with all GphysData subtypes
* *read_data* now uses verbosity for formats "slist" and "lennartz"

## **SeisIO Test Scripts**
Fixed some rare bugs that could break automated tests.
* *test/TestHelpers/check_get_data.jl*: now uses a *try-catch* loop for *FDSNWS station* requests
* *tests/Processing/test_merge.jl*: testing *xtmerge!* no longer allows total timespan *δt > typemax(Int64)*
* *tests/Quake/test_fdsn.jl*:  KW *src="all"* is no longer tested; too long, too much of a timeout risk
* *tests/Web/test_fdsn.jl*: bad request channels are deleted before checking file write accuracy
* Tests now handle time and data comparison of re-read data more robustly

# 4. **Other Changes**
* Most internal functions have now switched from keywords to positional args
  * RandSeis: `populate_arr!`, `populate_chan!`
  * SeisHDF: `write_asdf` (note: doesn't affect `write_hdf5`)
  * SeisIO: `FDSN_sta_xml` , `FDSNget!` , `IRISget!` , `fdsn_chp` , `irisws` , `parse_charr` , `parse_chstr` , `read_station_xml!` , `read_sxml` , `sxml_mergehdr!` , `trid`
* Rewrote SeisIO.RandSeis for faster structure generation
  + randSeisChannel has two new keywords: *fs_min* and *fc*
  + randSeisData has two new keywords: *fs_min* and *a0*
* [Official documentation](https://seisio.readthedocs.io/) updated
* Many docstrings have been updated and standardized. Notable changes:
  + *?timespec* is now *?TimeSpec*
  + *?chanspec* is now *?web_chanspec*
  + *?taper* now exists
  + *?seedlink* keywords table corrected
  + Quake *?EventChannel* now exists
  + Quake *?get_pha!* now describes the correct function
* Updated and expanded the tutorial

## **Internals**
* *t_extend* is now more robust and no longer needs a mini-API
  + previously, some rare cases of time matrix extension could break. They were likely never present in real data -- e.g., a time matrix with a gap before the last sample, extended by another sample -- but they were theoretically possible.
  + the rewrite covers and tests all 7 possible cases of time matrix extension.
* *check_for_gap!* is now a thin wrapper to *t_extend*, ensuring uniform behavior
* The internal functions in SeisIO.RandSeis have changed significantly. This will break work flows that imported RandSeis internals.
