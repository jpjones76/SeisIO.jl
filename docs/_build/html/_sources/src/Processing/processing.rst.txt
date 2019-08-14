Supported processing operations are described below.

In most cases, a "safe" version of each function can be invoked to create a
new object with the processed output.

Any function that can logically operate on a single-channel object will do so. Any
function that operates on a SeisData object can be applied to the :data field of a
SeisEvent object.

###############
Basic Functions
###############

These functions have no keywords that fundamentally change their behavior.

.. function: demean!(S::GphysData[, chans=CC, irr=false])

Remove the mean from all channels i with S.fs[i] > 0.0. Specify irr=true to also
remove the mean from irregularly sampled channels. Specify chans=CC to restrict
to channel number(s) CC. Ignores NaNs.

.. function: detrend!(S::GphysData[, n=1, chans=CC, irr=false])

Remove the polynomial trend of degree n from every regularly-sampled channel
in S using a least-squares polynomial fit. Specify chans=CC to restrict
to channel number(s) CC. Ignores NaNs.

.. function:: nanfill!(S)

For each channel **i** in **S**, replace all NaNs in **S.x[i]** with the mean
of non-NaN values.

.. function:: resample!(S::GphysData [, chans=CC, fs=FS])
.. function:: resample!(C::SeisChannel, fs::Float64)

Resample data in S to FS Hz. If keyword **fs** is not specified, data are
resampled to the lowest non-zero value in **S.fs[CC]**. Note that a poor choice
of fs can lead to upsampling and other bad behaviors.

Use keyword **chans=CC** to only resample channel numbers **CC**. By default,
all channels **i** with **S.fs[i] > 0.0** are resampled.

.. function:: unscale!(S[, chans=CC, irr=false])

Divide the gains from all channels **i** with **S.fs[i] > 0.0**. Specify
chans=CC to restrict to channel number(s) CC. Specify **irr=true** to also
remove gains of irregularly-sampled channels.

######################
Customizable Functions
######################

*******************
Convert Seismograms
*******************

Seismograms can be converted to or from displacement, velocity, or acceleration
using convert_seis:

.. function:: convert_seis!(S[, chans=CC, units_out=UU, v=V])
.. function:: convert_seis!(C[, units_out=UU, v=V])

Converts all seismic data channels in `S` to velocity seismograms,
differentiating or integrating as needed.

Keywords
========
* units_out=UU: specify output units: "m", "m/s" (default), or "m/s²"
* chans=CC: restrict seismogram conversion to seismic data channels in CC
* v=V: verbosity

Behavior and Usage Warnings
---------------------------

**Long Seismograms**: convert_seis becomes less reversible as seismograms lengthen,
especially at Float32 precision, due to `loss of significance
<https://en.wikipedia.org/wiki/Floating-point_arithmetic#Accuracy_problems>`_.
At single (Float32) precision, seismograms with N ~ 10^6 samples are
reconstructable after one conversion (e.g. "m" ==> "m/s" can be reversed, with
output approximately equal to the original data). After multiple conversions
(i.e., "m" ==> "m/s²" or "m/s²" ==> "m"), Float32 data cannot be perfectly
reconstructed in this way, though reconstruction errors are typically small.

**Rectangular Integration**: integration is always rectangular; irregularly-spaced
seismic data are not processed by convert_seis. Summation uses an in-place
variant of `Kahan-Babuška-Neumaier summation <https://github.com/JuliaMath/KahanSummation.jl>`_.

.....

*********
Fill Gaps
*********

.. function:: ungap!(S[, chans=CC, m=true, tap=false])
.. function:: ungap!(C[, m=true, tap=false])

Fill time gaps in each channel with the mean of the channel data.

Keywords
========
* chans=CC: only ungap channels CC.
* m=false: this flag fills gaps with NaNs instead of the mean.
* tap=true: taper data before filling gaps.

.....

.. _merge:


*****
Merge
*****

.. function:: merge!(S::GphysData, U::GphysData)

Merge two GphysData structures. For timeseries data, a single-pass merge-and-prune
operation is applied to value pairs whose sample times are separated by less than
half the sampling interval.

.. function:: merge!(S::GphysData)

"Flatten" a GphysData structure by merging data from identical channels.


Merge Behavior
==============

Which channels merge?
---------------------
* Channels merge if they have identical values for ``:id``, ``:fs``, ``:loc``, ``:resp``, and ``:units``.
* An unset ``:loc``, ``:resp``, or ``:units`` field matches any set value in the corresponding field of another channel.


What happens to merged fields?
------------------------------
* The essential properties above are preserved.
* Other fields are combined.
* Merged channels with different `:name` values use the name of the channel with the latest data before the merge; other names are logged to `:notes`.


What does ``merge!`` resolve?
-----------------------------

.. csv-table::
  :header: Issue, Resolution
  :delim: |
  :widths: 1, 1

  Empty channels | Delete
  Duplicated channels | Delete duplicate channels
  Duplicated windows in channel(s)  | Delete duplicate windows
  Multiple channels, same properties\ :sup:`(a)` | Merge to a single channel
  Channel with out-of-order time windows | Sort in chronological order
  Overlapping windows, identical data, time-aligned | Windows merged
  Overlapping windows, identical data, small time offset\ :sup:`(a)` | Time offset corrected, windows merged
  Overlapping windows, non-identical data | Samples averaged, windows merged

:sup:`(a)` "Properties" here are ``:id``, ``:fs``, ``:loc``, ``:resp``, and ``:units``.
:sup:`(b)` Data offset >4 sample intervals are treated as overlapping and non-identical.

When SeisIO Won't Merge
------------------------
SeisIO does **not** combine data channels if **any** of the five fields above
are non-empty and different. For example, if a GphysData object S contains two
channels, each with id "XX.FOO..BHZ", but one has fs=100 Hz and the other fs=50 Hz,
**merge!** does nothing.

It's best to merge only unprocessed data. Data segments that were processed
independently (e.g. detrended) will be averaged pointwise when merged, which
can easily leave data in an unusuable state.

.. function:: mseis!(S::GphysData, U::GphysData, ...)

Merge multiple GphysData structures into S.

.....

***************************
Seismic Instrument Response
***************************

.. function:: translate_resp!(S, resp_new[, chans=CC, wl=g])
.. function:: translate_resp!(Ch, resp_new[, wl=g])

Translate the instrument response of seismic data channels to **resp_new**.
Replaces field **:resp** with **resp_new** for all affected channels.

.. function:: remove_resp!(S, chans=CC, wl=g])
.. function:: remove_resp!(Ch, wl=g])

Remove (flatten to DC) the instrument response of **Ch**, or of seismic data
channels **CC** in **S**. Replaces **:resp** with the appropriate (all-pass)
response.

Keywords
========
* **C=cha** restricts response translation for GphysData object **S** to channel(s) **cha**. Accepts an Integer, UnitRange, or Array{Int64,1} argument; does *not* accept string IDs. By default, all seismic data channels in **S** have their responses translated to **resp_new**.
* **wl=g** sets the waterlevel to g (default: g = eps(Float32) ~ 1.1f-7). The waterlevel is the minimum magnitude (absolute value) of the normalized old frequency response; in other words, if the old frequency response has a maximum magnitude of 1.0, then no response coefficient can be lower than g. This is useful to prevent "divide by zero" errors, but setting it too high will cause errors.


Precision and Memory Optimization
=================================
To optimize speed and memory use, instrument response translation maps data to
Complex{Float32} before translation; thus, with Float64 data, there can be
minor rounding errors.

Instrument responses are also memory-intensive. The minimum memory consumption
to translate the response of a gapless Float32 SeisChannel object is ~7x the
size of the object itself.

More precisely, for an object **S** (of Type <: GphysData or GphysChannel),
translation requires memory ~ 2 kB + the greater of (7x the size of the longest
Float32 segment, or 3.5x the size of the longest Float64 segment). Translation
uses four vectors -- three complex and one real -- that are updated and
dynamically resized as the algorithm loops over each segment:

* Old response container: Array{Complex{Float32,1}}(undef, Nx)
* New response container: Array{Complex{Float32,1}}(undef, Nx)
* Complex data container: Array{Complex{Float32,1}}(undef, Nx)
* Real frequencies for FFT: Array{Float32,1}(undef, Nx)

...where **Nx** is the number of samples in the longest segment in **S**.

.....

***********
Synchronize
***********

.. function:: sync!(S::GphysData)

Synchronize the start times of all data in S to begin at or after the last
start time in S.

.. function:: sync!(S::GphysData[, s=ST, t=EN, v=VV])

Synchronize all data in S to start at `ST` and terminate at `EN` with verbosity level VV.

For regularly-sampled channels, gaps between the specified and true times
are filled with the mean; this isn't possible with irregularly-sampled data.

Specifying start time (s)
=========================
* s="last": (Default) sync to the last start time of any channel in `S`.
* s="first": sync to the first start time of any channel in `S`.
* A numeric value is treated as an epoch time (`?time` for details).
* A DateTime is treated as a DateTime. (see Dates.DateTime for details.)
* Any string other than "last" or "first" is parsed as a DateTime.

Specifying end time (t)
=======================
* t="none": (Default) end times are not synchronized.
* t="last": synchronize all channels to end at the last end time in `S`.
* t="first" synchronize to the first end time in `S`.
* numeric, datetime, and non-reserved strings are treated as for `-s`.

.....

*****
Taper
*****

.. function:: taper!(S[, chans=CC, t_max::Real=10.0, :math:`\alpha`::Real=0.05, N_min::Int64=10])

Cosine taper each channel in S around time gaps. Specify chans=CC to restrict
to channel number(s) CC. Does not modify irregularly-sampled data channels.

taper!(C[, t_max::Real=10.0, :math:`\alpha`::Real=0.05, N_min::Int64=10])

Cosine taper each segment of time-series data in GphysChannel object C that
contains at least `N_min` total samples. Returns if C is irregularly sampled.

Keywords
========
* chans: Only taper the specified channels.
* N_min: Data segments with N < N_min total samples are not tapered.
* t_max: Maximum taper edge in seconds.
* :math:`\alpha`: Taper edge area; as for a Tukey window, the first and last 100*:math:`\alpha`% of samples in each window are tapered, up to `t_max` seconds of data.

.....

*****************
Zero-Phase Filter
*****************

.. function:: filtfilt!(S::GphysData[; KWs])

Apply a zero-phase filter to regularly-sampled data in **S**. Irregularly-sampled data are never processed by filtfilt!.

.. function:: filtfilt!(C::SeisChannel[; KWs])

Apply zero-phase filter to **C.x**. Filtering is applied to each contiguous data
segment in C separately.

Keywords
========
.. csv-table::
  :header: KW, Default, Type, Description
  :delim: |
  :widths: 1, 2, 1, 4

  chans | []          | :sup:`(a)` | channel numbers to filter
  fl  | 1.0           | Float64 | lower corner frequency [Hz] \ :sup:`(b)`
  fh  | 15.0          | Float64 | upper corner frequency [Hz] \ :sup:`(b)`
  np  | 4             | Int64   | number of poles
  rp  | 10            | Int64   | pass-band ripple (dB)
  rs  | 30            | Int64   | stop-band ripple (dB)
  rt  | \"Bandpass\"    | String  | response type (type of filter)
  dm  | \"Butterworth\" | String  | design mode (name of filter)

:sup:`(a)`  Allowed types are Integer, UnitRange, and Array{Int64, 1}.
:sup:`(b)`  By convention, the lower corner frequency (fl) is used in a Highpass
filter, and fh is used in a Lowpass filter.

Default filtering KW values can be changed by adjusting the :ref:`shared keywords<dkw>`,
e.g., SeisIO.KW.Filt.np = 2 changes the default number of poles to 2.
