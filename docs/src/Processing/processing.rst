###############
Data Processing
###############
Basic data processing operations are described below.

.. function:: autotap!(S)

Cosine taper each channel in S around time gaps, then fill time gaps with the mean of non-NaN data points.

.. function: demean!(S::SeisData)

Remove the mean from all channels i with S.fs[i] > 0.0. Specify all=true to also remove the mean from irregularly sampled channels. Ignores NaNs.

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

.. function sync!(S::SeisData[, resample=false, fs=FS, s=ST, t=EN])

Synchronize S to a common range of times and pad data gaps.

Keywords and behaviors:

* resample=true resamples regularly-data in S to the lowest non-null value of S.fs. Resample requests are ignored if S has only one data channel.
* fs=FS resamples regularly-sampled data in S to FS. Note that a poor choice of FS can lead to upsampling and other bad behaviors.
* s=ST, t=EN specifies start and end times. Accepted values include:

  + s="max": Sync to earliest start time in S. (default)
  + s="min": Sync to latest start time in S.
  + t="max": Use latest end time in S. (default)
  + t="min": Use earliest end time in S.
  + DateTime values of s, e are accepted.
  + String values of s,e converted to DateTime.
  + Numeric values of s,e treated as seconds from 01-01-1970T00:00:00.

.. function:: ungap!(S, [m=true, w=true])

Cosine taper all subsequences of regularly-sampled data and fill gaps with the
mean of non-NaN data points. **m=false** leaves time gaps set to NaNs;
**w=false** prevents cosine tapering.

.. function:: T = ungap(S)

"Safe" ungap of SeisData object S to a new SeisData object T.

.. function:: unscale!(S[, all=false])

Divide the gains from all channels i with S.fs[i] > 0.0. Specify all=true to
also remove gains of irregularly-sampled channels.