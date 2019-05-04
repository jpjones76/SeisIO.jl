export seed_support, mseed_support

@doc """
# SEED Support
SeisIO supports mini-SEED, the "data-only" extension of the SEED (Standard for
the Exchange of Earthquake Data) file format.

## Supported Blockette Types

| Blockette                                     | Key in `:misc`  |
|:----------------------------------------------|:----------------|
| [100] Sample Rate Blockette                   |                 |
| [201] Murdock Event Detection Blockette       | seed_event      |
| [300] Step Calibration Blockette              | seed_calib      |
| [310] Sine Calibration Blockette              | seed_calib      |
| [320] Pseudo-random Calibration Blockette     | seed_calib      |
| [390] Generic Calibration Blockette           | seed_calib      |
| [500] Timing Blockette                        | seed_timing     |
| [1000] Data Only SEED Blockette               |                 |
| [1001] Data Extension Blockette               |                 |
| [2000] Variable Length Opaque Data Blockette  | seed_opaque*    |

Information unrelated to data or timing is stored in `:misc` as String arrays;
each blockette gets a single String in the named key, separated by a newline
character (\\n).

## Supported Data Encodings

| Format  | Data Encoding                                               |
|---------|:------------------------------------------------------------|
| 0       | ASCII text [^a]                                             |
| 1       | Int16 unencoded                                             |
| 3       | Int32 unencoded                                             |
| 4       | Float32 unencoded                                           |
| 5       | Float64 unencoded [^b]                                      |
| 10      | Steim-1                                                     |
| 11      | Steim-2                                                     |
| 12      | GEOSCOPE multiplexed, 16-bit gain ranged, 3-bit exponent    |
| 15      | GEOSCOPE multiplexed, 16-bit gain ranged, 4-bit exponent    |
| 16      | CDSN, 16-bit gain ranged                                    |
| 30      | SRO                                                         |
| 32      | DWWSSN gain ranged                                          |

[^a]: Saved to C.misc["seed_ascii"]; generally not used for data
[^b]: Converted to Float32
""" seed_support
function seed_support()
    return nothing
end

@doc (@doc seed_support)
mseed_support() = seed_support()

#
# ### Unsupported Data Encodings
# These have never been encountered by SeisIO and may not exist in real seismic
# data.
#
# | Format  | Data Encoding                                               |
# |---------|:------------------------------------------------------------|
# | 2       | Int24 unencoded                                             |
# | 12      | GEOSCOPE multiplexed, 24-bit integer                        |
# | 15      | US National Network                                         |
# | 17      | Graefenberg, 16-bit gain ranged                             |
# | 18      | IPG - Strasbourg, 16-bit gain ranged                        |
# | 19      | Steim-3                                                     |
# | 31      | HGLP                                                        |
# | 33      | RSTN 16-bit gain ranged                                     |
