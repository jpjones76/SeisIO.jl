# Fundamental Rule
Logging to *:notes* must contain enough detail that someone who reads *:notes* can replicate the work, starting with reading raw data, by following the steps described.

## **Definitions of Terms**
* **automated** means any change that results from a function, rather than a command entered at the Julia prompt.
* **metadata** includes any field in any structure whose Type is a subtype of GphysData or GphysChannel, *except* these fields: *:t*, *:x*, *:misc*, *:notes*

## General Note Structure
* First field: timestamp, formatted YYYY-MM-DDTHH:MM:SS
* Second field:
  - For time-series read or download, "+src"
  - For data processing functions: "processing"
  - For data analysis functions: "analysis"
  - For write operations, "write"
  - For metadata read or download, "+meta"
* Third field: function call
* Fourth field: (optional) human-readable description

### Expected field delimiter
" ¦ ", including spaces. Please note that this is Char(0xa6), not Char(0x7c).

# File I/O Logging API
`fread_note!(S::GphysData, N::Array{Int64,1}, method::String, fmt::String, filestr::String, opts::String)`

Log file read information to *:notes* in channels *S[N]*. *method* is the invoking function name, *fmt* is the format string, *filestr* is the file string. *opts* is a comma-separated String list of arguments, including keywords, like `"swap=true, full=true"`.

`fwrite_note!(S::GphysData, i::Int64, method::String, fname::String, opts::String)`

Log file write operation to *S.notes[i]* or *C.notes*. *method* is the name of the invoking function; *opts* is a dynamically-created comma-separated list of arguments, including keywords, with an initial comma, like `", fname=\"foo.out\", v=3"`.

# Processing/Analysis Logging API
Here, it's **not** necessary to correctly name the variable used for the input structure. Instead, use **S** for GphysData subtypes, **C** for GphysChannel subtypes, and **Ev** for Quake.SeisEvent.

`proc_note!(S::GphysData, N::Array{Int64, 1}, proc_str::String, desc::String)`

Log processing operation to *:notes* in channels *S[N]*. *proc_str* is a dynamic String of the full function call including relevant arguments and keywords, like `"unscale!(S, chans=[1,2,3])"`. *desc* should be a human-readable description, like `"divided out channel gain"`.

`proc_note!(S::GphysData, i::Int64, proc_str::String, desc::String)`

As above for *S.notes[i]*.

`proc_note!(C::GphysChannel, method::String, desc::String)`

As above for *C.notes*.

# Downloads and Streaming Data
## Syntax:
* `note!(S, i, "+source ¦ " * url)` for GphysData subtypes
* `note!(C, "+source ¦ " * url)` for GphysChannel subtypes

## What to Log
1. The URL, with "+source" as the second field.
2. Any submission info required for data transfer: POST data, SeedLink command strings, etc.
* The second field of the note should be a descriptive single-word string: "POST" for HTTP POST methods, "commands" for SeedLink commands, etc.
* Include only the relevant commands to acquire data for the selected channel.

### Example: HTTP POST request
```
2019-12-18T23:17:28 ¦ +source ¦ https://service.scedc.caltech.edu/fdsnws/station/1/
2019-12-18T23:17:28 ¦ POST ¦ CI BAK -- LHZ 2016-01-01T01:11:00 2016-02-01T01:11:00\n
```
# Automated Metadata Changes
## Syntax:
* First field: timestamp, formatted YYYY-MM-DDTHH:MM:SS
* Second field: "+meta", no quotes
* Third field: function call
* Fourth field: (optional) human-readable description

For file strings, we strongly recommend using `abspath(str)` to resolve the absolute path.

Example: `2019-12-18T23:17:30 ¦ +meta ¦ read_meta("sacpz", "/data/SAC/testfile.sacpz")`

# Field `:src`
`:src` should always contain the most recent time-series data source.

## File Source
`:src` should be the file pattern string, like "/data/SAC/test*.sac".

## Download or Streaming Source
`:src` should be the request URL.
