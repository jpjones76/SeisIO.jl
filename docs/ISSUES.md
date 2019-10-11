# Known Issues
* It's not clear that SeedLink works with `mode="FETCH"`. This sometimes appears to close connection immediately without returning data and rigorous tests that assume data returned often lead to timeout errors. The other two SeedLink modes appear to work.
* `FDSNevq` makes no checks for redundant events; using keyword `src="all"` is likely to yield duplicates.
  + It isn't guaranteed that all servers are up at all times; this can also time out and/or throw errors.

## SEG Y
* Files with nonstandard trace headers might not read, or might have incorrect header information.
    * Prior to SEG Y rev 2.0, only six trace header values/positions were mandatory. SeisIO assumes "recommended" positions for fields like `:gain`.

### Unsupported SEG Y Variants
* IBM Float data (note: IBM Float != IEEE Float)
* SEG Y rev 2
* Seismic Unix ("SU"), the "other" trace-only SEGY variant
  + Trying to read SU as PASSCAL won't work; trace headers are incompatible

## SEED
SEED readers only parse blockette types listed in `SeisIO.SEED.mseed_support()` (for mini-SEED with `read_data`) and `SeisIO.SEED.seed_support()` (for dataless
SEED with `read_meta`).

## SUDS
In `SeisIO.SUDS.suds_support()`, check the color coding of the packet number:
* **Green**: these packets should be readable without issue.
* **Yellow**: packets contain metadata outside the scope of SeisIO. Info can be dumped to stdout at high verbosity.
* **Red**: packet type is skipped. These have never been seen in our test data and will be added as people submit test data with them.

# External; Can't Fix
1. Very rarely, reported code coverage appears to be <95%, rather than 97-98%, because Travis-CI fails to upload test results to code coverage services. This happens even though all tests pass.
1. A few permanent North American short-period stations have an instrument response issue that we cannot identify; `translate_resp` and `remove_resp` on these sensors appear ill-behaved.
  * Test: using `get_data("FDSN", ...)`, check channel ``i`` with ``S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"``.
    + This description is shorthand for "Geospace Technologies HS-1-LT geophone with Kinemetrics Quanterra Q330 digitizer"...
    + ...probably. There is no "HS-1-LT" on the Geospace Technologies product website (https://www.geospace.com/sensors/); there's HS-1, HS-1 3C, and OMNI-X-LT.
  * Issue: sensors don't handle response translation well; tremendous (two orders of magnitude) scaling problems are introduced.
    + As of 2019-08-14, we have not tested whether the OMNI-X-LT response curve (i.e., with fc = 15.0 Hz) is a better fit to the data.

# Reporting New Issues
If possible, please include a text dump of a minimum working example (MWE), including error(s) thrown (if any).
