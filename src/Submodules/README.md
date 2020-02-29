# Submodules
Create a submodule for any set of functions that require vastly more internal
functions than the code exports.

## Expected Code Coverage
95% overall, 95% per file unless dealing with digital coelocanths

## File Naming
1. Each submodule needs a file in `Submodules/` named `($submodule).jl` and
a directory `Submodules/($submodule)`.

## Submodule Creation Guidelines
Please also read [CONTRIBUTE.md](../../docs/CONTRIBUTE.md).

### File Readers
* File readers must return a SeisData or SeisEvent structure and be compatible
with at least one "read" wrapper (`read_data`, `read_hdf5`, `read_meta`,
`read_quake`).
  - Please don't create readers that will require additional keywords in
  `read_data` or `read_meta` without approaching us first.
* For a new reader, remember to import SeisIO.Formats.formats and add an
appropriate description for the file format.
* Tests for file formats belong in `test/FileFormats/test_($format).jl`,
whether or not the reader is in a submodule.

### Types
Please read [adding_types.md](../../docs/DevGuides/adding_types.md).
