# **How to Contribute**
SeisIO welcomes contributions, but users should follow the rules below.

## **Recommended Contribution Procedure**
0. **Please contact us first**. Describe the intended contribution(s). In addition to being polite, this ensures that you aren't doing the same thing as someone else.
1. Fork the code: in Julia, type `] dev SeisIO`.
2. Choose an appropriate branch:
  - For **bug fixes**, please use `master`.
  - For **new features**, please create a new branch or push to `dev`.
3. When ready to submit, push to your fork and submit a Pull Request.
4. Please wait a week while we review the request.

# **General Rules**

## Please don't add dependencies

## Include tests
* Good tests include a mix of unit tests and typical "use" cases.
* Our target code coverage is 98%, with no file below 95%, on both [codecov.io](https://codecov.io) and [coveralls.io](https://coveralls.io).
  - For some files, 95% coverage is impossible (due to e.g. rarely-seen data formats). If one of your files can't reach 95% due to the need to code for such rare cases, please tell us before making your PR.

## Write comprehensible code
* Code should be well-organized. Other contributors must be able to trace your function calls.
* Keep wrapper functions to a bare minimum. Nested wrapper functions will be rejected.
* Please only use [metaprogramming](https://docs.julialang.org/en/v1/manual/metaprogramming/index.html) when necessary (e.g., if there's a significant speed improvement).

## Limit external calls
For reasons of code transparency, calls to external functions or software should be kept to a minimum. All external calls must meet these conditions:

1. Julia can't do it natively, or Julia's version performs poorly.
2. The call works correctly in Windows, Linux, and Mac OS, without invoking emulators, virtual machines, Cygwin, or "additional setup instructions".
3. The source code of the external function call is free and publicly available. This explicitly excludes source code that can only be obtained by contacting a maintainer.

### Prohibited external calls
* No calls to software with (re)distribution restrictions, such as Seismic Analysis Code (SAC)
* No calls to commercial software, such as MATLAB™
* No calls to software with many contributors and no clear control process, such as ObsPy, Octave, and the Arch User Repository (AUR)

# **Processing/Analysis Contributions**
In addition to the above, code for data processing or analysis must conform to these specifications:

## Record all operations in `:notes`
All processing and analysis operations must be logged in the `:notes` field of each channel processed.

Use the function `note!` and add relevant information in comma-separated fields. Include the name of the function invoked, any options that affect the result, and human-readable information in the last field. Typical examples look like this:

`2019-04-19T06:28:32.313: filtfilt!, fl=1.0, fh=15.0, np=4, rp=8, rs=30, rt=Bandpass, dm=Butterworth`

It's best to log any changes to numeric values in the channel and affected field(s) in the human-readable field, e.g.,

`2019-04-19T07:20:57.531: ungap!, m=true, tap=false, filled 4 gaps (sum = 1590288 μs)`

## Don't assume ideal objects
Your code must handle (or skip, as needed) channels in SeisData objects (and/or SeisChannel objects) with undesirable features. Explicit cases that your code must be able to handle or skip include:
* irregularly-sampled data (`S.fs[i] == 0.0`)
* (potentially very many) time gaps of arbitrary lengths (e.g., one SeisIO test file has `size(S.t[i],1) > 200`; the largest gap is over a week long)
* segments with very few data points (`length(S.x[i]) < 10`)
* data that are neither seismic nor geodetic (e.g. timing, radiometers, SO₂ flux)
* empty `:resp` fields
* empty or unusual `:loc` fields. There is no standard way to describe a scientific instrument's position. For example, inertial seismometers can use any of these conventions to describe location:
  - [lat. lon, (ele or depth)]
  - [easting, northing, (ele or depth), lat, lon], where [lat, lon] is the cooordinate system origin
  - [UTM-x, UTM-y, (ele or depth), UTM-zone]
  - [r, θ, lat, lon], where [r, θ] is a position relative to an origin at [lat, lon] (rare)
  - In addition, adding positional descriptors to `:loc` (e.g., seismometer azimuth and incidence angle) introduces more ambiguity: for example, azimuth can be measured clockwise from north (cartographical) or counterclockwise from east (mathematical). The former is more common in geosciences, but many authors in the literature use the latter.

You don't need to plan for others' PEBKAC errors, but nothing on the above list is a mistake.

## Don't assume a work flow
If a function assumes or requires specific preprocessing steps, apply them in the function body or check for them in the `:notes` field of each channel.

Example: seismic data analysis often assumes a work flow in which each data segment is detrended (or de-meaned), then cosine tapered to start and end with `x = 0.0`. However, these steps make no sense for data from non-seismic instruments, including many examples colocated with seismometers whose data are archived at seismic data centers.

## Leave unprocessed data alone
Skip channels (or segments within channels) that you don't process; never alter or delete unprocessed data.

### Selecting the right data
Whenever possible, SeisIO follows [SEED channel naming conventions](http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf) for the `:id` field of geophysical data. Thus, there are at least two ways to identify data channels of interest:
1. Get the single-character "channel instrument code" for channel `i` with ``split(S.id[i], '.')[4][2]``; compare to [standard SEED instrument codes](https://ds.iris.edu/ds/nodes/dmc/data/formats/seed-channel-naming/).
  - This can break for instruments whose IDs don't use the SEED naming standard; placing the `split` command in a `try/catch` loop is a useful precaution here.
  - Channel code `Y` is ambiguous; beware of matching on it.
2. Check `:units`. This can be problematic as a single check:
  - Some sources report units in "counts" (e.g., "counts/s", "counts/s**2"), because the "stage zero" gain is also a unit conversion.
  - Some units are ambiguous; for example, both displacement seismometers and GPS displacement have units of distance.
