#########################
Data Processing Functions
#########################
Supported processing operations are described below. Functions are organized
categorically.

In most cases, a "safe" version of each function can be invoked to create a
new SeisData object with the processed output.

Any function that can logically operate on a SeisChannel object will do so. Any
function that operates on a SeisData object will also operate on a SeisEvent
object by applying itself to the SeisData object in the ``:data`` field.

*****************
Signal Processing
*****************

.. function: demean!(S::SeisData[, irr=false])

Remove the mean from all channels i with S.fs[i] > 0.0. Specify irr=true to also
remove the mean from irregularly sampled channels. Ignores NaNs.

.. function: detrend!(S::SeisData[, n=1, irr=false])

Remove the polynomial trend of degree n from every regularly-sampled channel i
in S using a least-squares polynomial fit. Ignores NaNs.

.. function:: filtfilt!(S::SeisData[; KWs])

Apply a zero-phase filter to data in **S.x**.

.. function:: filtfilt!(Ev::SeisEvent[; KWs])

Apply zero-phase filter to **Ev.data.x**.

.. function:: filtfilt!(C::SeisChannel[; KWs])

Apply zero-phase filter to **C.x**

Filtering is applied to each contiguous data segment of each channel separately.

### Keywords
Keywords control filtering behavior; specify e.g. filtfilt!(S, fl=0.1, np=2, rt="Lowpass").
Default values can be changed by adjustin the :ref:`shared keywords<dkw>`, e.g.,
SeisIO.KW.Filt.np = 2 changes the default number of poles to 2.

.. csv-table::
  :header: KW, Default, Type, Description
  :delim: |
  :widths: 1, 2, 1, 4

  fl  | 1.0           | Float64 | lower corner frequency [Hz] \ :sup:`(a)`
  fh  | 15.0          | Float64 | upper corner frequency [Hz] \ :sup:`(a)`
  np  | 4             | Int64   | number of poles
  rp  | 10            | Int64   | pass-band ripple (dB)
  rs  | 30            | Int64   | stop-band ripple (dB)
  rt  | \"Bandpass\"    | String  | response type (type of filter)
  dm  | \"Butterworth\" | String  | design mode (name of filter)

:sup:`(a)`  By convention, the lower corner frequency (fl) is used in a Highpass
filter, and fh is used in a Lowpass filter.

.. function:: taper!(S)

Cosine taper each channel in S around time gaps.

.. function:: unscale!(S[, irr=false])

Divide the gains from all channels **i** with **S.fs[i] > 0.0**. Specify **irr=true** to
also remove gains of irregularly-sampled channels.

.. _merge:


*****
Merge
*****

.. function:: merge!(S::SeisData, U::SeisData)

Merge two SeisData structures. For timeseries data, a single-pass merge-and-prune
operation is applied to value pairs whose sample times are separated by less than
half the sampling interval.

.. function:: merge!(S::SeisData)

"Flatten" a SeisData structure by merging data from identical channels.


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
are non-empty and different. For example, if a SeisData object S contains two
channels, each with id "XX.FOO..BHZ", but one has fs=100 Hz and the other fs=50 Hz,
**merge!** does nothing.

It's best to merge only unprocessed data. Data segments that were processed
independently (e.g. detrended) will be averaged pointwise when merged, which
can easily leave data in an unusuable state.

***********
Synchronize
***********

.. function:: sync!(S::SeisData)

Synchronize the start times of all data in S to begin at or after the last
start time in S.

.. function:: sync!(S::SeisData[, s=ST, t=EN, v=VV])

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


.. function:: mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures into S.

****************************
Seismic Instrument Responses
****************************

.. function:: translate_resp!(S, resp_new[, C=chans, wl=g])
.. function:: translate_resp!(Ch, resp_new[, wl=g])

Translate the instrument response of seismic data channels to **resp_new**.
Replaces field **:resp** with **resp_new** for all affected channels.

Channels to translate can be specified with keyword **C=chans**; however, only
seismic data channels (with units "m", "m/s", or "m/s2") will be translated.

SeisChannel objects whose units are not "m", "m/s", or "m/s2" are returned with
no response translation done.

.. function:: remove_resp!(S, C=cha, wl=g])
.. function:: remove_resp!(Ch, wl=g])

Remove (flatten to DC) the instrument response of seismic data channels **cha**
in **S** or **Ch**. Replaces **:resp** with the appropriate (all-pass) response.

Response Keywords
=================
* **C=cha** restricts response translation for SeisData object **S** to channel(s) **cha**. Accepts an Integer, UnitRange, or Array{Int64,1} argument; does *not* accept string IDs. By default, all seismic data channels in **S** have their responses translated to **resp_new**.
* **wl=g** sets the waterlevel to g (default: g = eps(Float32) ~ 1.1f-7). The waterlevel is the minimum magnitude (absolute value) of the normalized old frequency response; in other words, if the old frequency response has a maximum magnitude of 1.0, then no response coefficient can be lower than g. This is useful to prevent "divide by zero" errors, but setting it too high will cause errors.


Precision and Memory Optimization
----------------------------------
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

**************************
Other Processing Functions
**************************

.. function:: nanfill!(S)

For each channel **i** in **S**, replace all NaNs in **S.x[i]** with the mean
of non-NaN values.

.. function:: ungap!(S[, m=true])

For each channel **i** in **S**, fill time gaps in **S.t[i]** with the mean of
non-NAN data in **S.x[i]**. If **m=false**, gaps are filled with NANs.
