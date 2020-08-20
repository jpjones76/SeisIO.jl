v1.2.0 adds `SeisIO.Nodal` for working with nodal data and limited IRISPH5 support.

A minor change to SEGY file read can break user work flows that use `full=true` and retrieve either renamed key.

Other changes include code consistency improvements for GPU compatibility.

# 1. **Public API Changes**

## New: IRISPH5 support
Pull request #53 from @tclements: `get_data` now supports IRISPH5 requests for
mseed and geocsv. (Issue #52)

## New: .Nodal submodule
Added SeisIO.Nodal for reading data files from nodal arrays
* New types:
  + NodalData <: GphysData
  + NodalChannel <: GphysChannel
  + NodalLoc <: InstrumentPosition
* Wrapper: `read_nodal(fmt, file, ...)`
  + Current file format support:
    + Silixa TDMS ("silixa")
    + Nodal SEG Y ("segy")
* Utility functions: `info_dump`

# 2. **Bug Fixes**
* When calling `read_data("segy", ..., full=true)`, two key names have changed:
  + `:misc["cdp"]` => `:misc["ensemble_no"]`
  + `:misc["event_no"]` => `:misc["rec_no"]`
* `guess` now tests all six required SEG Y file header values, rather than five.

# 3. **Consistency, Performance**
* The field `:x` of GphysData and GphysChannel objects now accepts either AbstractArray{Float64, 1} or AbstractArray{Float32, 1}.
* Issue #57 : `read_data("segy", ...)` has a new keyword: `ll=` sets the two-character location field in `:id` (NNN.SSS.**LL**.CC), using values in the SEG Y trace header:
  + 0x00 None (don't set location subfield) -- default
  + 0x01 Trace sequence number within line
  + 0x02 Trace sequence number within SEG Y file
  + 0x03 Original field record number
  + 0x04 Trace number within the original field record
  + 0x05 Energy source point number
  + 0x06 Ensemble number
  + 0x07 Trace number within the ensemble

# 4. **Developer API Changes**
* Internal function `SeisIO.dtr!` now accepts `::AbstractArray{T,1}` in first positional argument; fixes Issue #54.

# 5. **Documentation**
* The official documentation has been updated to reflect the above changes.
* When using SeisIO.Formats, the header for the second field is now "format string".
