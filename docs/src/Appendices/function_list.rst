.. _function_list:

######################################
Appendix A: Alphabetical Function List
######################################

.. function:: H = FDSNevq(ot::Real)

Multi-server query for event with origin time(s) closest to ``ot``.

.. function:: T = FDSNevt(ot::Real, C::Union{String,Array{String,1},Array{String,2}})

Get event headers and trace data for the event with origin time nearest ``ot`` on channels ``C``.

.. function:: S = FDSNget(C)

Retrieve data from channels ``C``.

.. function:: S = FDSNsta(C)

Retrieve station/channel info for ``C`` in an empty SeisData structure.

.. function:: S = IRISget(C)

Get near-real-time data from channels in ``C``.

.. function:: S = SeedLink(C)

Initiate a SeedLink session to feed data from streams ``C`` to a new SeisData structure with a handle to the SeedLink connection in ``S.c[1]``.

.. function:: SeedLink!(S, C)

Initiate a SeedLink session to feed data from streams ``C`` to SeisData structure ``S``. A handle to the TCP connection is appended to ``S.c``.

.. function:: C = SeisChannel()

Initiate an empty SeisChannel structure. Fields can be set at creation with keywords, e.g. ``SeisChannel(fs=100.0)`` creates a new SeisChannel structure with fs set to 100.0 Hz.

.. function:: S = SeisData()

Initiate an empty SeisData structure. Fields cannot be set at creation.

.. function:: evt = SeisEvent()

Initiate an empty SeisEvent structure.

.. function:: H = SeisHdr()

Create an empty SeisHdr structure. Fields can be set at creation with keywords, e.g. ``SeisHdr(mag=(1.1f0,'l',' '), loc=[45.37, -121.69, 6.8])``
initializes a SeisHdr structure with magnitude = M\ :sub:`l` 1.1 and location = 45.37°N, 121.69°W, z=6.8 km. Fields not specified at creation are initialized to SeisIO defaults.

.. function:: xstr = SL_info(v, url)

Retrieve SeedLink information at level ``v`` from ``url``. Returns XML as a string. Valid strings for ``L`` are ID, CAPABILITIES, STATIONS, STREAMS, GAPS, CONNECTIONS, ALL.

.. function:: autotap!(S)

Cosine taper each channel in S around time gaps, then fill time gaps with the mean of non-NaN data points.

.. function:: S = batch_read(fstr)

Read files matching ``fstr`` into memory using parallel read and shared arrays. The expected file type defaults to SAC; specify ``ftype="PASSCAL"`` for PASSCAL SEG Y.

.. function:: chanspec()

Type ``?chanspec`` to print detailed channel specification syntax to STDOUT.

.. function:: t = d2u(DT::DateTime)

Alias to ``Dates.datetime2unix``.

.. function:: distaz!(T::SeisEvent)

Fill ``T`` with great-circle distance, azimuth, and back-azimuth for each channel. Writes to ``evt.data.misc``.

.. function:: equalize_resp!(S, resp_new::Array, hc_new=HC, C=CH)

Translate all data in SeisData structure ``S`` to instrument response ``resp_new``. Expected structure of ``resp_new`` is a complex Float64 2d array with zeros in ``resp[:,1]``, poles in ``resp[:,2]``. If channel ``i`` has key ``S.misc[i]["hc"]``, the corresponding value is used as the critical damping constant; otherwise a value of 1.0 is assumed.

Keyword ``hc_new`` specifies the new critical damping constant. Keyword ``C`` specifies an array of channel numbers on which to operate; by default, every channel with fs > 0.0 is affected.

.. function:: resp = fctopz(fc)

Convert critical frequency ``fc`` to a matrix of complex poles and zeros; zeros in ``resp[:,1]``, poles in ``resp[:,2]``.

.. function:: i = findid(S, C)

Return the index of the first channel in ``S`` with id matching ``C``. If ``C`` is a string, ``findid`` is equivalent to ``findfirst(S.id.==C)``; if ``C`` is a SeisChannel, ``findid`` is equivalent to ``findfirst(S.id.==C.id)``.

.. function:: (dist, az, baz) = gcdist([lat_src, lon_src], rec)

Compute great circle distance, azimuth, and backazimuth from source coordinates ``[lat_src, lon_src]`` to receiver coordinates in ``rec`` using the Haversine formula. ``rec`` must be a two-column matix arranged [lat lon]. Returns a tuple of arrays.

.. function:: c = getbandcode(fs, fc=FC)

Get SEED-compliant one-character band code corresponding to instrument sample rate ``fs`` and corner frequency ``FC``. If unset, ``FC`` is assumed to be 1 Hz.

.. function:: tf = has_live_stream(C, url, g=G)

Check that streams with channel identifiers ``C`` have data < ``G`` seconds old at SeedLink server ``url``. Returns a Boolean array.

.. function:: tf = has_sta(C, url)

Check that station identifiers ``C`` exist at SeedLink server ``url``. Returns a Boolean array.

.. function:: s = ls(path)

Wrapper to /bin/ls; returns output as a string array. In Windows, provides similar functionality to *nix ls. ``ls()`` with no arguments lists contents of cwd.

.. function:: S = irisws(C)

Get near-real-time data from a single channel ``C``.

.. function:: (m, d) = j2md(y, j)

Convert Julian day ``j`` of year ``y`` to month, day. Returns a tuple.

.. function:: j = md2j(y, m, d)

Convert month ``m``, day ``d`` of year ``y`` to Julian day ``j``.

.. function:: namestrip!(S)

Remove bad characters from ``S``. Applied to a SeisData structure ``S``, ``namestrip!`` removes bad characters from ``S.name``.

.. function:: note!(S, txt)

Append a timestamped note to ``S.notes``. If ``txt`` mentions a channel name or ID, only the corresponding channel is annotated; otherwise, all channels are annotated.

.. function:: (d0, d1) = parsetimewin(s, t)

Convert times ``s`` and ``t`` to strings ``d0, d1`` sorted s.t. ``d0 < d1``. ``s`` and ``t`` can be real numbers, DateTime objects, or ASCII strings. Strings must follow the format "yyyy-mm-ddTHH:MM:SS.nnn", e.g. ``s="2016-03-23T11:17:00.333"``.

.. function:: U = pol_sort(S)

Sort channels of SeisData structure ``S`` to a new structure, retaining seismic data sorted in channel order Z, N, E (or Z, 1, 2).

.. function:: T = pull(S, i)

If ``i`` is a string, extract the first channel from ``S`` with ``id=i`` and return it as a new SeisData structure ``T``. The corresponding channel in ``S`` is deleted. If ``i`` is an integer, ``pull`` operates on the corresponding channel number.

.. function:: purge!(S)

Remove all channels ``i`` from ``S`` s.t. ``isempty(S.x[i]) = true``.

.. function:: C = randseischannel()

Generate a SeisChannel of random data. Specify ``c=true`` to allow the possibility of campaign (non-timeseries) data.

.. function:: S = randseisdata(N)

Generate ``N`` channels of random seismic data in a SeisData structure. Calling with no arguments (``randseisdata()``) generates 8 to 24 channels. Specify keyword ``c=true`` to allow the possibility of campaign (non-timeseries) data in some channels.

.. function:: evt = randseisevent()

Generate a SeisEvent structure filled with random values. Specify keyword ``c=true`` to allow the possibility of campaign (non-timeseries) data in some channels.

.. function:: H = randseishdr()

Generate a SeisHdr structure filled with random values.

.. function:: S = readmseed(fname)

Read miniSEED data file ``fname`` into a SeisData structure.

.. function:: S = readsac(fname)
.. function:: S = rsac(fname)

Read SAC data file ``fname`` into a SeisData structure. Specify keyword ``full=true`` to save all SAC header values in field ``:misc``.

.. function:: S = readsegy(fname)

Read SEG Y data file ``fname`` into a SeisData structure. Specify keyword ``passcal=true`` for PASSCAL-modified SEG Y.

.. function:: S = readuw(fname)

Read UW data file ``fname`` into a SeisData structure. ``fname`` can be a pick file (ending in [a-z]), a data file (ending in W), or a file root (numeric UW event ID).

.. function:: S = readwin32(fstr, cf)

Read win32 data from files matching ``fstr`` into a SeisData structure using channel information file ``cf``. ``fstr`` can contain wildcard filenames, but no wildcards are allowed in directory names if ``fstr`` specifies a full path.

..function:: S = rlennasc(fname)

Read Lennartz-formatted ASCII file ``fname`` into a SeisData structure.

.. function:: A = rseis(fname)

Read SeisIO data from ``fname`` into an array of SeisIO-compatible structures.

.. function:: sachdr(fname)

Print headers from SAC file ``fname`` to STDOUT.

.. function:: segyhdr(fname)

Print headers from SEG Y file ``fname`` to STDOUT. Specify ``passcal=true`` for PASSCAL SEG Y.

.. function:: seeddef(f, v)

Set default SEED value for field ``f`` to ``v``. Type ``?seeddef`` at the Julia prompt for a list of SEED defaults.

.. function:: T = sort(S, rev=false)

"Safe" sort of channels in SeisData struct ``S`` by S.id to a new SeisData structure. Specify ``rev=true`` to reverse the sort order.

.. function:: sort!(S, [rev=false])

In-place sort of channels in SeisData struct ``S`` by S.id. Specify ``rev=true`` to reverse the sort order.

.. function:: sync!(S)

Synchronize the start and end times of all trace data in SeisData structure ``S``

.. function:: U = sync(S)

"Safe" synchronize of start and end times of all trace data in SeisData structure ``S`` to a new structure ``U``.

.. function:: timestamp()

Return the current UTC time formatted yyyy-mm-ddTHH:MM:SS.

.. function:: resp_new = translate_resp(X, fs, resp_old, resp_new; gain=G, hc_old=h0, hc_new=h1)

Translate frequency response of time-series data ``X`` sampled at ``fs`` Hz from ``resp_old`` to ``resp_new``. zeros are in ``resp[:,1]``, poles in ``resp[:,2]``. Keywords ``gain, hc_old, hc_new`` set the scalar gain, old critical damping constant h\ :sub:`0`, and new critcal damping constant h\ :sub:`1`.

.. function:: u2d(x)

Alias to ``Dates.unix2datetime``.

.. function:: ungap!(S)

Fill time gaps in SeisData structure ``S``, cosine tapers regularly sampled subsequences of time series data, and fills time gaps with the mean of non-NaN data points. Setting ``m=false`` leaves time gaps set to NaNs; setting ``w=false`` prevents cosine tapering.

.. function:: T = ungap(S)

"Safe" ungap of SeisData structure ``S`` to a new structure ``T``.

.. function:: S = uwdf(dfname)

Parse UW event data file ``dfname`` into a new SeisEvent structure ``S``.

.. function:: uwpf!(evt, pfname)

Parse UW event pick file ``pfname`` into SeisEvent structure ``evt``.

.. function:: S = uwpf(pfname)

Parse UW event pick file ``pfname`` into a new SeisEvent structure.

.. function:: webhdr()

Generate a Dict{String,String} to set UserAgent in web requests.

.. function:: writesac(S)
.. function:: wsac(S)

Write SAC data from SeisData structure ``S`` to SAC files with auto-generated names. Specify ``ts=true`` to write time stamps; note that this will flag the file as "generic x-y data" in SAC.

.. function:: wseis(fname, S)

Write SeisIO data from S to ``fname``. Supports splat expansion for writing multiple objects, e.g. ``wseis(fname, S, T, U)`` writes ``S``, ``T``, and ``U`` to ``fname``.
