# Known Issues
* **Source tracking** (`:src` and copying `:src` to `:notes` on overwrite) is unreliable at present. Standardizing this is a priority for v0.5.0.
* **`FDSNevq(..., src="all")`**: no checks are made for redundant events or that all servers are up (the latter is *not* always true). Can yield duplicates or lead to connection timeouts.
* **`write_hdf5` with SeisEvent**: phase and source-receiver geometry are not yet written to ASDF volumes when `write_hdf5(..., fmt="ASDF")` is invoked on a SeisEvent structure.

# Incomplete File Formats
## To Add
If you want support expanded for any of these, **please send us test files**, along with some expected values.
* **ASDF** test files are needed with the following properties:
  + Waveforms with attributes `event_id`, `magnitude_id`, `focal_mechanism_id`
  corresponding to values in `QuakeML`
  + Waveforms with `provenance_id` corresponding to values in `Provenance`
* **SEG Y** test files are needed for the following:
  + IBM Float. IEEE Float has been the standard floating-point data format since 1985; in fact, SEG Y is one of four extant binary data formats *in the entire world* with IBM Float. We've never seen it in real data.
  + Trace header coordinates set to values that aren't x = 0, y = 0.
  + SEG Y rev 2.
  + Seismic Unix ("SU"), the "other" trace-only SEGY variant (in contrast to PASSCAL SEG Y). Note that the SU and PASSCAL variants are mutually unintelligible; the trace headers are different, so reading SU as PASSCAL won't work.

## Out of Scope
If you find an example that you feel should be supported, but isn't, please open a new Issue.
* **SEED** blockettes that aren't in the scope of SeisIO are skipped.
  + `read_data("mseed", ...)` only parses blockette types listed in `SeisIO.SEED.mseed_support()`.
  + `read_meta("dataless", ...)` only parses blockette types listed in `SeisIO.SEED.seed_support()`.
* **SUDS support** doesn't include all possible structure types. The color coding of the structure number in the output of `SeisIO.SUDS.suds_support()` gives the status:
  + *Green* structures should be readable without issue.
  + *Yellow* structures contain metadata outside the scope of SeisIO. Info can be dumped to stdout at high verbosity but isn't read into memory.
  + *Red* structures are skipped.

# External, Fixable
* **SCEDC connection issues**: See gist: https://gist.github.com/jpjones76/0175e762bea8c37d99b97ef3cb056068

# External / Won't Fix
* **Coverage**: rarely, reported code coverage drops to 94-95%, rather than 97-98%. This happens when Travis-CI fails to upload test results to code coverage services, even if tests pass. True coverage has been >97% since at least 2019-06-06.
* **Geophone response translation**: a few permanent North American short-period stations have tremendous (two orders of magnitude) scaling problems with `translate_resp` and `remove_resp`.
  * Test: using `get_data("FDSN", ...)`, check channel ``i`` with ``S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"``. We've only seen this bug with instruments matching this description.
    + This description may be shorthand for "Geospace Technologies HS-1-LT geophone with Kinemetrics Quanterra Q330 digitizer", but no "HS-1-LT" exists on the [Geospace Technologies product website](https://www.geospace.com/sensors/).
* **SEG Y files with nonstandard trace headers** generally won't read. Only six quantities have mandatory positions in a trace header in SEG Y <= rev 1.0; here, a "nonstandard" trace header means that a file has a "recommended" trace header quantity in an unexpected place (or absent). In order to support the SEG Y format at all, we assume most "recommended" values are present where indicated in the format specification.

# Reporting New Issues
If possible, please include a text dump of a minimum working example (MWE), including error(s) thrown (if any).
