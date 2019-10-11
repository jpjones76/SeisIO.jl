@doc """
# Mini-SEED Support
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
| [2000] Variable Length Opaque Data Blockette  | seed_opaque     |

Information unrelated to data or timing is stored in `:misc` as String arrays;
each blockette gets a single String in the named key, separated by a newline
character (\\n). `:misc["seed_opaque"]`, if present, contains raw (UInt8) byte
vectors of all data in each packet.

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

[^a]: Saved to `C.misc["seed_ascii"]`; generally not used for data
[^b]: Converted to Float32
""" mseed_support
function mseed_support()
  println("\nCurrently supported mini-SEED blockette types:\n")
  printstyled(@sprintf("%10s|%40s|%18s\n", "BLOCKETTE", " ", "KEY IN :MISC"), color=:green, bold=true)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[100]", "Sample Rate", " "), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[201]", "Murdock Event Detection", "seed_event"), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[300]", "Step Calibration", "seed_calib"), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[310]", "Sine Calibration", "seed_calib"), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[320]", "Pseudo-random Calibration", "seed_calib"), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[390]", "Generic Calibration", "seed_calib"), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[500]", "Timing", "seed_timing"), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[1000]", "Data Only SEED", " "), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[1001]", "Data Extension", " "), color=:green)
  printstyled(@sprintf("%10s|%40s|%18s\n", "[2000]", "Variable Length Opaque Data","seed_opaque*"), color=:green)

  return nothing
end


@doc """
# Dataless SEED Support
SeisIO supports reading of dataless SEED meta-data files.

Reading full SEED volumes is NYI.

## Supported Blockette Types

| Blockette                                             |
|:------------------------------------------------------|
| [10] Volume Identifier Blockette                      |
| [11] Volume Station Header Index Blockette            |
| [12] Volume Time Span Index Blockette                 |
| [31] Comment Description Blockette                    |
| [33] Generic Abbreviation Blockette                   |
| [34] Units Abbreviations Blockette                    |
| [41] FIR Dictionary Blockette                         |
| [43] Response (Poles & Zeros) Dictionary Blockette    |
| [44] Response (Coefficients) Dictionary Blockette     |
| [45] Response List Dictionary Blockette               |
| [47] Decimation Dictionary Blockette                  |
| [48] Channel Sensitivity/Gain Dictionary Blockette    |
| [50] Station Identifier Blockette                     |
| [52] Channel Identifier Blockette                     |
| [53] Response (Poles & Zeros) Blockette               |
| [54] Response (Coefficients) Blockette                |
| [57] Decimation Blockette                             |
| [58] Channel Sensitivity/Gain Blockette               |
| [59] Channel Comment Blockette                        |
| [60] Response Reference Blockette                     |
| [61] FIR Response Blockette                           |

## Unsupportable Blockette Types
These blockettes will probably never be supported as
their information lies outside the scope of SeisIO. At
high verbosity (v > 2), their information is dumped to
stdout.

| Blockette                                             |
|:------------------------------------------------------|
| [30] Data Format Dictionary Blockette                 |
| [32] Cited Source Dictionary Blockette                |
| [51] Station Comment Blockette                        |

"""
seed_support
function seed_support()
  println("\nCurrently supported dataless SEED blockette types:\n")
  printstyled("[10] Volume Identifier Blockette\n", color=:green)
  printstyled("[11] Volume Station Header Index Blockette\n", color=:green)
  printstyled("[12] Volume Time Span Index Blockette\n", color=:green)
  printstyled("[31] Comment Description Blockette\n", color=:green)
  printstyled("[33] Generic Abbreviation Blockette\n", color=:green)
  printstyled("[34] Units Abbreviations Blockette\n", color=:green)
  printstyled("[41] FIR Dictionary Blockette\n", color=:green)
  printstyled("[43] Response (Poles & Zeros) Dictionary Blockette\n", color=:green)
  printstyled("[44] Response (Coefficients) Dictionary Blockette\n", color=:green)
  printstyled("[45] Response List Dictionary Blockette\n", color=:green)
  printstyled("[47] Decimation Dictionary Blockette\n", color=:green)
  printstyled("[48] Channel Sensitivity/Gain Dictionary Blockette\n", color=:green)
  printstyled("[50] Station Identifier Blockette\n", color=:green)
  printstyled("[52] Channel Identifier Blockette\n", color=:green)
  printstyled("[53] Response (Poles & Zeros) Blockette\n", color=:green)
  printstyled("[54] Response (Coefficients) Blockette\n", color=:green)
  printstyled("[57] Decimation Blockette\n", color=:green)
  printstyled("[58] Channel Sensitivity/Gain Blockette\n", color=:green)
  printstyled("[59] Channel Comment Blockette\n", color=:green)
  printstyled("[60] Response Reference Blockette\n", color=:green)
  printstyled("[61] FIR Response Blockette\n", color=:green)
end

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
