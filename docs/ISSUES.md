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

# External / Won't Fix
* **Coverage**: rarely, reported code coverage drops to 94-95%, rather than 97-98%. This happens when Travis-CI fails to upload test results to code coverage services, even if tests pass. True coverage has been >97% since at least 2019-06-06.
* **Geophone response translation**: a few permanent North American short-period stations have tremendous (two orders of magnitude) scaling problems with `translate_resp` and `remove_resp`.
  * Test: using `get_data("FDSN", ...)`, check channel ``i`` with ``S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"``.
    + This description may be shorthand for "Geospace Technologies HS-1-LT geophone with Kinemetrics Quanterra Q330 digitizer", but no "HS-1-LT" exists on the [Geospace Technologies product website](https://www.geospace.com/sensors/).
* **SEG Y rare variants**: not supported.
  + Files with nonstandard trace headers.
    - Through SEG Y rev 1.0, only six trace header values/positions were mandatory. SeisIO assumes "recommended" positions for fields like `:gain`.
  + IBM Float is not supported on principle. IEEE Float has been the standard floating-point data format since *1985*. SEG Y is one of four extant binary data formats *in the entire world* with IBM Float.
  + SEG Y rev 2 is not supported. This may be added if demand arises; please ask if you need it.
  + Seismic Unix ("SU"), the "other" trace-only SEGY variant, is unsupported. We have never encountered this variant in the wild and only learned of its existence when looking for a PASSCAL reader in ObsPy. Again, please ask if you need it.
    - Trying to read SU as PASSCAL won't work; trace headers are incompatible.
* **IRIS XML validator**: may issue up to two warnings per channel for files produced with `write_sxml`: "No decimation found" and "Decimation cannot be null". Our files are fully compliant with FDSN station XML 1.1. These warnings are inconsistent and may be erroneous.
  + SeisIO creates no `Decimation` nodes for `PolesZeros` response stages. No data center does, either (including IRIS). In both cases, when channel `i` of structure `S` satisfies the condition `typeof(S.resp[i]) == MultiStageResp`, and subconditions `length(S.resp[i].stage) == 1` and `typeof(S.resp[i].stage[1]) in (PZResp, PZResp64)`, the channel response lacks a Decimation node and warnings are thrown by the validator.
    - See stationxml-validator issue [78](https://github.com/iris-edu/stationxml-validator/issues/78).

# Reporting New Issues
If possible, please include a text dump of a minimum working example (MWE), including error(s) thrown (if any).
