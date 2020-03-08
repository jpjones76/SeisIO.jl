SeisIO v0.4.0: Respocalypse Now
2019-09-22

# Instrument Response Improvements
SeisIO can now use full (multi-stage) instrument responses or simplified
(pole-zero) instrument responses.
* Added two new Instrument Response (`:resp`) types: `CoeffResp` and
`MultiStageResp`. These allow full descriptions of multi-stage instrument
responses in FDSN station XML.
  + Full multi-stage instrument responses can be requested by passing keyword
  `msr=true` to appropriate funcitons.

* Instrument response Types `PZResp` and `PZResp64` have changed in two ways:
  + Field `:c` renamed to `:a0` for consistency with FDSN and SEED
  + Field `:f0` added as a container for the frequency at which `:a0` is applied.

## New/Changed
* `fctoresp(f,c)`: generate a new instrument response from lower corner
frequency `f` and damping constant `c`. If no damping constant is specified,
assumes `c = 1/√2`.
* `remove_resp!(S)` remove (flatten to DC) the frequency responses of seismic
channels in a GphysData object.
* `resptofc(R)`: attempt to guess critical frequency `:f0` from poles and zeros
of a PZResp or PZResp64 object.
* `translate_resp!(S, R)`: translate response of seismic data channels
in GphysData object S to response R.
  + `translate_resp` works on channels with `MultiStageResp` responses, with
  two caveats:
    1. Only the *first* stage of the response changes.
    1. The first stage must be a PZResp or PZResp64 object for the response to
    be translated.

### Removed
* `equalize_resp!` (replaced by `translate_resp!`)
* `fctopz` (replaced by `fctoresp`)
* `SeisIO.resp_f` (deprecated)

# Expanded Read Support
With the addition of the readers below, SeisIO read support now covers many
data formats with a handful of simple wrapper functions:

## `read_data, read_data!`
Wrapper for reading entire data files into memory.

| Format                    | String          |
| :---                      | :---            |
| AH-1                      | ah1             |
| AH-2                      | ah2             |
| Bottle                    | bottle          |
| GeoCSV, time-sample pair  | geocsv          |
| GeoCSV, sample list       | geocsv.slist    |
| Lennartz ASCII            | lennartzascii   |
| Mini-SEED                 | mseed           |
| PASSCAL SEG Y             | passcal         |
| PC-SUDS                   | suds            |
| SAC                       | sac             |
| SEG Y (rev 0 or rev 1)    | segy            |
| UW datafile               | uw              |
| Win32                     | win32           |

### Improvements
* `read_data("passcal", ..., swap=true)` reads big-endian PASSCAL SEG Y.
* `read_data` method extended to take either one or two Strings as arguments.
  - If one String is passed to `read_data`, the string is treated as a file pattern; `guess` is called to determine the file format.
  - If two Strings are passed, the first is treated as a file format String; the second is treated as a file pattern string.
    + Note: `read_data` is *much* faster when the file format String is supplied.

## `read_meta, read_meta!`
Wrapper for reading instrument metadata files into memory.

| Format                    | String          |
| :---                      | :---            |
| Dataless SEED             | dataless        |
| FDSN Station XML          | sxml            |
| SACPZ                     | sacpz           |
| SEED RESP                 | resp            |

## `read_hdf5, read_hdf5!`
Extract data from an HDF5 archive that uses a recognized seismic data format.
This works differently from `read_data` in that HDF5 archives are generally
large and contain data from multiple channels; they are scanned selectively
for data in a user-defined time window matching a user-specified ID pattern.

| Format                    | String          |
| :---                      | :---            |
| ASDF                      | asdf            |

## `read_quake`
A wrapper to read discrete event data into a SeisEvent structure. Because
seismic event files are typically self-contained, this does not accept
wildcard file strings and has no "in-place" version.

| Format                    | String          |
| :---                      | :---            |
| QuakeML                   | qml             |
| PC-SUDS event             | suds            |
| UW event                  | uw              |

# Other Changes
## Documentation Improvements
* Public documentation of low-level file formats has been copied into docs/desc.
* CLI information on supported file formats can now be found in `SeisIO.formats`,
a dictionary accessed by format name (as given above).

## Processing on Download
`get_data` can now process requests after download by specifying keywords:
demean, detrend, rr (remove instrument response), taper, ungap, unscale.
  + There are no keywords in `get_data` to filter data or translate seismometer
  responses to a non-flat curve; too many additional keywords would be needed.

## New Functionality
* `?RESP_wont_read` shows some common SEED RESP issues for problem files.
* `convert_seis!` converts seismograms in `S` to other units (m, m/s, m/s²) by differentiation or integration.
* `env!` efficiently computes the signal envelope by segment within each (regularly-sampled) channel.
* `get_file_ver` gets the version of a SeisIO native format file.
* `get_seis_channels(S)` returns numeric indices of channels in `S` whose instrument codes indicate seismic data.
* `guess` guesses data file format and endianness.
* `inst_code(C)` returns the instrument code of GphysChannel object `C`.
* `inst_code(S,i)` returns the instrument code of channel `i`.
* `inst_codes(S)` returns the instrument code of every channel in `S`.
* `resp_a0!(S)` updates the sensitivity `:a0` of PZResp/PZResp64 responses in GphysData object `S`, including PZResp/PZResp64 stages of type MultiStageResp responses. It can also be called on individual InstrumentResponse objects.
* `scan_hdf5` scans supported Seismic HDF5 formats and returns a list of strings describing the waveform contents.
* `set_file_ver` sets the version of a SeisIO native format file.
* `using SeisIO.SUDS; suds_support()` lists current SUDS support.
* `validate_units(S)` validates strings in `:units` to ensure UCUM compliance.
* `vucum(str)` validates UCUM units for `str`.
* `writesacpz(S)` writes instrument responses to SACPZ files.

## Consistency, Performance, Bug Fixes
* Adjusted user agent settings when connecting to FDSN servers in California.
* `get_data` now warns when requesting a (non-miniseed) format from FDSN
dataselect servers that don't implement the `format` keyword.
* Fixed a bug that could cause buffer size to degrade performance with some
file readers after reading long files.
* `FDSN_sta_xml` and functions that call it (e.g. `get_data`) now only spam
"overwrite" warnings at (user-specified verbosity) `v > 0`.
* Meta-data readers and parsers now strictly use `A0` from file, rather than
recalculating it under certain circumstances.
* Rewrote `SL_info`; performance should be greatly improved and it should no
longer cause timeout errors in automated tests.
* Fixed issue #20
* Fixed issue #19
* `tx_float` now always uses Float64 precision; Float32 lacks the resolution
to handle long time series.
* `detrend!` has seen many improvements:
  + now uses linear regression on gapless channels with `:fs > 0.0` && `n=1`,
  yielding a ~12x speedup and >99% less memory use.
  + `detrend!(..., n=N)` now allows degree n=0, equivalent to `demean!`.
  + greatly increased accuracy at single precision.
* Most processing functions now accept a numeric channel list using keyword
`chans=` to restrict processing to certain channels.
  + The only exception to the above is `sync!`; `sync!` with channel restrictions
  makes no sense.
* All functions that accept a numeric channel list as a keyword now call this
keyword `chans`; `chans` can be an Integer, UnitRange, or Array{Int64, 1}.
* Added `resample` as a "safe" (out-of-place) version of `resample!`
* Station XML handling has been rewritten, yielding 97% reduced memory use, 5.1x
speedup, and a workaround for the GeoNet server-side StationXML error (fixes issue #15)
* FDSNEvq now returns full event catalogs by default (fixes issue #16)
* Documentation updated (fixes issue #17)
* `writesac()` with a GphysChannel object now accepts keyword `fname` to set
the file name (issue #18)
  + When specifying `fname=FSTR`, if FSTR doesn't end with (case-insensitive)
  ".sac", the suffix ".sac" is appended to FSTR automatically.
* New PZResp/PZResp64 objects should now always have `:a0 = 1.0, :f0 = 1.0`,
regardless of initialization method.
