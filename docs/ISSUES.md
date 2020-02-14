# List of Known Bugs and Issues
* **ASDF support** (I)
  + No support for waveform attributes `event_id`, `magnitude_id`, `focal_mechanism_id` corresponding to values in `QuakeML`.
  + No support for `Provenance`. Files are needed where seismograms have `provenance_id` values corresponding to values in `Provenance`.
  + `write_hdf5(..., fmt="ASDF")` doesn't write source-receiver geometry to ASDF volumes when invoked on a SeisEvent structure.
* **Code coverage** (X): if Travis-CI fails to upload test results from a successful run, reported coverage can appear to be 94%, rather than 99%. True coverage has been continuously >97% since 2019-06-01 and >99% since 2019-11-15.
* **FDSNevq(..., src="all")** (X): no checks are made for redundant events or that servers are up. Can lead to duplicate events or connection timeouts.
* **Quanterra geophone responses** (X): a few permanent North American short-period stations have tremendous (two orders of magnitude) scaling problems with `translate_resp` and `remove_resp`. All have the property SensorDescription = "HS-1-LT/Quanterra 330 Linear Phase Composite".
  * This description may be shorthand for "Geospace Technologies HS-1-LT geophone with Kinemetrics Quanterra Q330 digitizer", but no "HS-1-LT" exists on the [Geospace Technologies product website](https://www.geospace.com/sensors/).
  * Test: from the output of `get_data("FDSN", ...)`, check channel ``i`` with ``S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"``.
* **HDF5 variations in I/O speed** (X): see https://github.com/JuliaIO/HDF5.jl/issues/609. Other combinations of library versions and Julia language versions may also produce this slowdown.  
* **SCEC connection issues** (X): see gist at https://gist.github.com/jpjones76/0175e762bea8c37d99b97ef3cb056068
  + We try to fix this as new browser versions are released. However, a permanent fix would need to be implemented server-side by SCEC.
* **SEED blockette support** (O): SEED blockettes outside the scope of SeisIO (e.g., "status" and "health") are not read into memory.
* **SEED with little-endian Steim compression** (X)
  + This isn't valid SEED.
  + FDSN requires Steim compression to use big-endian word order.
  + Little-endian Steim compression has never been officially defined.
    - The definition in `libmseed.c` works for programs that parse mini-SEED with it; however, this definition is slated for removal in a future version of libmeed.
  + mini-SEED in ObsPy can write such files by default in rare cases.
  + See discussion of issue #33.
* **SEG Y files with nonstandard trace headers** (X)
  + Some industry SEG Y files have nonstandard trace headers. These are unreadable in SeisIO, as with any public software.
  + Cause: only six quantities have mandatory trace header positions and value types in SEG Y ≤ rev 1.0. Others were all "recommended".
  + In order to support the SEG Y format at the same level as other data formats, it's necessary to assume "recommended" trace headers.
* **SEG Y subformats** (I)
  + IBM Float is unsupported. IEEE Float has been the standard floating-point data format since 1985; SEG Y is one of four extant file formats that allows IBM Float. We've never seen it in real data.
  + SEG Y rev 2 is unsupported.
  + Seismic Unix ("SU") is unsupported. PASSCAL SEG Y is orders of magnitude more common, but the two variants are mutually unintelligible due to trace header differences.
* **SUDS structures** (I,O): structures outside the scope of SeisIO are not read into memory.
* **get_data() with ASCII formats** (B): multi-day requests will error due to no channel ID matching in geocsv parsers (issue #35).

## Issues Key
* B = Bug, internal; fixable by SeisIO developers
* I = Incomplete file support. Here, if support is needed, **please send us test files** with expected values and adequate documentation. For the cases below, official documentation does not satisfy any known definition of "adequate", which is why it's presently unsupported.
* O = Out of scope; can't be fixed
* X = External; can't be fixed

# Reporting New Issues
Always report issues [here](https://github.com/jpjones76/SeisIO.jl/issues). If possible, please include a text dump of a minimum working example (MWE), including error(s) thrown (if any).

Issues determined to be internal to SeisIO and within its scope will be listed here until fixed. Significant external (X) and out of scope (O) issues may be listed here as permanent reminders that they exist.
