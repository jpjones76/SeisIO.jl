# Known Issues
If installation fails, and the problem isn't documented, please [open a new issue](https://github.com/jpjones76/SeisIO.jl/issues/). If possible, please
include a text dump with the error message.

## Oustanding
* It's not clear whether or not `SeedLink!` works with `mode="FETCH"`. This mode
sometimes appears to close connections immediately without returning data.
* `FDSNevq` makes no checks for redundant events; using keyword `src="all"` is
likely to yield duplicates.

## Unsupported or Incomplete
* SEG Y
  + IBM Float data encoding (note: IBM Float != IEEE Float)
  + SEG Y rev 2
* SUDS
  + We cannot support additional header types unless example files containing
those types are provided, along with expected values for tests. Due to the
*many* errors in this format's documentation, there is no more reliable way to
determine whether or not our readers are coded correctly.

## External to SeisIO
1. Some data channels IDs in SeedLink are not unique, or are duplicates with
different LOC fields in `:id`.
  * This appears to happen with stations that transmit to multiple data
  centers. The probable cause is that some stations are jointly operated by
  multiple networks.
  * Workaround: set a location code in the appropriate request string(s).
2. Permanent FDSN stations with Geospace HS-1 geophones have instrument response
issues.
  * Test: `S.misc[i]["SensorDescription"] == "HS-1-LT/Quanterra 330 Linear Phase Composite"`.
    + This description is shorthand for "Geospace Technologies HS-1-LT geophone
    with Kinemetrics Quanterra Q330 digitizer"...
    + ...probably. There is no "HS-1-LT" on the Geospace Technologies product
    website (https://www.geospace.com/sensors/); there's HS-1, HS-1 3C, and
    OMNI-X-LT.
  * These sensors don't handle response translation well; tremendous (two
    orders of magnitude) scaling problems are introduced.    
  * These geophones might have wrong rolloff frequencies in their XML files.
    All claim fc = 2.0 Hz, but manufacturer data claims fc can vary from 2.0
    to 28 Hz.
    + As of 2019-08-14, we have not tested whether the OMNI-X-LT response
    curve (i.e., with fc = 15.0 Hz) is a better fit to the data.
3. SEG Y files with header variables in places that don't match the SEG standard
will not read. This is not a bug with SeisIO; this is a problem with industry
storing headers in nonstandard locations as a crude means of data protection.
