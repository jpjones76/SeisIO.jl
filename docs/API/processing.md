**Data Processing API**

Code for data processing or analysis must conform to additional specifications
for inclusion in SeisIO.

# Don't assume ideal objects
Your code must handle (or skip, as needed) channels in `GphysData` subtypes
(and/or `GphysChannel` subtypes) with undesirable features. Examples from our
tests include:
* irregularly-sampled data (`S.fs[i] == 0.0`), such as campaign-style GPS, SO₂ flux, and rain gauge measurements.
* data with (potentially very many) time gaps of arbitrary lengths.
  - Example: one of the mini-SEED test files comes from Steve Malone's [rebuilt Mt. St. Helens data](https://ds.iris.edu/ds/newsletter/vol16/no2/422/very-old-mount-st-helens-data-arrives-at-the-dmc/). Because the network was physically dangerous to maintain, each SEED volume spans several months with >100 time gaps, ranging in size from a few samples to a week and a half. Such gaps are _very_ common in records that predate the establishment of dedicated scientific data centers.
* segments and channels with very few data points (e.g. a channel `i` with `length(S.x[i]) < 10`)
* data that are neither seismic nor geodetic (e.g. timing, radiometers, gas flux)
* empty or unusual `:resp` or `:loc` fields

You don't need to plan for PEBKAC errors, but none of the cases above are mistakes.

## Skip channels that can't processed
For example, one can't bandpass filter irregularly-sampled data in a
straightforward way; even *approximate* filtering requires interpolating to a
regularly-sampled time series, filtering that, and extracting results at the
original sample times. That's a cool trick to impress one's Ph.D. committee,
but is there a demand for it...?

## Leave unprocessed data alone
Never alter or delete unprocessed data. We realize that some code requires very
specific data (for example, three-dimensional trace rotation requires a
multicomponent seismometer); in these cases, use `getfield`, `getindex`, and
utilities like `get_seis_channels` to select applicable channels.

# Don't assume a work flow
If a function assumes or requires specific preprocessing steps, the best
practice is to add code to the function that checks `:notes` for prerequisite
steps and applies them as needed.

## Tips for selecting the right data
In an object that contains data from more than one instrument type, finding the
right channels to process is non-trivial. For this reason, whenever possible,
SeisIO follows [SEED channel naming conventions](http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf)
for the `:id` field. Thus, there are at least two ways to identify channels of
interest:
1. Get the single-character "channel instrument code" for channel `i` (`get_inst_codes` does this efficiently). Compare to [standard SEED instrument codes](https://ds.iris.edu/ds/nodes/dmc/data/formats/seed-channel-naming/) and build a channel list, as `get_seis_channels` does.
  - This method can break on instruments whose IDs don't follow the SEED standard.
  - Channel code `Y` is opaque and therefore ambiguous; beware matching on it.
2. Check `:units`. See the [units mini-API](./API/units.md). This is usually safe, but can be problematic in two situations:
  - Some sources report units in "counts" (e.g., "counts/s", "counts/s²"), because the "stage zero" gain is a unit conversion.
  - Some units are ambiguous; for example, displacement seismometers and displacement GPS both use distance (typically "m").

# Log function calls to `:notes`
Logging to `:notes` should contain enough detail that someone who reads `:notes`
can replicate the work, starting with reading raw data from `:src`. Therefore,
processing and analysis calls must be logged in the `:notes` field of (each
affected channel of) each relevant object:
* Use the function `note!`; see its documentation for examples.
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

# Please, no unestablished algorithms
We understand the need for cutting-edge solutions, but unpublished algorithms
make little sense in SeisIO core. It's always a better idea to place research-
level code in its own package.