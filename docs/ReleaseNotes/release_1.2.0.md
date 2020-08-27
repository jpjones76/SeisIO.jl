v1.2.0 adds submodule `SeisIO.Nodal` for nodal data and some IRISPH5 request support.

# 1. **Public API Changes**
A minor change to SEGY file support could break user work flows that depend on
`read_data("segy", ..., full=true)`. Two keys have been renamed:
* `:misc["cdp"]` => `:misc["ensemble_no"]`
* `:misc["event_no"]` => `:misc["rec_no"]`

## New: IRISPH5 support
Pull request #53 from @tclements: `get_data` now supports IRISPH5 requests for
mini-SEED ("mseed"). (Resolves Issue #52)
* SAC and SEG Y requests to IRISPH5 are not yet implemented.

## New: .Nodal submodule
Added SeisIO.Nodal for reading data files from nodal arrays
* New types:
  + NodalData <: GphysData
  + NodalChannel <: GphysChannel
  + NodalLoc <: InstrumentPosition
* Wrapper: `read_nodal(fmt, file, ...)`
  + Current file format support:
    - Silixa TDMS ("silixa")
    - Nodal SEG Y ("segy") -- Issue #55
* Utility functions: `info_dump`

## New: `read_data("segy", ll=...)`
From Issue #57, `read_data("segy", ...)` has a new keyword: `ll=` sets the
two-character location field in `:id` (NNN.SSS.**LL**.CC), using values in the
SEG Y trace header. Specify using UInt8 codes; see official documentation for
codes and meanings.

# 2. **Bug Fixes**
* Fixed a minor bug with SEG Y endianness when calling `guess`.
* `guess` now tests all six required SEG Y file header values, rather than five.

# 3. **Consistency, Performance**
* The field `:x` of GphysData and GphysChannel objects now accepts either
`AbstractArray{Float64, 1}` or `AbstractArray{Float32, 1}`.

# 4. **Developer API Changes**
* Internal function `SeisIO.dtr!` now accepts `::AbstractArray{T,1}` in first positional argument; fixes Issue #54.
* Resolved Issue #49.

# 5. **Documentation**
* The official documentation has been updated to reflect the above changes.
* When using SeisIO.Formats, the header for the second field is now "format string".
