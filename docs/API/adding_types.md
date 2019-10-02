Adding Types: an API for new data structures

# 1. Supertypes

## GphysChannel
Any structure that contains univariate data and behaves similarly to SeisChannel
should have this supertype.

## GphysData
Any structure that contains univariate data and behaves similarly to SeisData
should have this supertype. A GphysData subtype should also have a corresponding
single-channel version, equivalent to a SeisChannel.

## InstrumentPosition
Any Type describing an instrument's position should have this supertype.

## InstrumentResponse
Any Type describing an instrument response should have this supertype.

# 2. Mandatory Fields
All SeisData fields *except* `:c` (Connections) are assumed to exist in any
subtype of GphysData; all SeisChannel fields are assumed to exist in any
GphysChannel subtype.

| Name  | Description | Recommendations |
|:---   |:--- | :---- |
| `:id` | String ID | Use format "NETWORK.STATION.LOCATION.CHANNEL" |
| `:name` | Channel name | |
| `:loc` | Instrument position | |
| `:fs` | Sampling frequency in Hz | |
| `:gain` | Scalar gain to convert `:x` to `:units`| |
| `:resp` | Instrument response | |
| `:units` | Units | See units API |
| `:src` | Data source | |
| `:misc` | Non-essential info | |
| `:notes` | Notes and logging | |
| `:t`  | Time | (time API must be followed)
| `:x`  | Univariate data | Allow floating-point data vectors |

Failure to include one or more of these fields may break how your new Type
interacts with SeisIO core code.

# 3. Methods to Extend
The following methods should be imported and extended if you want your new Type
to be usable:

`Base: ==, convert, isempty, isequal, show, size, sizeof, summary`

Strongly recommended:

`Base: hash`

Beware that `hash` can be annoying. It's best to look at the Types in SeisIO
core as examples before trying to extend it.

## Extending `convert`
1. Add `import SeisIO: convert` to your your module imports.
2. Add methods to convert between the new Type and corresponding SeisIO core
Types.
3. Include the mandatory fields above.
4. If fields aren't stored in the target Type, set them to default values.

## Recommended for GphysData Subtypes
`Base: +, append!, deleteat!, getindex, push!, setindex!`

# 4. Extending Native File IO
If you want your new Types to be readable/writable (with `rseis/wseis`), do the
following:
1. Add `import SeisIO: TNames, TCodes, rseis, wseis` to your module imports.
2. Add `import base: read, write` to your module imports.
3. Create low-level read and write functions for your new Types.
4. Add your Types to Tnames.
5. Generate type codes and add to TCodes.
6. Be aware of the strong potential for conflicts in TCodes with other submodules.

# 5. When is This API Mandatory?
Any pull request for SeisIO that adds Types in violation of this guide will be
rejected.
