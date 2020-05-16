# **Document Purpose**
This document lists problems that are not our fault and can't be fixed by us. GitHub Issues opened about items listed here will be closed with a comment referring the opener to this document.

## Issues Key
* I = Incomplete file support. If support is needed, please send us test files with expected values and adequate documentation. Please note that official documentation alone does not satisfy any known definition of "adequate" in any issue listed here.
* O = Out of scope; won't fix.
* X = External; can't fix.

# **List of Non-SeisIO Issues**
* **32-bit support** (O): SeisIO is designed for 64-bit systems and won't work in 32-bit versions of Julia.
* **ASDF support** (I)
  + `Waveform` group attributes `event_id`, `magnitude_id`, `focal_mechanism_id` are not yet matched to `QuakeML` group attributes.
  + `Provenance` is not fully supported.
  + `write_hdf5(..., fmt="ASDF")` doesn't write source-receiver geometry to ASDF volumes when invoked on a SeisEvent structure.
* **Code coverage** (X): reported coverage sometimes appears to be 94%, rather than ~99%.
* **FDSNevq(..., src="all")** (X): no checks are possible for event uniqueness or server status.
* **Quanterra geophone responses** (X): a few permanent North American short-period stations have tremendous (two orders of magnitude) scaling problems with `translate_resp` and `remove_resp`.
  * Details: all known cases have an XML `SensorDescription` value of "HS-1-LT/Quanterra 330 Linear Phase Composite". This description seems to mean "Geospace Technologies HS-1-LT geophone with Kinemetrics Quanterra Q330 digitizer", but no "HS-1-LT" exists on the [Geospace Technologies product website](https://www.geospace.com/sensors/).
* **NCEDC/SCEC connection issues** (X): [see gist](https://gist.github.com/jpjones76/0175e762bea8c37d99b97ef3cb056068)
* **SEED blockette support** (O): blockettes outside the scope of SeisIO aren't read into memory.
* **SEED with little-endian Steim compression** (X)
  + See issue #33. This isn't valid SEED.
  + mini-SEED in ObsPy writes these files by default in rare cases.
* **SEG Y files with nonstandard trace headers** (X)
  + If SEG Y files use nonstandard trace headers, they're unreadable by public software.
    - Details: only six trace header quantities have mandatory positions and value types in SEG Y ≤ rev 1.0. All public software assumes "recommended" trace header positions, including ours.
* **SEG Y subformats** (I)
  + SEG Y rev 2 is unsupported.
  + Seismic Unix ("SU") is unsupported.
* **SUDS structures** (I,O): structures outside the scope of SeisIO aren't read into memory.

## Issues with Workarounds
* **HDF5 variations in I/O speed** (X): [HDF5.jl issue #609](https://github.com/JuliaIO/HDF5.jl/issues/609). Most combinations of library version and Julia language version have this issue.
  + **Workaround**: Rebuild Julia from source with HDF5 <=v0.12.3.

# **Reporting New Issues**
[Always report issues here](https://github.com/jpjones76/SeisIO.jl/issues). If possible, please include a minimum working example (MWE) and text dump of error(s) thrown (if applicable). GitHub Issues that are in-scope and internal to SeisIO remain open until fixed. Significant external (X) and out-of-scope (O) issues will be added to this document.
