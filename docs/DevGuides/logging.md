# The fundamental rule of logging
Logging to `:notes` should contain enough detail that someone who reads `:notes` can replicate the work, starting with reading raw data, by following the steps described.

# Log processing/analysis to `:notes`
Processing and analysis function calls should be logged in the `:notes` field of (each affected channel of) each relevant object:
* Use the function `note!`; see its documentation for examples.
* Within each note, record function calls and relevant options in comma-delineated fields.

## Structure of processing/analysis notes
* First field: timestamp, formatted YYYY-MM-DDTHH:MM:SS
* Second field:
  - For data processing functions: "processing", no quotes
  - For data analysis functions: "analysis", no quotes
* Third field: function call
* Fourth field: (optional) human-readable description

### Expected delimiter
" ¦ ". Please note that this is Char(0xa6), not Char(0x7c).

### Best practice: why log analysis routines?
It's best to log analysis function calls to `:notes` when invoked, so that the sequence of steps up to and including analysis is clear later.

### Examples
An example of logging that leads to good reproducibility:
```
2019-04-19T06:28:32 ¦ processing ¦ filtfilt!(S, fl=1.0, fh=15.0, np=4, rp=8, rs=30, rt=Bandpass, dm=Butterworth) ¦ zero-phase filter
2019-04-19T07:20:57 ¦ processing ¦ ungap!(S, m=true, tap=false) ¦ filled 4 gaps (sum = 1590288 μs)
```

An example of inadequate logging; note that the processing cannot be reproduced from the information given:
```
2019-04-19T06:28:32 ¦ processing ¦ wavelet transform
2019-04-19T06:29:20 ¦ processing ¦ best basis filter
```

# Log data reads/acquisitions to `:notes`
We recommend logging exact command(s), so that they can be reproduced with no additional input.

## Structure of data read notes
* First field: timestamp, formatted YYYY-MM-DDTHH:MM:SS
* Second field: "+src", no quotes
* Third field: function call

For file strings, we strongly recommend using `abspath(str)` to resolve the absolute path.

Example: `2019-12-18T23:17:28 ¦ +source ¦ read_data("sac", "/data/SAC/test*.sac", full=true, swap=true)`

## Logging downloads and streaming data
`:notes` should contain two entries:
1. The URL, with "+source" as the second field.
2. Any submission info required for data transfer: POST data, SeedLink command strings, etc.
* The second field of the note should be a descriptive single-word string: "POST" for HTTP POST methods, "commands" for SeedLink commands, etc.
* Include only the relevant commands to acquire data for the selected channel.

Example: an HTTP POST request
```
2019-12-18T23:17:28 ¦ +source ¦ https://service.scedc.caltech.edu/fdsnws/station/1/
2019-12-18T23:17:28 ¦ POST ¦ CI BAK -- LHZ 2016-01-01T01:11:00 2016-02-01T01:11:00\n
```

# Log all automated metadata changes
* Here, "metadata" means any field in a GphysData or GphysChannel object *except* `:t`, `:x`, `:misc`, or `:notes`
* Here, "automated" means any metadata change that is done within a function, rather than manually set by a command like `setfield!(C, f, x)`.

## Structure of metadata notes
* First field: timestamp, formatted YYYY-MM-DDTHH:MM:SS
* Second field: "+meta", no quotes
* Third field: function call

For file strings, we strongly recommend using `abspath(str)` to resolve the absolute path.

Example: `2019-12-18T23:17:30 ¦ +meta ¦ read_meta("sacpz", "/data/SAC/testfile.sacpz")`

# Log the last data source to `:src`
The field `:src` should always contain the most recent data source.

## File source
`:src` should be the file pattern string: in the above example, "/data/SAC/test*.sac".

### File source that gives a data source
Note the original data source in `:notes` as if it was a data source, but use the file string in `:src`.

## Download or streaming source
`:src` should be the request URL.
