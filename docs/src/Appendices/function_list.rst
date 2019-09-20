.. _function_list:

#################
Utility Functions
#################
This appendix covers utility functions that belong in no other category.

.. function:: ?RESP_wont_read

.. function:: d2u(DT::DateTime)

Aliased to ``Dates.datetime2unix``.

Keyword ``hc_new`` specifies the new critical damping constant. Keyword ``C`` specifies an array of channel numbers on which to operate; by default, every channel with fs > 0.0 is affected.

.. function:: fctoresp(fc, c)

Generate a generic PZResp object for a geophone with critical frequency ``fc`` and damping constant ``c``. If no damping constant is specified, assumes c = 1/sqrt(2).

.. function:: find_regex(path::String, r::Regex)

OS-agnostic equivalent to Linux `find`. First argument is a path string, second is a Regex. File strings are postprocessed using Julia's native PCRE Regex engine. By design, `find_regex` only returns file names.

.. function:: getbandcode(fs, fc=FC)

Get SEED-compliant one-character band code corresponding to instrument sample rate ``fs`` and corner frequency ``FC``. If unset, ``FC`` is assumed to be 1 Hz.

.. function:: get_file_ver(fname::String)

Get the version of a SeisIO native format file.

.. function:: get_seis_channels(S::GphysData)

Get numeric indices of channels in S whose instrument codes indicate seismic data.

.. function:: guess(fname::String)

Attempt to guess data file format and endianness using known binary file markers.

.. function:: inst_code(C::GphysChannel)
.. function:: inst_code(S::GphysData, i::Int64)
.. function:: inst_code(S::GphysData)

Get instrument codes.

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

Convert times **s** and **t** to strings :math:`\alpha, \omega` sorted :math:`\alpha < \omega`.
**s** and **t** can be real numbers, DateTime objects, or ASCII strings.
Expected string format is "yyyy-mm-ddTHH:MM:SS.nnn", e.g. 2016-03-23T11:17:00.333.

"Safe" synchronize of start and end times of all trace data in SeisData structure ``S`` to a new structure ``U``.

.. function:: resp_a0!(R::InstrumentResponse)
.. function:: resp_a0!(S::GphysData)

Updates sensitivity :a0 of PZResp/PZResp64 responses.

.. function:: resptofc(R)

Attempt to guess critical frequency from poles and zeros of a PZResp/PZResp64.

.. function:: set_file_ver(fname::String)

Sets the SeisIO file version of file fname.

.. function:: u2d(x)

Alias to ``Dates.unix2datetime``.

.. function:: validate_units(S::GphysData)

Validate strings in :units field to ensure UCUM compliance.

.. function:: vucum(str::String)

Check whether ``str`` contains valid UCUM units.
