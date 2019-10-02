SeisIO timekeeping API

This guide applies to any single-channel time container `t = S.t[i]` of any
GphysData object S, including (but not limited to) SeisData structures. By
extension this also describes the time field `:t` of any GphysChannel object,
including a SeisChannel structure.

# 1. Structure of `t` when `fs > 0.0` (regularly-sampled data)
The time matrix `t` gives a delta-encoded representation of time gaps in `:x`.

## `t[:,1]`: indices within `:x`

### `t[1,1] == 1`
This should always be 1, indicating that `:x` begins at sample 1.

### `t[end,1] == length(x)`
This is assumed to be true when an object is inspected from the REPL.

## `t[:,2]`: time values in **microseconds** (μs)

### `t[1,2]`: absolute time of first sample in `:x`
* Start time is measured relative to the Unix epoch.
  + Example 1: `t[1,2] = 0` is 1970-01-01T00:00:00 (GMT/UTC +0).
  + Example 2: `t[1,2] = 1559347200000000` is 2019-06-01T00:00:00.
  + Representation problems will begin at approximately 2255-06-05T23:47:34,
  when the integer μs count exceeds `maxintfloat()` at 64-bit precision.

### `t[2:end,2]`: time gaps in μs
* A time field `t` with no time gaps has the property `size(t,1) == 2`.
* Time gaps are *in addition to*, not *instead of*, the sample interval in μs.
  + For a time gap at index `j = t[i,1]` in `:x`, add the sampling interval in μs
  to `t[i,2]` to calculate the total time between samples `j-1` and `j`.
    - Example: a time gap of 2.0 seconds in data sampled at 40 Hz before index
    `j=12` in `x` is represented `t[i,:] = [12 1975000]`, not `[12 2000000]`.
    The difference, 25000 μs, is the sample interval.

#### usually `t[end,2] == 0`
The last value should be a 0, though this is not strictly required. A
degenerate situation with a time gap before the last sample is allowed.

# 2. Structure of `t` when `fs == 0.0` (irregularly-sampled data)
The time matrix `t` gives the sample representations and absolute sample times
of each data point in `:x`.

## `t[:,1]`: indices in `:x`
This is redundant for irregularly-sampled data because `:x` contains vectors
with linear indexing in all current GphysData subtypes.

## `t[:,2]`: absolute sample times
These are not delta-encoded for irregularly-sampled data: because `t` uses
64-bit integers, each sample time requires 8 bits of memory.

# Converting to Absolute Time
Internal functions for working with time matrices are in `CoreUtils/time.jl`.
The most common functions needed to manipulate time matrices are covered by:

`import SeisIO: t_expand, t_collapse, t_win, w_time, tx_float`

If the absolute time of each sample from channel `i` of an object `S` is
required, one can use the following commands:

```
import SeisIO: t_expand
t = S.t[i]
fs = S.fs[i]
tx = t_expand(t, fs)
dtx = u2d.(tx.*1.0e-6)            # for a DateTime vector
stx = string.(u2d.(tx.*1.0e-6))   # for a vector of Strings
```

An equivalent one-liner to obtain a String vector with UTC times of each sample
in channel `i` is

`stx = string.(u2d.(SeisIO.t_expand(S.t[i], S.fs[i]).*1.0e-6))`
