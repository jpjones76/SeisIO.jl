const mseed_support_data = "# Mini-SEED Support
SeisIO supports mini-SEED, the \"data-only\" extension of the SEED (Standard for
the Exchange of Earthquake Data) file format.

## Supported Blockette Types

| Blockette                                     | Key in `:misc`  |
|:----------------------------------------------|:----------------|
| [100] Sample Rate Blockette                   |                 |
| [201] Murdock Event Detection Blockette       | seed_event ⁽¹⁾  |
| [300] Step Calibration Blockette              | seed_calib ⁽¹⁾  |
| [310] Sine Calibration Blockette              | seed_calib ⁽¹⁾  |
| [320] Pseudo-random Calibration Blockette     | seed_calib ⁽¹⁾  |
| [390] Generic Calibration Blockette           | seed_calib ⁽¹⁾  |
| [500] Timing Blockette                        | seed_timing     |
| [1000] Data Only SEED Blockette               |                 |
| [1001] Data Extension Blockette               |                 |
| [2000] Variable Length Opaque Data Blockette  | seed_opaque ⁽²⁾ |

Notes on the Table
1. Stored in `:misc` in String arrays; each blockette gets a single String in the named key, separated by a newline character (\\n).
2. Stored in `:misc[\"seed_opaque\"]`, which contains raw (UInt8) byte
vectors of all data in each packet.

## Supported Data Encodings

| Format  | Data Encoding                                               |
|---------|:------------------------------------------------------------|
| 0       | ASCII [Saved to `:misc[\"seed_ascii\"]`, not `:x`]          |
| 1       | Int16 unencoded                                             |
| 3       | Int32 unencoded                                             |
| 4       | Float32 unencoded                                           |
| 5       | Float64 unencoded [Converted to Float32]                    |
| 10      | Steim-1                                                     |
| 11      | Steim-2                                                     |
| 12      | GEOSCOPE multiplexed, 16-bit gain ranged, 3-bit exponent    |
| 15      | GEOSCOPE multiplexed, 16-bit gain ranged, 4-bit exponent    |
| 16      | CDSN, 16-bit gain ranged                                    |
| 30      | SRO                                                         |
| 32      | DWWSSN gain ranged                                          |

### Unsupported Data Encodings
These have never been encountered by SeisIO. If support is needed, please send example files.

| Format  | Data Encoding                                               |
|---------|:------------------------------------------------------------|
| 2       | Int24 unencoded                                             |
| 12      | GEOSCOPE multiplexed, 24-bit integer                        |
| 15      | US National Network                                         |
| 17      | Graefenberg, 16-bit gain ranged                             |
| 18      | IPG - Strasbourg, 16-bit gain ranged                        |
| 19      | Steim-3                                                     |
| 31      | HGLP                                                        |
| 33      | RSTN 16-bit gain ranged                                     |
"

const dataless_support_data = "# Dataless SEED Support
SeisIO supports reading of dataless SEED meta-data files, a popular extension of the SEED (Standard for the Exchange of Earthquake Data) file format.

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

"

const broken_resp_data = "The following is a list of breaking SEED RESP issues that we've encountered in real data. Files with these issues don't read correctly into any known program (e.g., ObsPy, SeisIO, SEED C libraries).

| Network | Station(s)    | Problem(s)
| :----   | :----         | :----
| CN      | (broadbands)  | B058F05-06 contain units; should be B053F05-06
"

"mseed_support() shall info. dump mini-SEED blockette support to stdout."
mseed_support
function mseed_support()
  show(stdout, MIME("text/plain"), Markdown.parse(mseed_support_data))
  return nothing
end


"dataless_support() shall info. dump dataless SEED blockette support to stdout."
function dataless_support()
  show(stdout, MIME("text/plain"), Markdown.parse(dataless_support_data))
  return nothing
end

"seed_support() shall info. dump ALL SEED support info to stdout."
function seed_support()
  show(stdout, MIME("text/plain"), Markdown.parse(mseed_support_data))
  show(stdout, MIME("text/plain"), Markdown.parse(dataless_support_data))
  show(stdout, MIME("text/plain"), Markdown.parse(broken_resp_data))
  return nothing
end

"resp_wont_read() shall info. dump to stdout about broken resp files."
function resp_wont_read()
  show(stdout, MIME("text/plain"), Markdown.parse(broken_resp_data))
  return nothing
end
