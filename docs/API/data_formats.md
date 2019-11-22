Adding Data Formats: a mini-API for creating readers and writers.

# 1. Mandatory Parameters
File readers must:
* return a SeisData or SeisEvent structure; never return a SeisChannel.
* be fully compatible with at least one "read" wrapper (`read_data`,
  `read_hdf5`, `read_meta`, `read_quake`).
  - HDF5-based file formats belong in submodule SeisHDF.
* faithfully log the file or data source to `:src` so that the read operation
can be reproduced.

Don't add custom file formats or create new ones. If a file format isn't
published and has never been in widespread use, supporting it wastes
everyone's time.

# 2. Strongly Suggested
* Unless it's absolutely necessarily for code to work, please don't add keywords to "read" wrappers.
* For a new reader, please remember to import SeisIO.Formats.formats and add an appropriate description of the file format.
* Tests for file formats belong in `test/FileFormats/test_($format).jl`, whether or not the reader is part of a submodule.

# 3. Useful Functions
* `SeisIO.BUF` has fields intended as buffers for data read from file.
  - A two-step processing of buffering, then converting to SeisData, is often much faster than reading directly to `:x`.
* `check_for_gap` can check for time gaps and modify `:t`.
* `mk_t` can initialize new time matrices.
