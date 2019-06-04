### 2019-06-01
#### Full switch to read_data
Readers for individual file formats (e.g. `readsac`) have been removed, with
a few exceptions (as warned about in the notes for SeisIO-0.2.0). Please use
`read_data` instead.

#### Quake submodule
Types and functions dealing with discrete earthquake events have moved to a new
submodule, SeisIO.Quake. This includes several (former) SeisIO core functions
and Types.
* UW data format: `readuwevt`, `uwpf`, `uwpf!`
* Event web functions: `FDSNevq`, `FDSNevt`, `distaz`, `get_pha!`
* Miscellaneous: `gcdist`, `show_phases`
* Types: `SeisHdr`, `SeisEvent`

#### SeisIO.Quake Types
* `SeisHdr` field changes:
  + `:axes`, `:mt` have moved to a different structure, `SeisSrc`.
  + `:typ` (String) added for event type.
  + `:id` has changed Type (Int64 ==> String) to accommodate ISC IDs.
  + `:loc` was expanded; added subfields can now fully characterize location
    quality, type, and source.
  + `:mag` is now a custom object, rather than Tuple(Float32, String), with fields:
    - `:val` (Float32): magnitude value
    - `:scale` (String): magnitude scale
    - `:nst` (Int64): number of stations used in magnitude calculation
    - `:gap` (Float64): max. azimuthal gap between stations in magnitude calculation
    - `:src` (String): magnitude source (e.g,. software name, authoring agency)
* `SeisSrc` is a new Type that characterizes the earthquake source process, with fields:
  - `:id` (String): seismic source id
  - `:eid` (String): event id
  - `:m0` (Float64): scalar moment
  - `:misc` (Dict{String,Any}): dictionary for non-essential information
  - `:mt` (Array{Float64,1}): moment tensor values
  - `:dm` (Array{Float64,1}): moment tensor errors
  - `:npol` (Int64): number of polarities used for computing focal mechanism
  - `:pax` (Array{Float64,2}): Principal axes
  - `:planes` (Array{Float64,2}): nodal planes
  - `:src` (String): data source
  - `:st` (SourceTime): source-time description with subfields:
    + `:desc` (String): description of source-time function
    + `:dur` (Real): duration
    + `:rise` (Real): rise time
    + `:decay` (Real): decay time
* `SeisEvent` now has three substructures, rather than two. The major change
here is because source process descriptions are too complicated to easily
characterize in a `hdr` subfield.
  + `hdr` (SeisHdr), header information
  + `data` (SeisData), trace data
  + `source` (SeisSrc), source process characterization
* `FDSNevq`
  + Now returns both an Array{SeisHdr,1} and a corresponding Array{SeisSrc,1}.


**Notes**
1. Redundancy in `SeisSrc` fields is for QuakeML compatibility.
2. The structure of `SeisSrc` should be treated as semi-final but not final.
3. Seismic data centers typically use different IDs for an event and its source
characterization. SeisSrc objects contain an `:eid` field for Event ID and an
`:id` field for moment tensor or focal mechanism ID. So, given a SeisHdr object
`H` and corresponding SeisSrc object `R`, `H.id == R.eid` but `H.id != H.eid`.
**Please don't open an issue about this.**

##### QuakeML Support
  + A new function, `read_qml`, reads QuakeML files and parses QuakeML downloads.
  + If multiple focal mechanisms, locations, or magnitudes are present in a
  single `Event` element, the following rules are used to select one of each:
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
  + Non-essential QuakeML data are saved to each event `W` in
  `W.source.misc` (for earthquake source data) or `W.hdr.misc` (other data),
  using the corresponding QuakeML element names as keys.

#### Read/Write changes
* `read` and `write` methods now extend to all exported SeisIO Types, including
  those in SeisIO.Quake. The primary use of `rseis` and `wseis` will be creating
  indexed, searchable files of SeisIO objects.
* `SeisChannel` objects are no longer convered to `SeisData` on write.
* The native file format has been rewritten. Notable changes that affect users:
* Please open an issue if you need to access data in the old file format.
* Write speed has improved 20-30%. Read speed improved two orders of magnitude
  by removing automatic compression; SeisIO native files now generally read
  slightly faster than SAC or SEG Y with fewer allocations and less overhead.
* On write, the field `:x` of data objects is no longer compressed automatically.
  + Two new keywords, `KW.comp` (UInt8) and `KW.n_zip` (Int64), control compression
    * If `KW.comp == 0x00`, data are not compressed when written.
    * If `KW.comp == 0x01`, only compress `:x` if maximum([length(S.x[i])
    for i = 1:S.n]) ≥ KW.n_zip; by default, `KW.n_zip = 100000`.
    * If `KW.comp == 0x02`, always compress `:x`.
* Switched compressors from `blosclz` to `lz4`. This yields orders-of-magnitude
  write speed improvements for long sequences of compressed data.

### 2019-05-15
Consistency and Performance Improvements
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
* `purge!` added as a new function to remove empty and duplicate channels
* `mseis!` now accepts EventTraceData and EventChannel objects
* `get_data`
  + now uses new keyword `KW.prune` to determine whether or not to remove empty
    channels from partially-successful data requests
  + now calls `prune!` instead `merge!` after new downloads
  + no longer throws warnings if removing an empty channel because its data
    were unavailable
* `sort!` has been extended to objects of type T<: GphysData

### 2019-05-10
**Typeageddon!** A number of changes have been made to SeisData object
architectures, with two goals: (1) allow several standardized formats for fields
with no universal convention; (2) improve the user experience.
* An abstract Type, GphysData, is now the supertype of SeisData
* An abstract Type, GphysChannel, is now the supertype of SeisChannel
* In SeisEvent objects, `:data` is a new Type, EventTraceData (<: GphysData),
  with additional fields for event-specific information:
  + `az`    Azimuth from event
  + `baz`   Backazimuth to event
  + `dist`  Source-receiver distance
  + `pha`   Phase catalog, a dictionary of SeisPha objects, which have fields
      - `d`   Distance
      - `tt`  Travel Time
      - `rp`  Ray Parameter
      - `ta`  Takeoff Angle
      - `ia`  Incidence Angle
      - `pol` Polarity
* In SeisData objects:
  + `:loc` now contains an abstract type, InstrumentPosition, whose subtypes
    standardize location formats. A typical SeisData object uses type GeoLoc
    locations, with fields
    - `datum`
    - `lat` Latitude
    - `lon` Longitude
    - `el`  Instrument elevation
    - `dep` Instrument depth (sometimes tracked independently of elevation, for reasons)
    - `az`  Azimuth, clocwise from North
    - `inc` Incidence, measured downward from verticla
  + `:resp` is now an abstract type, InstrumentResponse, whose subtypes
    standardize response formats. A typical SeisData object has type PZResp
    responses with fields
    - `c` Damping constant
    - `p` Complex poles
    - `z` Complex zeros
* SeisHdr changes:
  + ~~The redundant fields `:pax` and `:np` have been consolidated into `:axes`,
    which holds 3-Tuples of Float64s.~~
  + ~~The moment tensor field `:mt` is no longer filled in a new SeisHdr.~~
  + The SeisHdr `:loc` field is now a substructure with fields for `datum`,
    `lat`, `lon`, and `dep`.
* Bugs/Consistency
  + `sizeof(S)` now better gauges the true sizes of custom objects.
  + `isempty` is now well-defined for SeisChannel and SeisHdr objects.
  + Fixed incremental subrequest behavior for long `get_data` requests.
  + Eliminated the possibility of a (very rare, but previously possible)
    duplicate sample error in long `get_data` requests.
  + `get_data` no longer treats regional searches and instrument selectors
    as mutually exclusive.
  + keyword `nd` (number of days / subrequest) is now type `Real` (was: `Int`).
  + shortened keyword `xml_file` to `xf` because I'm *that* lazy about typing.
  + `writesac` stores channel IDs correctly again.
  + `writesac` now sets begin time (SAC `b`) from SeisChannel/SeisData `:t`,
    rather than truncating to 0.0; thus, channel times of data saved to SAC
    should now be identical to channel times of data saved to SeisIO format.

# SeisIO v0.2.0 Release: 2019-05-04
