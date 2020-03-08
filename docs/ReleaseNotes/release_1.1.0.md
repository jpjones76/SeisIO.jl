v1.1.0: 2020-03-07

New minor version because the SAC change could break user work flows that match on `:id` to/from SAC data files.

# 1. **Public API Change**
## **SAC**
* Data files no longer track the LOC field of `:id`; thus, IDs `NN.SSSSS.LL.CCC` and `NN.SSSSS..CCC` will be written (read) identically to (from) SAC.
  + This change realigns SeisIO SAC handling with the format spec.
  + *Explanation*: we learned only recently that LOC has no standard SAC header variable: some data sources stored this in KHOLE, which we used in the past, but this is correctly an *event* property (not a station property) in the [format spec](http://ds.iris.edu/files/sac-manual/manual/file_format.html).

# 2. **Bug Fixes**
* SEED submodule support functions (e.g. `mseed_support()`) now correctly info dump to stdout
* Fixed a very rare bug in which two rows of a time matrix could have the same sample index
* *merge!* is now logged in a way that *show_processing* catches
* *read_qml* on an event with no magnitude element now returns a header whose `:mag` field SeisIO considers empty
* *show* now reports true number of gaps when `:x` has a gap before the last sample
* *write_hdf5* with *ovr=false* no longer overwrites a trace in an output volume when two sample windows have the same ID, start time string, and end time string; instead, the tag is incremented
  + This was previously possible only with two segments from one channel that started on the same second and ended on the same second; it's unlikely that anyone encountered this situation with real data.

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
  * `FDSN_sta_xml`
  * `FDSNget!`
  * `IRISget!`
  * `fdsn_chp`
  * `irisws`
  * `parse_charr`
  * `parse_chstr`
  * `read_station_xml!`
  * `read_sxml`
  * `sxml_mergehdr!`
  * `trid`
* [Official documentation](https://seisio.readthedocs.io/) reorganized for better navigation
* Many docstrings have been updated and standardized
* Updated the tutorial

## **Internals**
* *t_extend* is now more robust and no longer needs a mini-API
  + previously, not all cases of time matrix extension were covered.
  + this rewrite cover all 7 possible cases of time matrix extension, with full tests
* *check_for_gap!* is now a thin wrapper to *t_extend*, ensuring uniform behavior
