.. _function_list:

#################
Utility Functions
#################
This appendix covers utility functions that belong in no other category.

.. function:: distaz!(Ev::SeisEvent)

Fill Ev with great-circle distance, azimuth, and back-azimuth for each channel. Writes to evt.data.misc.

.. function:: d2u(DT::DateTime)

Aliased to ``Dates.datetime2unix``.

Keyword ``hc_new`` specifies the new critical damping constant. Keyword ``C`` specifies an array of channel numbers on which to operate; by default, every channel with fs > 0.0 is affected.

.. function:: fctopz(fc)

Convert critical frequency ``fc`` to a matrix of complex poles and zeros; zeros in ``resp[:,1]``, poles in ``resp[:,2]``.

.. function:: find_regex(path::String, r::Regex)

OS-agnostic equivalent to Linux `find`. First argument is a path string, second is a Regex. File strings are postprocessed using Julia's native PCRE Regex engine. By design, `find_regex` only returns file names.

.. function:: (dist, az, baz) = gcdist([lat_src, lon_src], rec)

Compute great circle distance, azimuth, and backazimuth from source coordinates ``[lat_src, lon_src]`` to receiver coordinates in ``rec`` using the Haversine formula. ``rec`` must be a two-column matix arranged [lat lon]. Returns a tuple of arrays.

.. function:: getbandcode(fs, fc=FC)

Get SEED-compliant one-character band code corresponding to instrument sample rate ``fs`` and corner frequency ``FC``. If unset, ``FC`` is assumed to be 1 Hz.

.. function:: ls(s::String)

Similar functionality to Bash ls with OS-agnostic output. Accepts wildcards in paths and file names.
* Always returns the full path and file name.
* Partial file name wildcards (e.g. "`ls(data/2006*.sac)`) invoke `glob`.
* Path wildcards (e.g. `ls(/data/*/*.sac)`) invoke `find_regex` to circumvent glob limitations.
* Passing ony "*" as a filename (e.g. "`ls(/home/*)`) invokes `find_regex` to recursively search subdirectories, as in the Bash shell.

.. function:: ls()

Return full path and file name of files in current working directory.

.. function:: j2md(y, j)

Convert Julian day **j** of year **y** to month, day.

.. function:: md2j(y, m, d)

Convert month **m**, day **d** of year **y** to Julian day **j**.

.. function namestrip(s::String[, convention="File")

Remove unwanted characters from S.

.. function:: parsetimewin(s, t)

Convert times **s** and **t** to strings α, ω sorted α < ω.
**s** and **t** can be real numbers, DateTime objects, or ASCII strings.
Expected string format is "yyyy-mm-ddTHH:MM:SS.nnn", e.g. 2016-03-23T11:17:00.333.

.. function:: webhdr()

Generate a Dict{String,String} to set UserAgent in web requests.

"Safe" synchronize of start and end times of all trace data in SeisData structure ``S`` to a new structure ``U``.

.. function:: u2d(x)

Alias to ``Dates.unix2datetime``.

function:: w_time(W::Array{Int64,2}, fs::Float64)

Convert matrix W from time windows (w[:,1]:w[:,2]) in integer μs from the Unix epoch (1970-01-01T00:00:00) to sparse delta-encoded time representation. Specify fs in Hz.

********
RandSeis
********
This submodule is used to quickly generate SeisIO structures with quasi-random
field contents. Access it by typing "using SeisIO.RandSeis"

* Channels have SEED-compliant IDs, sampling frequencies, and data types.
* Channel data are randomly generated.
* Some time gaps are automatically inserted into regularly-sampled data.
* Instrument location parameters are randomly set.

.. function:: C = randSeisChannel([,c=false, s=false])

Generate a SeisChannel of random data. Specify c=true for campaign-style (irregularly-sampled) data (fs = 0.0); specify s=true to guarantee seismic data. s=true overrides c=true.

.. function randSeisData([, c=0.2, s=0.6])

Generate 8 to 24 channels of random seismic data as a SeisData object.

* 100*c% of channels *after the first* will have irregularly-sampled data (fs = 0.0)
* 100*s% of channels *after the first* are guaranteed to have seismic data.

  randSeisData(N[, c=0.2, s=0.6])

Generate N channels of random seismic data as a SeisData object.

.. function:: randSeisEvent([, c=0.2, s=0.6])

Generate a SeisEvent structure filled with random values.
* 100*c% of channels *after the first* will have irregularly-sampled data (fs = 0.0)
* 100*s% of channels *after the first* are guaranteed to have seismic data.

.. function:: H = randSeisHdr()

Generate a SeisHdr structure filled with random values.
