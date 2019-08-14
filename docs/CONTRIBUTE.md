# **How to Contribute**
0. **Please contact us first**. Describe the intended contribution(s). In addition to being polite, this ensures that you aren't doing the same thing as someone else.
1. Fork the code: in Julia, type `] dev SeisIO`.
2. Choose an appropriate branch:
  - For **bug fixes**, please use `master`.
  - For **new features** or **changes**, don't use `master`. Create a new branch or push to `dev`.
3. When ready to submit, push to your fork (please, not to `master`) and submit a Pull Request (please, not to `master`).
4. Please wait while we review the request.

# **General Rules**

## **Include tests for new code**
* We expect at least 95% code coverage on each file.
* Our target code coverage is 98% on both [CodeCov](https://codecov.io/gh/jpjones76/SeisIO.jl) and [Coveralls](https://coveralls.io/github/jpjones76/SeisIO.jl?branch=master). We're rarely below 97%. Please don't break that for us.
* Good tests include a mix of [unit testing](https://en.wikipedia.org/wiki/Unit_testing) and [use cases](https://en.wikipedia.org/wiki/Use_case).

Data formats with rare encodings can be exceptions to the 95% rule. For example, SEG Y is one of four extant file formats that still uses [IBM hexadecimal Float](https://en.wikipedia.org/wiki/IBM_hexadecimal_floating_point); we've never encountered it, so we can't test it, but it exists. We understand the need to handle these digital coelocanths, but please consider their rarity before deciding that SeisIO should support one. (For example, although Int24 encoding of SEED data exists in theory, we cannot find a single researcher who's encountered it; this includes IRIS DMC staff.)

## **Don't add dependencies to the SeisIO core module**

## **Write comprehensible code**
Other contributors must be able to understand your work. People must be able to use it. Scientific software shouldn't require a Ph.D. to use, even if one needs a Ph.D. to understand the science.

## Please limit calls to other languages
For reasons of transparency, portability, and reproducibility, external calls must meet three conditions:
1. Works correctly in (non-emulated) Windows, Linux, and Mac OS.
1. Source code free and publicly available. "Please contact the author for the source code" emphatically **does not** meet this standard.
1. Must free pointers after use. If we can make your code trigger a segmentation fault, we have no choice but to reject it.

We strongly recommend only calling external functions for tasks with no Julia equivalent (e.g. plotting) or whose native Julia versions perform poorly (e.g. `DateTime`).

### Prohibited external calls
* No software with (re)distribution restrictions, such as Seismic Analysis Code (SAC)
* No commercial software, such as MATLAB™ or Mathematica™
* No software with many contributors and no clear control process, such as ObsPy, Gnu Octave, or the Arch User Repository (AUR)

# **Processing/Analysis Contributions**
Code for processing or analysis must conform to additional specifications:

## Log function calls to `:notes`
Logging to `:notes` should contain enough detail that someone who reads `:notes` can replicate the work, starting with reading raw data from `:src`. Therefore, processing and analysis calls must be logged in the `:notes` field of (each affected channel of) each relevant object:
* Use the function `note!`; see the documentation for examples.
* Within each note, record function calls and relevant options in comma-delineated fields:
  - The first field is the function name.
  - Fields after the first contain input values that affect the result.
  - Optionally, you can place human-readable information in the last field.
* An example of logging for reproducibility:
```
2019-04-19T06:28:32.313: filtfilt!, fl=1.0, fh=15.0, np=4, rp=8, rs=30, rt=Bandpass, dm=Butterworth
2019-04-19T07:20:57.531: ungap!, m=true, tap=false, filled 4 gaps (sum = 1590288 μs)
```
* An example of inadequate logging:
```
2019-04-19T06:28:32.313: called my_wavelet_function with exit code 0
2019-04-19T06:29:20:000: best basis, Haar wavelet, j=3
```

## Don't assume ideal objects
Your code must handle (or skip, as needed) channels in `GphysData` subtypes (and/or `GphysChannel` subtypes) with undesirable features. Examples from our tests include:
* irregularly-sampled data (`S.fs[i] == 0.0`), such as campaign-style GPS, SO₂ flux, and rain gauge measurements.
* data with (potentially very many) time gaps of arbitrary lengths.
  - Example: one of the mini-SEED test files comes from Steve Malone's [rebuilt Mt. St. Helens data](https://ds.iris.edu/ds/newsletter/vol16/no2/422/very-old-mount-st-helens-data-arrives-at-the-dmc/). Because the network was physically dangerous to maintain, the full record spans several months but there are >200 time gaps, ranging in size from a few samples to a week and a half. Such gaps are _very_ common in records that predate the establishment of dedicated scientific data centers.
* segments and channels with very few data points (e.g. a channel `i` with `length(S.x[i]) < 10`)
* data that are neither seismic nor geodetic (e.g. timing, radiometers, gas flux)
* empty or unusual `:resp` or `:loc` fields

You don't need to plan for others' PEBKAC errors, but these situations aren't mistakes.

It's OK to skip channels that cannot logically be processed by your code. For example, one can't bandpass filter irregularly-sampled data in a straightforward way; even *approximate* filtering requires interpolating to a regularly-sampled time series, filtering that, and extracting results at the original sample times. That's a cool trick to impress one's Ph.D. committee, but we see little demand for filtering irregularly-sampled univariate geophysical data...

## Don't assume a work flow
If a function assumes or requires specific preprocessing steps, the best practice is to add code in the function that checks `:notes` for prerequisite steps and applies them as needed.

## Leave unprocessed data alone
Skip channels (or segments within channels) that you don't process. Never alter or delete unprocessed data. We realize that some code requires very specific data (for example, three-dimensional trace rotation requires a multicomponent seismometer); in these cases, use `getfield` and `getindex` to select applicable channels.

### Tips for selecting the right data
In an object that contains data from more than one instrument type, finding the right channels to process is non-trivial. For this reason, whenever possible, SeisIO follows [SEED channel naming conventions](http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf) for the `:id` field. Thus, there are at least two ways to identify channels of interest:
1. Get the single-character "channel instrument code" for channel `i` (`get_inst_codes` does this efficiently). Compare to [standard SEED instrument codes](https://ds.iris.edu/ds/nodes/dmc/data/formats/seed-channel-naming/) and build a channel list, as `get_seis_channels` does.
  - This method can break on instruments whose IDs don't follow the SEED standard.
  - Channel code `Y` is ambiguous; beware of matching on it.
2. Check `:units`. See the [units mini-API](./API/units.md). This is usually safe, but can be problematic in two situations:
  - Some sources report units in "counts" (e.g., "counts/s", "counts/s²"), because the "stage zero" gain is a unit conversion.
  - Some units are ambiguous; for example, displacement seismometers and displacement GPS both use distance (typically "m").
