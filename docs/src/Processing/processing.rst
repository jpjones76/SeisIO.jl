###############
Data Processing
###############
Basic data processing operations are described below.

.. function:: autotap!(S)

Cosine taper each channel in S around time gaps, then fill time gaps with the mean of non-NaN data points.

.. function: demean!(S::SeisData[, irr=false])

Remove the mean from all channels i with S.fs[i] > 0.0. Specify irr=true to also remove the mean from irregularly sampled channels. Ignores NaNs.

.. function: demean(S::SeisData)

"Safe" demean with results output to a new structure.

.. function: detrend!(S::SeisData[, n=1])

Remove the polynomial trend of degree n from every regularly-sampled channel i in S using a least-squares polynomial fit. Ignores NaNs. Channels of irregularly-sampled data are not (and cannot be) detrended.

**Warning**: detrend! does *not* check for data gaps; if this is problematic, call ungap!(S, m=true) first!

.. function: detrend(S::SeisData)

"Safe" detrend with results output to a new structure.

.. function:: equalize_resp!(S, resp_new::Array[, hc_new=HC, C=CH])

Translate all data in SeisData structure ``S`` to instrument response ``resp_new``. Expected structure of ``resp_new`` is a complex Float64 2d array with zeros in ``resp[:,1]``, poles in ``resp[:,2]``. If channel ``i`` has key ``S.misc[i]["hc"]``, the corresponding value is used as the critical damping constant; otherwise a value of 1.0 is assumed.

.. function:: lcfs(fs::Array{Float64,1})

Find *L*owest *C*ommon *fs*, the lowest sampling frequency at which data can be upsampled by repeating an integer number of copies of each sample value.

.. function:: mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures into S.

.. function:: prune!(S::SeisData)

Delete all channels from S that have no data (i.e. S.x is empty or non-existent).

.. function:: pull(S::SeisData, id::String)

Extract the first channel with id=id from S and return it as a new SeisChannel structure. The corresponding channel in S is deleted.

.. function:: pull(S::SeisData, i::integer)
   :noindex:

Extract channel i from S as a new SeisChannel struct, deleting it from S.

.. function sync!(S::SeisData)

Synchronize the start times of all data in S to begin at or after the last
start time in S.

.. function sync!(S::SeisData[, s=ST, t=EN, v=VV])

Synchronize all data in S to start at `ST` and terminate at `EN` with verbosity level VV.

For regularly-sampled channels, gaps between the specified and true times
are filled with the mean; this isn't possible with irregularly-sampled data.

#### Specifying start time
* s="last": (Default) sync to the last start time of any channel in `S`.
* s="first": sync to the first start time of any channel in `S`.
* A numeric value is treated as an epoch time (`?time` for details).
* A DateTime is treated as a DateTime. (see Dates.DateTime for details.)
* Any string other than "last" or "first" is parsed as a DateTime.

#### Specifying end time (t)
* t="none": (Default) end times are not synchronized.
* t="last": synchronize all channels to end at the last end time in `S`.
* t="first" synchronize to the first end time in `S`.
* numeric, datetime, and non-reserved strings are treated as for `-s`.

Related functions: time, Dates.DateTime, parsetimewin

.. function:: ungap!(S, [m=true, w=true])

Cosine taper all subsequences of regularly-sampled data and fill gaps with the
mean of non-NaN data points. **m=false** leaves time gaps set to NaNs;
**w=false** prevents cosine tapering.

.. function:: T = ungap(S)

"Safe" ungap of SeisData object S to a new SeisData object T.

.. function:: unscale!(S[, all=false])

Divide the gains from all channels i with S.fs[i] > 0.0. Specify all=true to
also remove gains of irregularly-sampled channels.
