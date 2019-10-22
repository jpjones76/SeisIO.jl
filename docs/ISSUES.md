# Known Issues
* **Source tracking** (`:src` and copying `:src` to `:notes` on overwrite) is unreliable at present. Standardizing this is a priority for v0.5.0.
* **`FDSNevq(..., src="all")`**: no checks are made for redundant events or that all servers are up (the latter is *not* always true). Can yield duplicates or lead to connection timeouts.
* **SEED support** doesn't include all possible blockette types. Blockettes that aren't in the scope of SeisIO are skipped.
  + `read_data("mseed", ...)` only parses blockette types listed in `SeisIO.SEED.mseed_support()`.
  + `read_meta("dataless", ...)` only parses blockette types listed in `SeisIO.SEED.seed_support()`.
* **SUDS support** doesn't include all possible structure types. The color coding of the structure number in the output of `SeisIO.SUDS.suds_support()` gives the status:
  + *Green* structures should be readable without issue.
  + *Yellow* structures contain metadata outside the scope of SeisIO. Info can be dumped to stdout at high verbosity but isn't read into memory.
  + *Red* structures are skipped.
* **Some SEG Y variants aren't supported**. Please open a new Issue if you need read support for any of these:
  + IBM Float (any SEG Y version). IEEE Float has been the standard floating-point data format since 1985; in fact, SEG Y is one of four extant binary data formats *in the entire world* with IBM Float. We've never seen it in real data.
  + SEG Y rev 2.
  + Seismic Unix ("SU"), the "other" trace-only SEGY variant (in contrast to PASSCAL SEG Y). Note that the SU and PASSCAL variants are mutually unintelligible; the trace headers are different, so reading SU as PASSCAL won't work.

# External / Won't Fix
* **Coverage**: rarely, reported code coverage drops to 94-95%, rather than 97-98%. This happens when Travis-CI fails to upload test results to code coverage services, even if tests pass. True coverage has been >97% since at least 2019-06-06.
* **Geophone response translation**: a few permanent North American short-period stations have tremendous (two orders of magnitude) scaling problems with `translate_resp` and `remove_resp`.
  * Test: using `get_data("FDSN", ...)`, check channel ``i`` with ``S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"``.
    + This description may be shorthand for "Geospace Technologies HS-1-LT geophone with Kinemetrics Quanterra Q330 digitizer", but no "HS-1-LT" exists on the [Geospace Technologies product website](https://www.geospace.com/sensors/).
* **SEG Y files with nonstandard trace headers** generally won't read. Only six quantities have mandatory positions in a trace header in SEG Y <= rev 1.0; here, a "nonstandard" trace header means that a file has a "recommended" trace header quantity in an unexpected place (or absent). In order to support the SEG Y format at all, we assume most "recommended" values are present where indicated in the format specification.

# Reporting New Issues
If possible, please include a text dump of a minimum working example (MWE), including error(s) thrown (if any).
