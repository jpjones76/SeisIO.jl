# Known Issues
If installation fails, and the problem isn't documented, please
[open a new issue](https://github.com/jpjones76/SeisIO.jl/issues/). If possible,
please include a text dump with the error message.

## Oustanding
* It's not clear whether or not SeedLink works with `mode="FETCH"`. This mode
sometimes appears to close connections immediately without returning data and
attempting to switch to more meaningful tests leads to timeout errors.
* `FDSNevq` makes no checks for redundant events; using keyword `src="all"` is
likely to yield duplicates.

## SEG Y Limitations
* IBM Float data encoding (note: IBM Float != IEEE Float) is not supported and
reads incorrectly.
* SEG Y rev 2 read support is not yet implemented.
* There is no reader for SU ("Seismic Unix"), the "other" headerless SEGY
  variant; no reader is planned at this time.
* Files with nonstandard trace headers might not read, or might have incorrect
  header information.
    * Prior to SEG Y rev 2.0, only six trace header values/positions were
    mandatory. SeisIO assumes "recommended" positions to set fields like `:gain`.

## SEED and SUDS Limitations
* The following Blockette and packet types are skipped:
  + Anything *not* listed in `?SeisIO.SEED.mseed_support` or `?SeisIO.SEED.seed_support`.
  + Anything listed in red in `SeisIO.SUDS.suds_support()`

# External to SeisIO
1. Some data channels IDs in SeedLink are not unique, or are duplicates with
different LOC subfields in `:id`, or have a LOC subfield that differs from the
same channel's FDSN info.
  * Separate parameter files for FDSN and SeedLink might be necessary with such
  channels.
  * This might be related to stations transmitting to multiple data centers or
  being jointly operated by multiple seismic networks.
  * Workaround: set a location code in the appropriate SeedLink request string(s).
2. Permanent FDSN stations with Geospace HS-1 geophones have an instrument
response issue.
  * Test: `S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"`.
    + This description is shorthand for "Geospace Technologies HS-1-LT geophone
    with Kinemetrics Quanterra Q330 digitizer"...
    + ...probably. There is no "HS-1-LT" on the Geospace Technologies product
    website (https://www.geospace.com/sensors/); there's HS-1, HS-1 3C, and
    OMNI-X-LT.
  * Issue: sensors don't handle response translation well; tremendous (two
    orders of magnitude) scaling problems are introduced.
  * These geophones might have wrong rolloff frequencies in their XML files.
    All claim fc = 2.0 Hz, but manufacturer data claims fc can vary from 2.0
    to 28 Hz.
    + As of 2019-08-14, we have not tested whether the OMNI-X-LT response
    curve (i.e., with fc = 15.0 Hz) is a better fit to the data.
3. If coverage reported is <95%, rather than ~98%, it's most likely because
Travis-CI broke their uploads to code coverage services.
  * This can happen even when all tests pass on Travis-CI.
  * The lower Code Coverage numbers mean that only Appveyor reports test coverage;
  Appveyor coverage is lower because they can't handle encrypted test files.
