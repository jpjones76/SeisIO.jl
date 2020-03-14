# **SeisIO Time Guide and API**
This guide describes how to use the time field `:t` of any GphysData (multichannel) or GphysChannel (single-channel) structure in SeisIO and its submodules. This includes, but is not limited to, SeisData and SeisChannel structures in SeisIO core. Future subtypes of GphysData and GphysChannel will also conform to the standards established in this guide.

All data described herein are univariate and discretely sampled.

# **SeisIO Time Matrices**
## **List of Variables**
| V   | Meaning                   | Julia Type in SeisIO                      |
|:--- |:----                      | :---                                      |
| C   | single-channel structure  | typeof(C) <: SeisIO.GphysChannel          |
| S   | multichannel structure    | typeof(S) <: SeisIO.GphysData             |
| T   | SeisIO time matrix, `:t`  | Array{Int64, 2}                           |
| X   | SeisIO data vector, `:x`  | Union{Vector{Float32}, Vector{Float64}}   |
| end | last index of a dimension | Integer                                   |
| fs  | sampling frequency [Hz]   | Float64                                   |
| i   | channel index             | Integer                                   |
| j   | sample index              | Integer                                   |
| k   | row index in time matrix  | Integer                                   |
| t   | time                      | Int64                                     |
| Δ   | sampling interval [μs]    | Int64                                     |
| δt  | time gap or time jump     | Int64                                     |

## **Definitions of Terms**
* **Unix epoch** or **epoch time**: 1970-01-01T00:00:00 (UTC)
* **single-channel structure**: a structure that can contain only discrete univariate data from a single channel of a single instrument. The guidelines below apply to single-channel structures by assuming a channel index subscript value of *i* = 1.
* **multichannel structure**: a structure that can contain discrete univariate data from multile channels of multiple instruments.
* **time-series**: a vector *Xᵢ* of univariate data sampled at a regular interval *Δᵢ*.
  + SeisIO convention: data are time-series if `fsᵢ > 0.0`
* **irregular**: univariate data sampled at discrete times. Short for "irregularly-sampled".
  + SeisIO convention: data are irregular if `fsᵢ == 0.0`
* **gap**: a significant deviation in **time-series** *Xᵢ* from the regular sampling interval *Δᵢ*.
  + Formal definition: for values *Xᵢⱼ₋₁* and *Xᵢⱼ* sampled at times *tᵢⱼ₋₁*, *tᵢⱼ*, *δt ≡ tᵢⱼ₋₁* - *tᵢⱼ* - *Δᵢ*
  * A gap before sample *Xᵢⱼ* is considered significant in SeisIO if sample times *tᵢⱼ₋₁*, *tᵢⱼ* satisfy the inequality |*tᵢⱼ₋₁* - *tᵢⱼ* - *Δᵢ* | > 0.5 *Δᵢ*.
  + In SeisIO, time gaps can be positive or negative.
* **segment**: a contiguous set of indices *j₀*:*j₁* in **time-series** *Xᵢ* with *j₁* ≥ *j₀* and no **gap** between *Xᵢⱼ₀* and *Xᵢⱼ₁*.
  + If *j₁* > *j₀*, every pair of adjacent samples (*Xᵢⱼ*, *Xᵢⱼ₊₁*), whose indices satisfy the inequality *j₀* ≤ *j* < *j* + 1 ≤ *j₁*, satisfies the property *tᵢⱼ₊₁* - *tᵢⱼ* = *Δᵢ* to within the absolute precision of a **gap**, i.e., ≤0.5 *Δᵢ*.
    * Sample times are generally much more precise than ±0.5 *Δᵢ* with modern digital recording equipment.
    * Time gaps with absolute deviations ≤ 0.5 *Δᵢ* from sampling interval *Δᵢ* are discarded by SeisIO readers.

## **Definition of SeisIO Time Matrix**
A two-column Array{Int64,2}, in which:
* `Tᵢ[:,1]` are monotonically increasing indices *j* in *Xᵢ*
* `Tᵢ[:,2]` are time values in μs

### **Time-series time matrix**
#### `Tᵢ[:,1]`
* `Tᵢ[1,1] == 1`
* `Tᵢ[end,1] == length(Xᵢ)`
* `Tᵢ[k,1] < Tᵢ[k+1,1]` for any *k* (row index *k* increases monotonically with data index *j*)
* `Tᵢ[2:end-1,1]`: each sample is the first index in *Xᵢ* after the corresponding time gap in the second column

#### `Tᵢ[:,2]`
* `Tᵢ[1,2]` is the absolute time of *X₁* measured from Unix epoch
  + `Tᵢ[1,2]` is usually the earliest sample time; however, if the time segments in *Xᵢ* aren't in chronological order, this isn't necessarily true.
* `Tᵢ[2:end,2]` are time gaps *δt* in *Xᵢ*, defined *δt* ≡ *tᵢⱼ₋₁* - *tᵢⱼ* - *Δᵢ*.
  + **Important**: for time gap *δt* = *Tᵢ[k,2]* at index *j = Tᵢ[k,1]* in *Xᵢ*, the total time between samples *Xᵢⱼ₋₁* and *Xᵢⱼ* is *δt + Δᵢ* not *δt*. This may differ from time gap representations in other geophysical software.
  + `Tᵢ[end,2]` is usually the latest sample time; however, if the time segments in *Xᵢ* aren't in chronological order, this isn't necessarily true.

#### How gaps are logged
1. A gap is denoted by a row in *Tᵢ* whenever samples *Xᵢⱼ*, *Xᵢⱼ₊₁* have sample times *tᵢⱼ₊₁*, *tᵢⱼ* that satisfy |*tᵢⱼ₋₁* - *tᵢⱼ* - *Δᵢ* | > 0.5 *Δᵢ*.
2. Both negative and positive time gaps are logged.

#### Examples
* `Tᵢ[1,2] = 0` occurred at *tᵢ* = 1970-01-01T00:00:00.00000 (UTC).
* `Tᵢ[1,2] = 1559347200000000` occurred at tᵢ = 2019-06-01T00:00:00.000000.
* `Tᵢ[k,:] = [12 1975000]` at *fsᵢ* = 40.0 Hz is a time gap of 2.0 s before the 12th sample of *Xᵢ*.
  + Check: `g = 1975000; d = round(Int64,1.0e6/40.0); (g+d)/1.0e6`
* `Tᵢ[k,:] = [31337 -86400000000]` at *fsᵢ* = 100.0 Hz is a time gap of -86399.99 s before the 31337th sample of *Xᵢ*.
  + Check: `g = -86400000000; d = round(Int64,1.0e6/100.0); (g+d)/1.0e6`
    - Substituting `1.0e-6*(g+d)` for the last expression is slightly off due to floating-point rounding.
* `Tᵢ = [1 1324100000000000; 8640000 0]` at *fsᵢ* = 100.0 Hz is a one-segment time matrix.
* `Tᵢ = [1 1401000000000002; 100001 9975000; 200001 345000; 300000 0]` at *fsᵢ* = 40.0 Hz is a three-segment time matrix.
* `Tᵢ = [1 1324100000000000; 8640000 50000]` at *fsᵢ* = 100.0 Hz is a two-segment time matrix.
  + There is a gap of *δ* = 50000 μs between samples *j* = 8639999 and *j* = 8640000.
  + The second segment is one sample long; it starts and ends at *j* = 8640000.
  + The last two samples were recorded 0.06 s apart.
* `Tᵢ = [1 1559347200000000; 31337 -86400010000; 120000 0]` at *fsᵢ* = 100.0 Hz is a two-segment time matrix where the first sample is not the earliest.
  + The earliest sample is *j* = 31337, recorded at 2019-05-31T00:05:13.36 (UTC).
  + If the data segments were in chronological order, the equivalent time matrix would be `Tᵢ = [1 1559261113350000; 88665 85200010000; 120000 0]`.

* Recording a gap:
  + *tᵢⱼ₋₁* = 1582917371000000
  + *tᵢⱼ* = 1582917371008000
  + *Δᵢ* = 20000 μs
  + *δt* = 1582917371008000 - 1582917371000000 - Δᵢ = -12000 μs
  + The gap in *Tᵢ* before sample *j* is denoted by the row `[j -12000]`

#### Notes
* A time matrix `Tᵢ` with no time gaps has the property `size(Tᵢ,1) == 2`.
* A time gap in `Tᵢ[end,2]` is acceptable. This indicates there was a time gap before the last recorded sample.
* In a time-series time matrix, `Tᵢ[1,2]` and `Tᵢ[end,2]` are the only values that should ever be 0. Length-0 gaps in other rows are undefined and untested behavior; they also create a display issues with `show`.

### **Irregular time matrix**
#### `Tᵢ[:,1]` expected behavior
* `Tᵢ[1,1] == 1`
* `Tᵢ[end,1] == length(Xᵢ)`
* `Tᵢ[:,1]` has the same length as *Xᵢ*
* `Tᵢ[k,1]` < `Tᵢ[k+1,1]` for any `k` (row index `k` increases monotonically with data index `j`)
* `Tᵢ[k,1] = k`; in other words, row number corresponds to index `k` in *Xᵢ*
  + These are technically redundant, as all current GphysData subtypes use linear indexing for *Xᵢ*

#### `T[:,2]` expected behavior
* `Tᵢ[k,2]` is the sample time of `Xᵢ[k]` in μs relative to the Unix epoch

## **Converting to Absolute Time**
Internal functions for working with time matrices are in `CoreUtils/time.jl`. An API for working with them is given below.

### **Common use cases**
The most common functions needed to manipulate time matrices are covered by:

`import SeisIO: t_expand, t_collapse, t_win, w_time, tx_float`

If the absolute time of each sample in `S.x[i]` is required, try the following commands:
```
using SeisIO
import SeisIO: t_expand
t = S.t[i]
fs = S.fs[i]
tx = t_expand(t, fs)              # Int64 vector of sample times (in μs)
dtx = u2d.(tx.*1.0e-6)            # DateTime vector of sample times
stx = string.(u2d.(tx.*1.0e-6))   # String vector of sample times
```

## **Obsolescence**
The SeisIO time matrix system will remain accurate at 64-bit precision until 5 June 2255. At later dates it will become increasingly unusable, as 64-bit floating-point representation of integer μs will become increasingly imprecise. Please plan to discontinue use before that date.

Check: `using Dates; unix2datetime(1.0e-6*maxintfloat())`

# **Time API**
## **List of Variables**
| V   | Meaning                   | Type in Julia     |
|:--- |:----                      | :---              |
| A   | array of Int64 time vals  | Array{Int64, 1}   |
| B   | array of Int32 time vals  | Array{Int32, 1}   |
| C   | single-channel structure  | typeof(C) <: SeisIO.GphysChannel  |
| D   | Julia DateTime structure  | DateTime          |
| H   | hex-encoded UInt8 array   | Array{UInt8, 1}   |
| M   | month                     | Integer           |
| S   | multichannel structure    | typeof(S) <: SeisIO.GphysData     |
| T   | SeisIO time matrix        | Array{Int64, 2}   |
| Tf  | floating-point time vector| Array{Float64, 1} |
| Tx  | expanded time vector      | Array{Int64, 1}   |
| W   | time window matrix        | Array{Int64, 2}   |
| c   | fractional seconds        | Integer           |
| d   | day of month              | Integer           |
| fs  | sampling frequency [Hz]   | Float64           |
| h   | hour                      | Integer           |
| i   | channel index             | Int64             |
| j   | Julian day (day of year)  | Integer           |
| k   | row index in time matrix  | Integer           |
| m   | minute                    | Integer           |
| n   | a 64-bit integer          | Int64             |
| r   | real number               | Real              |
| s   | second                    | Integer           |
| str | ASCII string              | String            |
| t   | time value                | Int64             |
| ts  | time spec                 | TimeSpec          |
| u   | hex-encoded 8-bit uint    | UInt8             |
| x   | a Julia double float      | Float64           |
| xj  | x-indices of segments     | Array{Int64, 2}   |
| y   | four-digit year           | Int64             |
| yy  | two-digit hex year part   | UInt8             |
| Δ   | sampling interval [μs]    | Int64             |
| μ   | microsecond               | Integer           |

## **Function API**

`TimeSpec`

Type alias to `Union{DateTime, Real, String}`

`check_for_gap!(S::GphysData, i::Int64, t::Int64, n::Integer, v::Integer)`

Check for gaps between the end of *S.t[i]* and time *t*. Assumes the data
segment being added is length-*n*. Thin wrapper to *t_extend*.

`x = d2u(D::DateTime)`

Alias to `Dates.datetime2unix`

`datehex2μs!(A::Array{Int64, 1}, H::Array{UInt8, 1})`

Unpack datehex-encoded time values from length-8 datehex array *H* to length-6 array *A*. Assumes *H* is of the form *[yy1, yy2, M, d, h, m, s, c]* where *c* here is in hundredths of seconds.

`t = endtime(T::Array{Int64, 2}, Δ::Int64)`

`t = endtime(T::Array{Int64, 2}, fs::Float64)`

Compute the time of the last sample in *T* sampled at interval *Δ* [μs] or frequency *fs* [Hz]. Output is integer μs measured from the Unix epoch.

`s = int2tstr(t::Int64)`

Convert time value *t* to a String.

`M,d = j2md(y, j)`

Convert year *y* and Julian day (day of year) *j* to month *M*, day *d*.

`j = md2j(y, M, d)`

Convert month *M*, day *d* of year *y* to Julian day (day of year) *j*.

`mk_t!(C::GphysChannel, n::Integer, t::Int64)`

Initialize SeisIO time matrix *C.t* for *n*-sample data vector *C.x* to start at *t* in integer μs from the Unix epoch.

`mk_t(n::Integer, t::Int64)`

Create new SeisIO time matrix *T* for an *n*-sample data vector starting at *t* in integer μs from the Unix epoch.

`t = mktime(y::T, j::T, h::T, M::T, s::T, μs::T) where T<:Integer`

Convert *y*, *j*, *h*, *m*, *s*, *μ* to integer μs from the Unix epoch.

`t = mktime(A::Array{T, 1}) where T<:Integer`

Convert values in *A* to total integer μs from the Unix epoch. Expected format of *A* is *[y, j, h, s, μ]*.

`(str0, str1) = parsetimewin(ts1::TimeSpec, ts2::TimeSpec)`

Convert *ts1*, *ts2* to String, and sort s.t. *DateTime(str0)* < *DateTime(str1)*. See **TimeSpec API** below.

`t = starttime(T::Array{Int64, 2}, Δ::Int64)`

`t = starttime(T::Array{Int64, 2}, fs::Float64)`

Get the time of the first sample in SeisIO time matrix `t`, sampled at
interval `Δ` [μs] or frequency `fs` [Hz]. Output is integer μs measured from
the Unix epoch.

`t_arr!(B::Array{Int32,1}, t::Int64)`

Convert *t* to *[y, j, h, m, s, c]*, overwriting the first 6 values in *B* with the result. Here, *c* is milliseconds.

`T = t_collapse(Tx::Array{Int64, 1}, fs::Float64)`

Create a time matrix from times in *Tx* sampled at *fs* Hz. For input matrix *Txᵢ*, the time *t* of each index *j* is the sample time of *Xᵢⱼ* measured relative to the Unix epoch.

`Tx = t_expand(T::Array{Int64, 2}, fs::Float64)`

Create a vector of sample times *Tx* starting at *T[1,2]* for a data vector *X* sampled at *fs* Hz.

`str = tstr(D::DateTime)`

Convert DateTime *D* to String *str*. The output format follows ISO 8601 code `YYYY-MM-DDThh:mm:ss`.

`D = u2d(r::Real)`

Alias to `Dates.unix2datetime`

`T = t_extend(T::Array{Int64,2}, t_new::Int64, n_new::Int64, Δ::Int64)`

`T = t_extend(T::Array{Int64,2}, t::Integer, n::Integer, fs::Float64)`

Extend SeisIO time matrix *T* sampled at interval *Δ* μs or frequency *fs* Hz. For matrix *Tᵢ*:
* *t_new* is the start time of the next segment in data vector *Xᵢ*
* *n_new* is the expected number of samples in the next segment of *Xᵢ*

This function has a mini-API below.

`W = t_win(T::Array{Int64, 2}, Δ::Int64)`

`W = t_win(T::Array{Int64, 2}, fs::Float64)`

Convert time matrix *T* for data sampled at interval Δ [μs] or frequency fs [Hz] to a time window matrix *W* of segment times, measured from the Unix epoch. Window *k* starts at *W[k,1]* and ends at *W[k,2]*.

`str = timestamp()`

Return a String with the current time, with ISO 8601 format code `YYYY-MM-DDThh:mm:ss.s`. Equivalent to `tstr(now(UTC))`.

`str = timestamp(ts::Union{DateTime, Real, String})`

Alias to `tstr(t)`

`str1 = tnote(str::String)`

Create prefix of timestamped note; alias to `string(timestamp(), " ¦ ", str)`

`t = tstr2int(str::String)`

Convert time string *str* to μs. *str* must follow [Julia expectations](https://docs.julialang.org/en/v1/stdlib/Dates/) for DateTime input strings.

`Tf = tx_float(T::Array{Int64, 2}, fs::Float64)`

Convert time matrix *T* sampled at frequency *fs* Hz to an array of Float64 sample times in μs relative to the Unix epoch. For input matrix *Tᵢ* the time value *t* of each index *j* in *Tf* is the sample time of *Xᵢⱼ* measured relative to the Unix epoch.

`n = unpack_u8(u::UInt8)`

Unpack a datehex-encoded UInt8 to Int64. In this encoding, the UInt8 representation *u=0xYZ* uses *Y* for the first digit and *Z* for the second; for example, 0x22 is the number 22.

`T = w_time(W::Array{Int64, 2}, Δ::Int64)`

Convert time window matrix *W* of data sampled at interval *Δ* [μs] or frequency *fs* [Hz] to a SeisIO time matrix.

`xj = x_inds(T::Array{Int64, 2})`

Get *x*-indices *j* corresponding to the start and end of each segment in *T*. Total number of segments is *size(xj, 1)*. Segment *k* starts at index *xj[k,1]* and ends at *xj[k,2]*.

`t = y2μs(y::Integer)`

Convert year *y* to integer μs from the Unix epoch.

## **TimeSpec API**
Functions that allow time specification use two reserved keywords or arguments to track time:
* *s*: Start (begin) time
* *t*: Termination (end) time

A TimeSpec can be any Type in Union{Real, DateTime, String}.
* Real numbers are interpreted as seconds
  * **Caution**: not μs; not measured from Epoch time
  * Exact behavior is given in the table below
* DateTime values should follow [Julia documentation](https://docs.julialang.org/en/v1/stdlib/Dates/).
* Strings should conform to [ISO 8601](https://www.w3.org/TR/NOTE-datetime) *without* the time zone designator.
  + ISO 8601 expected format spec: `YYYY-MM-DDThh:mm:ss.s`
    + Fractional second is optional and accepts up to 6 decimal places (μs)
    + Julia support for ISO 8601 time zones is NYI
  + Equivalent Unix `strftime` format codes: `%Y-%m-%dT%H:%M:%S`, `%FT%T`
  * Example: `s="2016-03-23T11:17:00.333"`

When start and end time are both specified, they're sorted so that `t` < `s` doesn't error.

### **parsetimewin Behavior**
In all cases, parsetimewin outputs a pair of strings, sorted so that the first string corresponds to the earlier start time.

| typeof(s) | typeof(t) | Behavior                                          |
|:------    |:------    |:-------------------------------------             |
| DateTime  | DateTime  | convert to String, then sort                      |
| DateTime  | Real      | add *t* seconds to *s*, convert to String, sort   |
| DateTime  | String    | convert *s* to String, then sort                  |
| Real      | DateTime  | add *s* seconds to *t*, convert to String, sort   |
| Real      | Real      | treat as relative, convert to String, sort        |
| Real      | String    | add *s* seconds to *t*, convert to String, sort   |
| String    | DateTime  | convert *t* to String, then sort                  |
| String    | Real      | add *t* seconds to *s*, convert to String, sort   |
| String    | String    | sort                                              |

Special behavior with (Real, Real): *s* and *t* are converted to seconds from the start of the current minute.
