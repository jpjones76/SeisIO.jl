# Known Issues
1. Source tracking (`:src` and copying to `:notes` on overwrite) is unreliable
at present. Standardizing this is a priority for v0.5.0.
1. `FDSNevq` makes no checks for redundant events; using `src="all"` can yield
duplicates or lead to connection timeouts.
1. SEED support doesn't include all possible blockette types. Blockettes that
aren't in the scope of SeisIO are skipped.
  + `read_data("mseed", ...)` only parses blockette types listed in `SeisIO.SEED.mseed_support()`.
  + `read_meta("dataless", ...)` only parses blockette types listed in `SeisIO.SEED.seed_support()`.
  + If expanded SEED blockette support is needed, send us test data with
  examples of the requested blockettes.
1. SUDS support doesn't include all possible structures. The color coding of the
structure number in the output of `SeisIO.SUDS.suds_support()` gives the status:
  + **Green** structures should be readable without issue.
  + **Yellow** structures contain metadata outside the scope of SeisIO. Info can
  be dumped to stdout at high verbosity but isn't read into memory.
  + **Red** structures are skipped; these have never been seen in our test data.
  + If expanded SUDS support is needed, send us test data with examples of the
  requested structures.

# Suspected External
1. The IRIS XML validator issues warnings for files produced with `write_sxml`.
Written station XML files read correctly into other programs and conform to
[FDSN schema](https://www.fdsn.org/xml/station/fdsn-station-1.1.xsd). We
suspect that these warnings are erroneous; see stationxml-validator issues
[78](https://github.com/iris-edu/stationxml-validator/issues/78) \&
[79](https://github.com/iris-edu/stationxml-validator/issues/79).

# External / Won't Fix
1. Very rarely, reported code coverage appears to be <95%, rather than 97-98%,
because Travis-CI fails to upload test results to code coverage services. This
happens even though all tests pass.
1. A few permanent North American short-period stations don't handle response
translation well; tremendous (two orders of magnitude) scaling problems are introduced with `translate_resp` and `remove_resp` on these channels.
  * Test: using `get_data("FDSN", ...)`, check channel ``i`` with
  ``S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"``.
    + This description is shorthand for "Geospace Technologies HS-1-LT geophone
    with Kinemetrics Quanterra Q330 digitizer"...
    + ..."we think". There is no "HS-1-LT" on the Geospace Technologies product
    website (https://www.geospace.com/sensors/); there's HS-1, HS-1 3C, and
    OMNI-X-LT.
1. Some uncommon SEG Y variants aren't supported:
  + Files with nonstandard trace headers don't read correctly.
    - Through SEG Y rev 1.0, only six trace header values/positions were
    mandatory. SeisIO assumes "recommended" positions for fields like `:gain`.
  + IBM Float is not supported on principle. IEEE Float has been the standard
    floating-point number format since 1985. SEG Y is one of four extant binary
    data formats *in the entire world* that still uses IBM Float.
  + SEG Y rev 2 is not supported. This may be added if demand arises.
  + Seismic Unix ("SU"), the "other" trace-only SEGY variant, is unsupported.
    We have never encountered this variant in the wild and only learned of its
    existence when looking for a PASSCAL reader in ObsPy.
    - Trying to read SU as PASSCAL won't work; trace headers are incompatible.

# Reporting New Issues
If possible, please include a text dump of a minimum working example (MWE),
including error(s) thrown (if any).
