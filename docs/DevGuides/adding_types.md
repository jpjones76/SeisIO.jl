Adding new data structures

# 0. When is This Guide Mandatory?
Any pull request for SeisIO that adds Types

# 1. Supertypes

## GphysChannel
Any structure that contains univariate data and behaves similarly to SeisChannel should have this supertype.

## GphysData
Any structure that contains univariate data and behaves similarly to SeisData should have this supertype. A GphysData subtype should also have a corresponding single-channel version, equivalent to a SeisChannel.

## InstrumentPosition
Any Type describing an instrument's position should have this supertype.

## InstrumentResponse
Any Type describing an instrument response should have this supertype.

# 2. Mandatory Fields
All SeisData fields *except* `:c` (Connections) are assumed to exist in any subtype of GphysData; all SeisChannel fields are assumed to exist in any GphysChannel subtype.

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

Failure to include one or more of these fields will break how your new Type interacts with SeisIO core code.

# 3. Required Method Extensions
For general Types, the following methods must be imported and extended:

```
import Base: ==, isempty, isequal, show, sizeof, summary
```

## 3a. GphysData subtypes
Methods needed:
```
import Base: +, *, ==, append!, convert, deleteat!, getindex,
isempty, isequal, merge!, push!, setindex!, show, size, sizeof,
sort!, summary
import SeisIO: merge_ext!
```

### Required behavior
* Let `C` be a single-channel object of type `T <: GphysChannel`.
* Let `S` be a multichannel object of type `Y <: GphysData`, analogous to a multichannel version of `C`.

The following are required and should be demonstrated in your tests:
* `sort!` uses the `:id` field
* `append!` attaches an object of type Y <: GphysData to `S`
* `push!` attaches `C` to `S` and thereby extends each Array field in S by 1
* `convert`
  - Converts `C` to and from Type SeisChannel.
  - Converts `S` to and from Type SeisData.
  - Include the mandatory fields above.
  - If fields aren't stored in the target Type, set them to default values.
  - Not all fields are preserved by conversion. In general, `convert(Y, convert(SeisData, S)) != S`.
    - Changing this to `==` would require storing your new fields in `:misc`; but relying on keys in `:misc` is non-robust and potentially very slow.
* `isempty` should always return `true` for a newly initialized structure with no keywords passed during initialization.
  - For numeric fields, I recommend initializing to 0 or 1 (as appropriate) and testing against the default value in your `isempty` method extension.
  - Strings and Arrays are best initialized empty.
  - This does imply that the "default" values of keyword init. must be the same values that `isempty` considers "empty".
* If `hash` is extended to a parameteric type, it must return the same value for two empty structures of the same Type.

#### Note on `hash`
With apologies, `hash` is unpredictable in Julia. Check the `hash` function documentation and experiment until the above test succeeds. This may take far more time than this paragraph suggests; our apologies.

`hash` must be extended to new subtypes of InstrumentPosition and InstrumentResponse.

An earlier version of this guide erroneously states that `hash` must be extended to all new types.

# 4. Recommendations

## a. Suggested Workflows

### New Subtype
1. Define initialization methods
1. Extend `show`, `summary` (if different from supertype)
1. Extend `isempty`, `isequal`, `sizeof`
1. Extend `read`, `write`

### GphysData Subtype
Starting with the SeisData Type as a skeleton:
1. Define new fields
  * Follow "New Subtype" workflow if adding new subtypes of InstrumentPosition and/or InstrumentResponse
1. Follow "New Subtype" workflow
1. Extend `convert!` to/from SeisData
1. Create a single-channel version, like SeisChannel
  + Follow "New Subtype" workflow
  + Extend `convert!` to/from SeisChannel
1. Indexing: extend each of `append!`, `deleteat!`, `getindex`, `push!`, `setindex!`, `sort!`
1. Define `merge_ext!` for the new subtype, to merge any fields not in a SeisData object
1. Add tests

## b. Native File IO
If you want your new Types to be readable/writable with `rseis/wseis`, then you must do the following:
1. Add to the relevant module:
  + `import SeisIO: TNames, TCodes, rseis, wseis`
  + `import Base: read, write`
1. Create low-level `read` and `write` functions for your new Types.
1. Add your Types to Tnames.
1. Generate type codes and add to TCodes.
1. Be aware of the potential for conflict in TCodes with other submodules.
