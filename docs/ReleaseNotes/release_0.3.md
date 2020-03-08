# SeisIO v0.3: **Typeageddon!**
2019-06-04

The main purpose of this release is to finalize custom Types; major changes to Types are *extremely* unlikely after this release; minor changes will only happen in response to significant demands. The Type restructuring below serves two main purposes:
1. allow a range of predetermined styles for fields with no universal standard (e.g. location)
2. improve user experience

Descriptions of Type fields and meanings can be found in the help text of each Type.

Low-level descriptions of how each Type is stored on file can be found in the SeisIO documentation.

## Full switch to read_data
Readers for individual file formats (e.g. `readsac`) have been deprecated (as warned about in the notes to SeisIO-0.2.0). Please use `read_data` instead.

## Changes to SeisData, SeisChannel
* An abstract Type, `GphysData`, is now the supertype of `SeisData`. This will allow variants of `SeisData` objects to be added easily.
* For similar reasons, an abstract Type, `GphysChannel`, is now the supertype of `SeisChannel`.
* The `:loc` field now uses custom types designed for one location format each; current options are:
  + `GeoLoc`: geographic instrument position using lat/lon
  + `UTMLoc`: location in UTM coordinates (zone, Northing, Easting)
  + `XYLoc`: location in local (x-y-z) coordinates relative to a georeferenced origin
  + `GenLoc`: generic location
  + It is not necessary for all channels in a SeisData object to use the same location Type.
* The `:resp` field now uses custom types designed for instrument response formats. Current options are:
  + `PZResp`: pole-zero response with Float32 fields `:c` (damping constant), `:p` (complex poles), `:z` (complex zeros).
  + `PZResp64`: pole-zero response with Float64 precision; same field names as `PZResp`.
  + `GenResp`: generic instrument response object comprising a descriptive string, `:desc`, and a complex Float64 matrix, `:resp`.

## Quake submodule
All Types and functions related to handling of discrete earthquake events have been moved to a new submodule, SeisIO.Quake. This includes several (former) SeisIO core functions:
* UW data format: `readuwevt`, `uwpf`, `uwpf!`
* Event web functions: `FDSNevq`, `FDSNevt`, `distaz`, `get_pha!`
* Miscellaneous: `gcdist`, `show_phases`
* Types: `SeisHdr`, `SeisEvent`

### SeisIO.Quake Types
* `SeisSrc` is a new Type that characterizes an earthquake source process, with fields:
  - `:id` (String): seismic source id
  - `:eid` (String): event id
  - `:m0` (Float64): scalar moment
  - `:misc` (Dict{String,Any}): dictionary for non-essential information
  - `:mt` (Array{Float64,1}): moment tensor values
  - `:dm` (Array{Float64,1}): moment tensor errors
  - `:npol` (Int64): number of polarities used in focal mechanism
  - `:pax` (Array{Float64,2}): principal axes
  - `:planes` (Array{Float64,2}): nodal planes
  - `:src` (String): data source
  - `:st` (SourceTime): source-time description with subfields:
    + `:desc` (String): description of source-time function
    + `:dur` (Real): duration
    + `:rise` (Real): rise time
    + `:decay` (Real): decay time
* `SeisHdr` has changed, hopefully for the last time:
  + Fields describing the seismic source process have moved to `SeisSrc`.
  + `:typ` (String) added for event type.
  + `:id` changed Type (Int64 ==> String) to accommodate ISC IDs.
  + `:loc` was expanded; added subfields can now fully characterize location quality, type, and source.
  + `:mag` is now a custom object, rather than Tuple(Float32, String), with fields:
    - `:val` (Float32): magnitude value
    - `:scale` (String): magnitude scale
    - `:nst` (Int64): number of stations used in magnitude calculation
    - `:gap` (Float64): max. azimuthal gap between stations in magnitude calculation
    - `:src` (String): magnitude source (e.g,. software name, authoring agency)
* `SeisEvent` now has three substructures, rather than two:
  + `:data` is now Type `EventTraceData` (<: GphysData), which behaves like SeisData but contains four additional fields for event-specific information:
    + `az`    Azimuth from event
    + `baz`   Backazimuth to event
    + `dist`  Source-receiver distance
    + `pha`   Phase catalog. This is a dictionary of custom objects named `SeisPha`, keyed to phase names (e.g. "pP"), with fields: (Float64 except as  indicated)
      - `amp` amplitude
      - `d`   distance
      - `ia`  incidence angle
      - `pol` polarity (Char)
      - `qual` quality (Char)
      - `rp`  ray parameter
      - `res` residual
      - `ta`  takeoff angle
      - `tt`  travel time
      - `unc` uncertainty
  + `:hdr` (SeisHdr), header information
  + `:source` (SeisSrc), source process characterization

**Note**: Seismic data centers typically use different IDs for event location and event source model; hence, for a SeisHdr object `H` and the corresponding SeisSrc object `R`, `H.id == R.eid`, but generally, `H.id != H.eid`. **Please don't open an issue about this, I swear it's not a bug.**

### QuakeML Support
SeisIO.Quake introduces QuakeML support.
+ A new function, `read_qml`, reads QuakeML files and parses QuakeML downloads.
+ If multiple focal mechanisms, locations, or magnitudes are present in a single `Event` element, the following rules are used to select one of each:
  - `FocalMechanism`
    1. `preferredFocalMechanismID` if present
    2. Solution with best-fitting moment tensor
    3. First `FocalMechanism` element
  - `Magnitude`
    1. `preferredMagnitudeID` if present
    2. Magnitude whose ID matches `MomentTensor/derivedOriginID`
    3. Last moment magnitude (in this context, any magnitude whose lowercase
      scale abbreviation begins with "mw")
    4. First `Magnitude` element
  - `Origin`
    1. `preferredOriginID` if present
    2. `derivedOriginID` from the chosen `MomentTensor` element
    3. First `Origin` element
+ Non-essential QuakeML data are saved to each event `W` in `W.source.misc` (for earthquake source data) or `W.hdr.misc` (other data), using the corresponding QuakeML element names as keys.

### Changes to former SeisIO core functions
* `FDSNevq` now returns both an Array{SeisHdr,1} and a corresponding Array{SeisSrc,1}.
* SeisIO processing functions must now be called on the `:data` field of a `SeisEvent` object. They won't work if called on the `SeisEvent` object itself.

## read/write and SeisIO Types
* `read` and `write` methods now extend to all exported SeisIO Types, including those in SeisIO.Quake. The primary use of `rseis` and `wseis` will be creating indexed, searchable files of many SeisIO objects.
* `SeisChannel` objects are no longer converted to `SeisData` on write.
* The native file format has been rewritten. Please open an issue if you need to access data in the old file format; we don't think anyone was using it yet.
* Write speed has improved 20-30%. Read speed improved two orders of magnitude by removing automatic compression; it's now comparable to SAC or SEG Y with fewer allocations and less overhead.
* On write, the field `:x` of a data object is no longer compressed automatically.
  + Two new keywords, `KW.comp` (UInt8) and `KW.n_zip` (Int64), control compression
    * If `KW.comp == 0x00`, data are not compressed when written.
    * If `KW.comp == 0x01`, only compress `:x` if maximum([length(S.x[i])
    for i = 1:S.n]) ≥ KW.n_zip; by default, `KW.n_zip = 100000`.
    * If `KW.comp == 0x02`, always compress `:x`.
* Switched compressors from `blosclz` to `lz4`. This yields orders-of-magnitude write speed improvements for long sequences of compressed data.

## New Functionality
* `purge!` returns to remove empty and duplicate channels
* `resample!` does what the name suggests. Note that this is both (much) slower and more memory-intensive than a typical decimate operation

## Consistency, Performance, Bug Fixes
* The **+** and **\*** operators on objects of type T<: GphysData now obey
  basic properties of arithmetic:
  - commutativity: `S1 + S2 = S2 + S1`
  - associativity: `(S1 + S2) + S3 = S1 + (S2 + S3)`
  - distributivity: `(S1*S3 + S2*S3) = (S1+S2)*S3`
* `merge!`
  - improved speed and memory efficiency
  - duplicates of channels are now removed
  - duplicates of windows within channels are now removed
  - corrected handling of two (previously breaking) end-member cases:
    + data windows within a channel not in chronological order
    + sequential one-sample time windows in a channel
* `mseis!` now accepts EventTraceData and EventChannel objects
* `get_data`
  + now uses new keyword `KW.prune` to determine whether or not to remove empty
    channels from partially-successful data requests
  + now calls `prune!` instead `merge!` after new downloads
  + no longer throws warnings if removing an empty channel because its data
    were unavailable
* `sort!` has been extended to objects of type T<: GphysData
* FDSN web queries, including `get_data`, now work correctly with the Northern California Seismic Network.
* `sizeof(S)` should now accurately return the total size of (all data and fields) in each custom Type
* `isempty` is now defined for all Types
* fixed incremental subrequests in long `get_data` requests.
* eliminated the possibility of a (never-seen, but theoretically possible) duplicate sample error in multiday `get_data` requests.
* `get_data` no longer treats regional searches and instrument selectors as mutually exclusive.
* SeisIO keyword `nd` (number of days per subrequest) is now type `Real` (was: `Int`).
* shortened SeisIO keyword `xml_file` to `xf` because I'm *that* lazy about typing. y do u ax
* `writesac`:
  - once again stores channel IDs correctly
  - now sets begin time (SAC `b`) from SeisChannel/SeisData `:t`, rather than to 0.0. Channel start and end times using `writesac` should now be identical to `wseis` and `write`.
