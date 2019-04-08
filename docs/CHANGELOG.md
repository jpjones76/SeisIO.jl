### 2019-03-22
* `get_data / get_data!` can now handle long requests and coordinate searches with FDSN.
  + Long requests are broken into subrequests of length `nd` days. Change
  the length of each subrequest with keyword `nd=` (default: `nd=1`).
  + Search in a rectangular region with keyword `reg`. Coordinates should be
  an Array{Float64,1} in decimal degrees, arranged [min_lat, max_lat, min_lon, max_lon].
  Treat North and East as positive.
  + Search in a radius around a central point with keyword `rad`. Coordinates
  should be an Array{Float64,1} arranged [center_lat, center_lon, r_min, r_max].
  Use decimal degrees for the center and treat North and East as positive.
  Specify radii in km.
  + Station XML for all FDSN `get_data` requests is now written to file by
  default. The default file created is "FDSNsta.xml". Change this with keyword
  `xml_file=`.
* Arrrays in the "data" field of a SeisData object (`:x`) can now be either
  Array{Float64,1} or Array{Float32,1}.
* `readsac`, `readsegy`, `readuw`, and `readwin32` now read into single-
  precision channels, consistent with each file format's native precision.
* SEED files and SEED data (e.g. SeedLink, `readmseed`, FDSN requests) use
  double-precision channels.
* Data processing operations should all preserve the precision of SeisData
  channels.
* Deprecated keyword `q` (quality) from web requests due to its breakingly
  non-standard implementation. Quality constraints can be added to the `opts`
  keyword string (e.g. `opts="q=B&..."`) if needed.
* Bug fix: standard keywords in `SeisIO.KW` are now faithfully propagated to all
  web functions that allow them.

### 2019-03-18
* Major rewrite to `merge!`
  + Channels are no longer combined if they have different (non-empty) values
    of resp, units, or loc, or if they have different fs values.
  + Channels with no data (:x empty) or time info (:t empty) are deleted.
  + Dramatic speed and performance improvements.
  + Consistency fix: :x for each merged channel is now aligned in memory.    
* Consistency fix: bad web requests to IRISws (with e.g. `get_data`) no longer
  throw exceptions.
* `readmseed` improvements
  + Added support for blockette types:
    - [300] Step Calibration Blockette (60 bytes)
    - [310] Sine Calibration Blockette (60 bytes)
    - [320] Pseudo-random Calibration Blockette (64 bytes)
    - [390] Generic Calibration Blockette (28 bytes)
    - [395] Calibration Abort Blockette (16 bytes)
    - [2000] Variable Length Opaque Data Blockette
  + Timing information from blockette type 500 (Timing Blockette) is now
  saved in the :misc dictionary for the appropriate channel.

### 2019-03-12
* `readmseed` improvements:
  + tested data decoders added for remaining SEED data formats. three exceptions:
    - No Steim3. No one, even IRIS staff, has seen it used.
    - No USNSN Data Compression.
    - Int24 has a decoder that should work, but cannot be tested unless someone
    sends me a SEED volume with Int24 data.
  + corrected handling of event detection and timing blockettes.
  + temporarily deprecated handling of blockette type 2000; to return in a
    later release, when examples are found in the wild!
  + bugfix to handle an unusual situation where record endianness changes
    within a file
  + Improved time gap handling: for data sampled at fs, with δ = 1.0/fs,
    a time gap is now recorded when the time gap between the end of one
    packet and the start of the next exceeds 1.5x the sample rate δ (i.e.
    when drift > 0.5δ).
* Consistency fix: `get_data("IRIS" ... )` now always handles unset fields as follows:
  + An unset :loc is always set to `[0.0, 0.0, 0.0, 0.0, 0.0]`.
  + An unset :name is always set to match :id.
* SeedLink: fixed a bug where :x was not being truncated after a packet parse
  in which :x was resized.
* Updated examples.jl

### 2019-03-10
* Several improvements to `readsegy`
  + Fixed a bug where elevations were set incorrectly with `-passcal=true`.
  + Dictionary keys with `-full=true` are now much more comprehensible.
  + `readsegy` now always returns a SeisData object.
* Consistency fix: `readwin32!` now appends channels to existing SeisData
structures; it doesn't merge.
* Deprecated `wsac` as an alias to `writesac`.
* Moved CHANGELOG.md, ISSUES.md to docs/

### 2019-03-08
* `readwin32` is now an order of magnitude faster and uses an order of magnitude
less memory.
  + use kw `jst=false` to NOT apply a 9h correction to win32 data times.
* Added a `find_regex` command for OS-agonstic `find` functionality.
* The built-in `ls` now behaves like Bash ls but outputs full paths in returned file names.
  + Most invocations of `ls` still invoke `readdir` or `isile`.
  + Partial file name wildcards (e.g. "`ls(data/*.sac)`) now invoke `glob`.
  + Path wildcards (e.g. `ls(/data/*/*.sac)`) invoke `find_regex` to circumvent
    glob limitations.
  + Passing ony "\*" as a filename (e.g. "`ls(/home/*)`) invokes `find_regex` to
  recursively search subdirectories, as in the Bash shell.

### 2019-03-04
* Fixed a rare bug where `wseis` occasionally failed to write channels with
very few data points.
* Fixed several breaking `readwin32` issues.
  + Added timezone kw "tz" for `readwin32`; most files are UTC +9 (tz="true")

### 2019-03-03
* added `equalize_resp!` to translate instrument frequency responses to a given
complex response matrix (in pole/zero form).
* `gcdist` now returns an array, rather than a tuple of vectors.
* Deprecated SeedLink keyword argument `safety`.

### 2019-03-02
* `sync!` has been rewritten
  + `sync!` no longer calls `ungap!` or requires ungapped data
  + `sync!` no longer has an option to resample data
* Fixed a bug in `show` for a SeisChannel
* SeisIO native file format now supports all Unicode characters supported by
the Juila language.
* Added `detrend!`

### 2019-02-26
Bugfixes and consistency improvments:
* Consolidated methods for channel delete in `SeisData`, standardized syntax
* `isempty` no longer defined for `SeisEvent`; old definition wasn't achievable
* `rseis`, `wseis` no longer assume `:loc` has length-5 vectors. The intent was
always for location values and `:loc` vector lengths to be freeform.
* Improved read methods for `rseis`.
* More bug fixes for irregularly-sampled data.
* `get_data` now sets default keyword values from SeisIO.KW.
* `SeisData(n)` should now always allocate memory correctly.
* Addition of SeisChannel and SeisData objects is once again commutative.
* `SeisData(1)` and `SeisData(SeisChannel())` are now identical.
* `isempty(SeisChannel)` and `isempty(SeisData)` have been redefined in a self-consistent way.
Backend improvements:
* Reorganized directory trees
* Reorganized and improved tests
* Removed Distributions from dependencies
RandSeis:
* The "randseis" functions are now a submodule, `SeisIO.RandSeis`. Functions
have been renamed:
    + `randseischannel` --> `RandSeis.randSeisChannel`
    + `randseisdata` --> `RandSeis.randSeisData`
    + `randseishdr` --> `RandSeis.randSeisHdr`
    + `randseisevent` --> `RandSeis.randSeisEvent`

### 2019-02-24
Several minor consistency improvements:
* Exported functions are now all documented by topic
* `randseisevent` now uses the same keywords as `randseisdata`
* In SeedLink functions, `u` (url base) is now a keyword; FDSNWS keys aren't yet used
* A `SeisData` object can now be created from a `SeisEvent`
* Fixed exported functions to be more consistent and complete

### 2019-02-23
Significant update with many bug fixes and code improvements.
* Documentation has been updated to include a tutorial.
* FDSN methods now support the full list of standard FDSNWS servers.
  + Type `?seis_www` for server list and correspondence.
* Web requests of time-series data now use a wrapper function `get_data`.
  + Syntax is `get_data(METHOD, START_TIME, END_TIME)`, where:
  + `METHOD` is a protocol string, e.g., "FDSN", "IRIS".
  + `START_TIME` and `END_TIME` are the former keyword arguments `-s` and `-t`.
  + `FDSNget`, `IRISget`, `irisws` are no longer being exported.
    web functions.
* Web requests now merge! by default, rather than append!
* `FDSN_sta!` added to autofill existing SeisData headers; complements
the longstanding `FDSN_sta` method.
* Bug fixes:
  + delete!, deleteat! now correctly return nothing, preventing accidentally
    returning a link to a SeisData structure
  + show no longer has errors for channels that contain very few samples
    (length(S.x[i]) < 5)
  + Fixed a file read bug of :resp in native SeisIO format
  + randseis now sets :src accurately rather than using a random string
  + Fixed creation of new SeisData objects from multiple SeisChannels
  + `get_pha` is now correctly exported
* Behavior changes:
  + New SeisChannel structures no longer have fields set except :notes
  + New SeisData structures no longer have fields set except :notes
  + SeedLink keywords have changed and are now much more intuitive
  + randseis now uses floats to set the fraction of campaign data (KW `c=0.`)
    and guaranteed seismic data (KW `s`).
  + `FDSN_evt` has been rewritten.
  + changes to SeisData :id and :x fields can now be tracked with the
    functions track_on!(S) and u = track_off!(S).
* Performance improvements:
  + note! is a factor of 4 faster due to rewriting the time stamper
  + readsac now reads bigendian files

### 2019-02-15
`readmseed` bug fixes and backend improvements
  + Now skips blockettes of unrecognized types rather than throwing an error
  + Fixed bug #7; added @anowacki's previously-breaking mSEED file to tests

### 2019-02-13
Updated for Julia 1.1. Deprecated support for Julia 0.7.
* Minor bug fix in `SAC.jl`

### 2018-08-10
Updated for Julia 1.0.
* Added full travis-ci, appveyor testing

### 2018-08-07
Updated for Julia 0.7. Deprecated support for Julia 0.6.
* `wseis` changes:
  + New syntax: `wseis(filename, objects)`
  + Deprecated keyword arguments
  + Deprecated writing single-object files
  + Several bug fixes
* `SeisHdr` changes:
  + `:mag` is now `Tuple(Float32, String)`; was `Tuple(Float32, Char, Char)`
* Switched dependencies to `HTTP.jl`; `Requests.jl` was abandoned by its creators.
  + In SeisIO web requests, `to=τ` (timeout) now requires an `Integer` for `τ`; was `Real`.
* Improved partial string matches for channel names and IDs.
* Improved `note!` functionality and autologging of data processing operations
* New function: `clear_notes!` deletes notes for a given channel number or string ID
* Fixed a bug in `readuw`
* Fixed a bug in `ungap!` for very short data segments (< 20 samples)
* `batch_read` has been removed

### 2017-08-04
* Fixed a mini-SEED bug introduced 2017-07-16 where some IDs were set incorrectly.
* Added functions:
  + `env, env!`: Convert time-series data to envelopes (note: won't work with gapped data)
  + `del_sta!`: Delete all channels matching a station string (2nd part of ID)

### 2017-07-24
* Several minor bug fixes and performance improvements
* Added functions:
  + `lcfs`: Find lowest common sampling frequency
  + `t_win`, `w_time`: Convert `:t` between SeisIO time representation and a true time window
  + `demean!`, `unscale!`: basic processing operations now work in-place

### 2017-07-16
* `readmseed` rewritten; performance vastly improved
  + SeisIO now uses a small (~500k) memory-resident structure for SEED packets
  + SEED defaults can be changed with `seeddef`
  + Many minor bug fixes
* `findid` no longer relies on `findfirst` and String arrays.
* Faster initialization of empty SeisData structs with `SeisData()`.

### 2017-07-04
Updated for Julia 0.6. Deprecated support for Julia 0.5.

### 2017-04-19
* Removed `pol_sort`
* Fixed an indexing bug in SeisIO data file appendices

### 2017-03-16
* Moved seismic polarization functionality to a separate GitHub project.
* Functions with bug fixes: `randseischannel`, `randseisdata`, `randseisevent`, `autotap!`, `IRISget`, `SeisIO.parserec!`, `SeisIO.ls`, `SeisIO.autotuk!`

### 2017-03-15
Rewrote `merge` and arithmetic operators for functionality and speed.
* `merge!(S,T)` combines two SeisData structures S,T in S.
* `mseis!(S,...)` merges multiple SeisData structures into `S`.
  + This "splat" syntax can handle as many SeisData objects as system memory allows, e.g. `mseis!(S, S1, S2, S3, S4, S5)`).
* `S = merge(A)` merges an array of SeisData objects into a new object `S`.
* Arithmetic operators for SeisData have been standardized:
  + `S + T` appends T to S without merging.
  + `S * T` merges T into S via `merge(S,T)`.
  + `S - T` removes traces whose IDs match T from S.
  + `S ÷ T` is undefined.
* Arithmetic operators no longer operate in place, e.g., `S+T` for two SeisData objects creates a new SeisData object; `S` is not modified.
* SeisData arithmetic operations are non-associative: usually `S+T-T = S` but `S-T+T != S`.

Minor changes/additions:
* Web functions (e.g. `IRISget`) no longer synchronize requests by default;  synchronization can be specified by passing keyword argument `y=true`.
* `sync!` no longer de-means or cosine tapers around gaps.
* SeisIO now includes an internal `ls` command; access as `SeisIO.ls`. (This will never be exported due to conflict concerns)
* Automatic disk write (`w=true`) of requests with `IRISget` and `FDSNget` now generates file names that follow FDSN naming conventions `YY.JJJ.HH.MM.SS.sss.(id).ext`.
* Fixed a bug that broke `S.t` in SeisData channels with `length(S[i].x) = 1`
* Single-object files can now be written by specifying `sf=true` when calling `wseis`. By default, single-object file names use IRIS-style naming conventions.

### 2017-02-23
SeisIO data files now include searchable indices at the end of each file.
* This change is backwards-compatible and won't affect the ability to read existing files.
* A file index contains the following information, written in this order:
  - (length = ∑\_j∑\_i length(S.id[i])\_i) IDs for each trace in each object
  - (length = 3∑\_j S.n\_j) start and end times and byte indices of each trace in each object. (time unit = integer μs from Unix epoch)
  - Byte index to start of IDs.
  - Byte index to start of Ints.

### 2017-01-31
First stable SeisIO release.
* Documentation has been completely rewritten.
* All web functions now use the standard channel naming convention `NN.SSSSS.LL.CCC` (Net.Sta.Loc.Cha); number of letters in each field is the max. field size.
  + Web functions that require channel input now accept either a config file (pass the filename as a String), a String of comma-delineated channel IDs (formatted as above), or a String array (with IDs formatted as above).
* Renamed several web function keywords for uniformity.
* Deprecated keyword arguments in SeisIO data types
* Native SeisIO file format changed; not backwards-compatible
* `prune!(S)` is now `merge!(S)`

### 2017-01-24
* Type stability for nearly all methods and custom types
* Complete rewrite of mini-SEED resulting in 2 orders of magnitude speedup
* Faster read times for SAC, SEG Y, and UW data formats
* Better XML parsing
* batch_read works again
* Event functionality is no longer a submodule

### 2016-09-25
Updated for Julia 0.5. Deprecated support for Julia 0.4.

### 2016-05-17
* Added an alpha-level SeedLink client

### 2016-05-17
Initial commit for Julia 0.4
