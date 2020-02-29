Adding Data Formats: guidelines for readers and writers

# 1. Mandatory Parameters
File readers must:
* return a SeisData or SeisEvent structure.
* be fully compatible with at least one "read" wrapper (`read_data`, `read_hdf5`, `read_meta`, `read_quake`).
  - HDF5-based file formats belong in submodule SeisHDF.
* faithfully log the file or data source to `:src` so that the read operation can be reproduced.

## New/custom file formats: why...?
Seismology alone has ~10^2 file formats. Before adding support for a new one, ask yourself if this is both necessary and useful.

## Forbidden Practices
* No new keywords in "read" wrappers without prior approval
* No new wrappers without prior approval

# 2. Strongly Suggested
* Import `SeisIO.Formats.formats` and add an appropriate description of the your format.
* Tests for file formats belong in `test/FileFormats/test_($format).jl`, whether or not the reader is part of a submodule.
* Once your reader works, consider replacing low-level function calls with equivalents in `SeisIO.FastRead`.

# 3. Useful Functions
* `SeisIO.BUF` has fields intended as buffers for data I/O.
  - A two-step processing of buffering, then converting to SeisData, is often much faster than reading directly to `:x`.
* `check_for_gap` can check for time gaps and modify `:t`.
* `mk_t` can initialize new time matrices.

# 4. Other Requirements
## Never sort a GphysData structure in a reader
`read_data` will break, and so will your reader
