SeisIO v0.4.1
2019-10-13

Primarily a bug fix release for v0.4.0, with the addition of write support for FDSN station XML files and the ASDF file format.

## New Writers
* Added `write_hdf5` to allow writing complete structures to seismic HDF5 files. Currently only supports ASDF; PH5 may be added later.
* Added `write_sxml` to create station XML from SeisData headers.
  + Note: output is valid FDSN station XML 1.1 but the IRIS validator may issue up to two warnings per channel inconsistently; see stationxml-validator issue [78](https://github.com/iris-edu/stationxml-validator/issues/78) for details.

## Consistency, Performance, Bug Fixes
* Added a file reader for SLIST (ASCII sample list) (`read_data("slist", ...)`), since I have readers for two SLIST variants (lennartzascii and geocsv.slist)...
* `resample` will no longer throw an error if the desired sampling frequency equals `:fs` for the largest group of segments. Fixed `resample` docstrings.
* `SEED.mseed_support()` and `SEED.seed_support()` now output some text; users don't need to check their respective help files.
* Added kw `autoname` to `get_data`; see documentation for functionality and behavior. Implements request in issue #24.
* Discovered/fixed a rare mini-SEED bug wherein the last packet of a request containing unencoded data could throw a BoundsError if padded with empty bytes. * The memory footprint of SeisIO has been reduced by moving most large files to https://github.com/jpjones76/SeisIO-TestData. SeisIO now requires ~3 MB rather than ~300 MB.
  + The development version is somewhat unwieldy due to the commit history; without test files, it's around 500 MB. This can be safely pruned with BFG Repo-Cleaner with a file size threshold of 50k.
  + Test data now have their own repository. They're downloaded automatically by `tests/runtests.jl` when the script is first invoked, but `runtests.jl` now requires a Subversion command-line client to run.
* `read_data("seisio", ...)` now works as a wrapper to `rseis`
  + Note: this is a convenience wrapper and lacks the full functionality of `rseis`. When reading a SeisIO file that contains multiple objects, `read_data("seisio", ...)` reads only the first object in each file that can be converted to a SeisData structure.
* User agent settings are now standardized and should no longer cause error 500 on FDSN servers in California.
* `get_data` now warns when requesting a (non-miniseed) format from FDSN dataselect servers that don't implement the `format` keyword.

### SeedLink renamed and fixed
* Functions `SeedLink` and `SeedLink!` have been renamed to lowercase (they're now `seedlink` and `seedlink!`) because `SeedLink` was too easily mistaken for a custom Type.
* Fixed an issue that broke SeedLink connectons in v0.4.0; SeedLink connections once again process buffered data without manual intervention.
