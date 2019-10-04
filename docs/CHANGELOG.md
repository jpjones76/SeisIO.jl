### 2019-10-03
* Added kw `autoname` to `get_data`; see documentation for functionality
and behavior. Implements request in issue #24.
* Discovered/fixed a rare mini-SEED bug wherein the last packet of a request
containing unencoded data could throw a BoundsError when padded with empty bytes.

### 2019-10-02
* The memory footprint of SeisIO has been reduced by moving most large files
to https://github.com/jpjones76/SeisIO-TestData. SeisIO now requires ~3 MB
rather than ~300 MB.
  + The development version is somewhat unwieldy due to the commit history.
  This can be safely pruned with BFG Repo-Cleaner at a max. file size of 50k.

### 2019-10-01
* `read_data("seisio", ...)` now works as a wrapper to `rseis`
  + Note: this is a convenience wrapper and lacks the functionality of `rseis`.
  When reading a SeisIO file that contains multiple objects,
  `read_data("seisio", ...)` reads only the first object in each file that can
  be converted to SeisData.
* Test data now have their own repository. They're downloaded automatically by
  `tests/runtests.jl` when the script is first invoked.

### 2019-09-29
* Functions `SeedLink` and `SeedLink!` have been renamed to lowercase (they're
now `seedlink` and `seedlink!`) because `SeedLink` was too easily mistaken for
a custom Type.
* Added a file reader for SLIST (ASCII sample list): use `read_data("slist", ...)`.

### 2019-09-27
* Fixed `resample` docstrings
* `resample` will no longer throw an error if the desired sampling frequency
equals `:fs` for the largest group of segments
* Fixed imports from `SeisIO.SEED`; SeedLink connections correctly process
buffered data again

### 2019-09-22
* Adjusted user agent settings when connecting to FDSN servers in California.
* `get_data` now warns when requesting a (non-miniseed) format from FDSN
dataselect servers that don't implement the `format` keyword.

### 2019-09-19
### Introducing read_hdf5
* `read_hdf5` is a wrapper to extracting data from HDF5 archives. This works
differently from `read_data` in that we assume HDF5 archives are large and
contain data from multiple channels; they are thus scanned selectively for
data of interest to read, rather than read into memory as a whole file.
  + currently only the ASDF data format is supported, but others will be
  added if various staff respond to our emails.
* `scan_hdf5` scans supported Seismic HDF5 formats and returns a list of
strings describing the waveform contents.

### Introducing read_quake
* `read_quake` is a wrapper to read discrete event data into a SeisEvent
structure.

#### Bugs, Consistency, Performance
* fixed several bugs that could cause buffer size to degrade performance after
reading long files.
* `update_resp_a0!(S)` has been renamed `resp_a0!(S)` and now works on
`MultiStageResp`.

### 2019-09-12
### Introducing read_meta
* `read_meta` is a wrapper for reading instrument metadata files. The syntax
is identical to `read_data` but the keywords differ somewhat. Supported formats
currently include:
  + "dataless": dataless SEED
  + "sacpz": SAC pole-zero file
  + "resp": SEED RESP
  + "sxml": FDSN station XML
* "sacpz", "sxml", and "resp" have moved here from `read_data`
* Incidentally, there is now a dataless SEED reader.

#### Respocalypse 2
* The InstrumentResponse subtypes added 2019-09-03 have changed:
  + Removed fields `:i`, `:o` from `CoeffResp`.
  + Added fields `:i`, `:o` (input and output unit strings, respectively)
  to MultiStageResp; renamed `:factor` to `:fac` and `:offset` to `:os`.
* Added a reader for dataless SEED volumes: `read_data("dataless", ...)`

#### Bugs, Consistency, Performance
* Meta-data readers now strictly use `A0` from file, rather than recalculating
it under certain circumstances.
* Fixed several minor bugs in the initial implementation of `MultiStageResp`
involving non-standardized and missing units.
* Reading a SEED Resp file now sets channel `:fs` in a manner consistent with
SEED "documentation".
* As SEED functionality becomes bloated like SEED itself, I have moved most
internal SEED functions to a submodule.
* The number of zeros read from SACPZ is now consistent with, and adjusted for,
the units.

#### SeisIO file format version increased to 0.53
SeisIO files created with `wseis` between 2019-09-03 and 2019-09-12 use the
original CoeffResp/MultiStageResp definitions. Legacy reader code *should* take
care of the change, but please open a new issue if there are problems.

### 2019-09-07
* Added a reader for SEED RESP: `read_data("resp", ...)`
  + RESP files are poorly standardized. If your RESP files cause errors, please
    check `?RESP_wont_read` before opening new issues.
* Added `read_data` support for station XML with `read_data("sxml", ...)`.
* Note: `guess` can't identify SACPZ files; `read_data` with only one input
  string won't work on them.

### 2019-09-05
* `FDSN_sta_xml` and functions that call it (e.g. `get_data, ``read_sxml`) now
only spam "overwrite" warnings at user-specified verbosity `v` > 0.

### 2019-09-03
* Added two new Instrument Response (`:resp`) types: `CoeffResp` and
`MultiStageResp`. These allow full descriptions of multi-stage instrument
responses in FDSN XML files.
  + Full multi-stage instrument responses can be requested in `get_data` and
  `FDSNsta` by passing keyword `msr=true`.
  + `translate_resp` works on channels with `MultiStageResp` responses, but
  only modifies the *first* listed stage in the response, and only if the first
  stage is of Type `PZResp` or `PZResp64`.
* Added `read_sxml` to read Station XML files; this functionality has existed
since 2016 but was never exported in a way that could parse files with one
command.
* Public documentation on low-level file formats has been copied into docs/desc

### 2019-08-31
* Added read/write support for SACPZ files. Read with e.g.,
`read_data!(S, "sacpz", ...)`; write with e.g., `writesacpz(S)`

### 2019-08-30
* Added function `guess` to guess data file format and endianness.
* `read_data` methods have been extended to take either one or two Strings as
  arguments.
  - If a single String is passed to `read_data`, the string is assumed to be
  a file pattern; `guess` is called to determine the file format.
  - `read_data` is *much* faster when a file format String is supplied. `guess`
  can't be optimized because so many try/catch statements are required.
* Rewrote `SL_info`; performance should be greatly improved and it should no
longer cause timeout errors in automated tests.

### 2019-08-26
* Added readers for the following formats:
  - Ad Hoc (AH) 1.0: `read_data("ah1", ...)`
  - Ad Hoc (AH) 2.0: `read_data("ah2", ...)`
  - UNAVCO Bottle: `read_data("bottle", ...)`
* Added a constant dictionary `"formats"` with information on supported
file formats. Type `formats["list"]` to see a list of options.

#### SeisIO Native File Format
* Incremented SeisIO file format version to 0.51.
  - Legacy support for SeisIO file version 0.50 will assume PZResp, PZResp64
    have field `:c` but not fields `:a0, :f0`.
  - For SeisIO files created *after* the addition of `:a0, :f0` to PZResp and
  PZResp64, set the file version to 0.51 with `set_file_ver(file, 0.51)`.
  - Workaround for issue #21
* Added `get_file_ver` and `set_file_ver` for SeisIO native file format.
* If you have problems reading files recently created with `wseis`, call
  `set_file_ver(file, 0.51)` on each file.

### 2019-08-23
* Fixed issue #20
* Added read support for PC-SUDS data format. Syntax:
  + `read_data("suds", ...)` reads waveform data
  + `SUDS.sudsevt` reads data and possible headers into a SeisEvent
  + `SUDS.suds_support()` lists current SUDS support
  + SeisIO PC-SUDS readers are optimized for multiplexed data (PC-SUDS struct
  code 6); memory overhead for traces (PC-SUDS code 7) is significantly worse.
* Submodules are now in {SeisIO}/src/Submodules/{name}, e.g., SeisIO.Quake is
now in {SeisIO}/src/Submodules/Quake.
* UW file format support has been moved to submodule `UW`.
  + Access individual commands with e.g., `using SeisIO.UW; ?UW.uwpf`.
  + This does not change the syntax `read_data("uw", ...)`

### 2019-08-22
* Fixed issue #19

### 2019-08-19
* `tx_float` now always uses Float64 precision; Float32 lacks the resolution
to handle long time series.
* `detrend!` now uses linear regression on gapless channels with `:fs > 0.0`
when `n=1`, yielding a 12x speedup and >99% less memory use.
* added `env!` to efficiently compute the signal envelope by segment within
each (regularly-sampled) channel.

### 2019-08-14
* `read_data("passcal", ..., swap=true)` now reads big-endian PASSCAL SEG Y.

### 2019-08-13
#### New, Changed, Deprecated
* Added `vucum(str)` and `validate_units(S)` to validate strings for `:units`.

### Bugs, Consistency, Performance
* `detrend!`
  + `detrend!(..., n=N)` now allows degree n=0, equivalent to `demean!`.
  + slightly reduced memory consumption.
  + greatly increased accuracy at single precision.
* `get_data`
  + now correctly defaults to `unscale=false` and `ungap=false`.
* `convert_seis!` converts seismograms in `S` to other units (m, m/s, m/s²) by
differentiation or integration.

### 2019-08-05
#### New, Changed, Deprecated
* Most processing functions now accept a numeric channel list using keyword
`chans=` to restrict processing to certain channels. Affects:
  + demean!, demean
  + detrend!, detrend
  + filtfilt!, filtfilt
  + resample!
  + taper!, taper
  + unscale!, unscale
* The only current exceptions to the above are `nanfill!` and `sync!`, as we
cannot imagine use cases where channel restriction is useful.
* New utility functions efficiently retrieve instrument codes:
  + `inst_codes(S)` returns the instrument code of every channel in `S`.
  + `inst_code(S,i)` returns the instrument code of channel `i`.
  + `inst_code(C)` returns the instrument code of GphysChannel object `C`.
* `get_seis_channels(S)` returns numeric indices of channels in `S` whose
instrument codes indicate seismic data.
* `get_data` can now process requests after download by specifying keywords:
demean, detrend, rr (remove instrument response), taper, ungap, unscale.
  + There is not (and may never be) options in `get_data` to filter data
  or translate seismometer responses to a non-flat curve; too many additional
  keywords.

#### Bugs, Consistency, Performance
* Functions that accept a numeric channel list as a keyword now use keyword
`chans` for this; `chans` can be an Integer, UnitRange, or Array{Int64, 1}.
Affects:
  + remove_resp
  + translate_resp
* Added `resample` as a "safe" (out-of-place) version of `resample!`

### 2019-08-01
#### Respocalypse Part I
* Instrument response Types Resp and Resp64 have changed in two minor ways:
  + Field `:c` renamed to `:a0` for consistency with FDSN and SEED
  + Field `:f0` added for the frequency at which `:a0` is applied
#### New, Changed, Deprecated
* `fctoresp`: generate a new instrument response from lower corner frequency `f`
and damping constant `c`. If no damping constant is specified, assumes c = 1/sqrt(2).
* `remove_resp!` remove (flatten to DC) the frequency responses of seismic
channels in a SeisData object.
  + Currently only known to work for velocity sensors; accelerometers and
    displacement sensors are NYI
* `resptofc`: guess damping constant of geophone from poles and zeros of a
  PZResp or PZResp64 object.
* `translate_resp!`: translate response of seismic data channels in a SeisData
  object.
  + Currently working for velocity sensors, maybe accelerometers; displacement
    NYI
  + Uses around 1% of the memory of the old `equalize_resp!` function
* Removed `equalize_resp!`
* Removed `fctopz`
* Removed `SeisIO.resp_f`
#### Bugs, Consistency, Performance
* Normalization frequency is now saved to `S.resp[i].f0` instead of `S.misc[i]["normfreq"]`.
* **Warning**: Code coverage may drop below 97% for a few days.
* **Warning**: Official documentation for instrument response functions will
be outdated until next week; the help text for individual functions is correct.

### 2019-07-16
#### Bugs, Consistency, Performance
* Station XML handling has been rewritten, yielding 97% reduced memory use, 5.1x
speedup, and a workaround for the GeoNet server-side StationXML error (issue #15)
* FDSNEvq now returns full event catalogs by default (issue #16)
* Documentation updated (fixes issue #17)
* `writesac()` with a GphysChannel object now accepts keyword `fname` to set
the file name (issue #18)
  + When specifying `fname=FSTR`, if FSTR doesn't end with (case-insensitive)
  ".sac", the suffix ".sac" is appended to FSTR automatically.
* New PZResp and PZResp64 objects should now always have :c = 1.0, regardless of
initialization method

# SeisIO v0.3.0 Release: 2019-06-05

### 2019-06-04
#### Bugs, Consistency, Performance
* writesac with SeisEvent objects works again
* merge! has been extended to EventTraceData
* removed hash(::SeisSrc)
* purge, the "safe" version of purge!, is now exported

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
