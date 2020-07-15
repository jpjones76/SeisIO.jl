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
* Wrapper: `read_nodal`
  + Current file format support: Silixa TDMS (default, or use `fmt="silixa"`)
* Utility functions: `info_dump`

# 2. **Bug Fixes**

# 3. **Consistency, Performance**
* The field `:x` of GphysData and GphysChannel objects now accepts either
AbstractArray{Float64, 1} or AbstractArray{Float32, 1}.

# 4. **Developer API Changes**

# 5. **Documentation**
